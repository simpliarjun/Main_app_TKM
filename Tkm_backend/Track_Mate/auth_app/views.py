

from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from django.utils import timezone
from django.contrib.auth import get_user_model
from rest_framework_simplejwt.tokens import RefreshToken
from django.core.mail import send_mail
from django.conf import settings
from datetime import timedelta
import secrets  # ✅ SECURITY FIX: Use cryptographically secure random

from .models import EmailOTP
from .utils import send_otp_email

User = get_user_model()


def _generate_otp():
    # ✅ SECURITY FIX: Use secrets.randbelow instead of random for OTP generation
    return f"{secrets.randbelow(1000000):06d}"


# -----------------------------
# SIGNUP -> create user (is_verified=False) and send OTP
# -----------------------------
@api_view(["POST"])
def signup(request):
    data = request.data
    email = (data.get("email") or "").strip()
    username = (data.get("username") or "").strip()
    password = data.get("password", "")

    # ✅ Input Validation
    if not email or not username or not password:
        return Response({"error": "email, username, and password required"}, status=status.HTTP_400_BAD_REQUEST)

    # ✅ Email format validation
    if "@" not in email or "." not in email.split("@")[-1]:
        return Response({"error": "Invalid email format"}, status=status.HTTP_400_BAD_REQUEST)

    # ✅ Username validation (3+ characters, alphanumeric and underscore)
    if len(username) < 3:
        return Response({"error": "Username must be at least 3 characters"}, status=status.HTTP_400_BAD_REQUEST)

    # ✅ Password strength validation (8+ characters)
    if len(password) < 8:
        return Response({"error": "Password must be at least 8 characters"}, status=status.HTTP_400_BAD_REQUEST)

    if User.objects.filter(email=email).exists():
        return Response({"error": "Email already registered"}, status=status.HTTP_400_BAD_REQUEST)

    if User.objects.filter(username=username).exists():
        return Response({"error": "Username already taken"}, status=status.HTTP_400_BAD_REQUEST)

    # ✅ Create user with verified status set to False
    user = User.objects.create_user(email=email, username=username, password=password)
    user.is_verified = False
    user.save()

    otp_code = _generate_otp()
    expires_at = timezone.now() + timedelta(minutes=10)

    EmailOTP.objects.create(
        email=email,
        code=otp_code,
        purpose="signup",
        used=False,
        expires_at=expires_at
    )

    send_otp_email(email, otp_code, "signup")
    return Response({"message": "Signup successful. OTP sent to email."}, status=status.HTTP_201_CREATED)


# -----------------------------
# VERIFY OTP
# -----------------------------
@api_view(["POST"])
def verify_otp(request):
    email = request.data.get("email", "").strip()
    code = (request.data.get("code") or request.data.get("otp") or "").strip()

    # ✅ Input Validation
    if not email or not code:
        return Response({"error": "email and code required"}, status=status.HTTP_400_BAD_REQUEST)

    # ✅ Email format validation
    if "@" not in email or "." not in email.split("@")[-1]:
        return Response({"error": "Invalid email format"}, status=status.HTTP_400_BAD_REQUEST)

    # ✅ OTP format validation (should be 6 digits)
    if not code.isdigit() or len(code) != 6:
        return Response({"error": "Invalid OTP format"}, status=status.HTTP_400_BAD_REQUEST)

    otp_obj = EmailOTP.objects.filter(email=email, code=code, purpose="signup", used=False).order_by("-created_at").first()
    if not otp_obj:
        return Response({"error": "Invalid or already used OTP"}, status=status.HTTP_400_BAD_REQUEST)

    if otp_obj.is_expired():
        return Response({"error": "OTP has expired. Please request a new one."}, status=status.HTTP_410_GONE)

    otp_obj.used = True
    otp_obj.save()

    try:
        user = User.objects.get(email=email)
    except User.DoesNotExist:
        return Response({"error": "User not found"}, status=status.HTTP_404_NOT_FOUND)

    user.is_verified = True
    user.save()
    return Response({"message": "Email verified successfully"}, status=status.HTTP_200_OK)


# -----------------------------
# LOGIN
# -----------------------------
@api_view(["POST"])
def login(request):
    email = request.data.get("email", "").strip()
    password = request.data.get("password", "")

    # ✅ Input Validation
    if not email or not password:
        return Response({"error": "Email and password required"}, status=status.HTTP_400_BAD_REQUEST)

    # ✅ Email format validation
    if "@" not in email or "." not in email.split("@")[-1]:
        return Response({"error": "Invalid email format"}, status=status.HTTP_400_BAD_REQUEST)

    try:
        user = User.objects.get(email=email)
    except User.DoesNotExist:
        # ✅ Use consistent error message to prevent timing attacks
        return Response({"error": "Invalid credentials"}, status=status.HTTP_400_BAD_REQUEST)

    if not user.check_password(password):
        # ✅ Use consistent error message to prevent timing attacks
        return Response({"error": "Invalid credentials"}, status=status.HTTP_400_BAD_REQUEST)

    if not user.is_verified:
        return Response({"error": "Email not verified. Please check your email for verification link."}, status=status.HTTP_403_FORBIDDEN)

    refresh = RefreshToken.for_user(user)
    return Response({
        "access": str(refresh.access_token),
        "refresh": str(refresh),
        "user_id": user.id,
        "email": user.email
    }, status=status.HTTP_200_OK)


# -----------------------------
# REFRESH TOKEN
# -----------------------------
@api_view(["POST"])
def refresh_token(request):
    token = (request.data.get("refresh") or "").strip()

    # ✅ Input Validation
    if not token:
        return Response({"error": "Refresh token is required"}, status=status.HTTP_400_BAD_REQUEST)

    try:
        refresh = RefreshToken(token)
        return Response({"access": str(refresh.access_token)}, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({"error": "Invalid or expired refresh token"}, status=status.HTTP_401_UNAUTHORIZED)


# -----------------------------
# FORGOT PASSWORD (send OTP)
# -----------------------------
@api_view(["POST"])
def forgot_password(request):
    email = (request.data.get("email") or "").strip()

    # ✅ Input Validation
    if not email:
        return Response({"error": "Email is required"}, status=status.HTTP_400_BAD_REQUEST)

    # ✅ Email format validation
    if "@" not in email or "." not in email.split("@")[-1]:
        return Response({"error": "Invalid email format"}, status=status.HTTP_400_BAD_REQUEST)

    try:
        user = User.objects.get(email=email)
    except User.DoesNotExist:
        # ✅ Timing-attack resistant: same message whether user exists or not
        return Response({"message": "If an account exists with this email, you will receive a password reset OTP."}, 
                       status=status.HTTP_200_OK)

    otp_code = _generate_otp()
    expires_at = timezone.now() + timedelta(minutes=10)

    EmailOTP.objects.create(
        email=email,
        code=otp_code,
        purpose="reset",
        used=False,
        expires_at=expires_at
    )

    send_otp_email(email, otp_code, "password reset")
    return Response({"message": "Password reset OTP sent to your email"}, status=status.HTTP_200_OK)


# -----------------------------
# RESET PASSWORD
# -----------------------------
@api_view(["POST"])
def reset_password(request):
    email = (request.data.get("email") or "").strip()
    code = (request.data.get("code") or request.data.get("otp") or "").strip()
    new_password = request.data.get("new_password", "")

    # ✅ Input Validation
    if not email or not code or not new_password:
        return Response({"error": "email, code and new_password required"}, status=status.HTTP_400_BAD_REQUEST)

    # ✅ Email format validation
    if "@" not in email or "." not in email.split("@")[-1]:
        return Response({"error": "Invalid email format"}, status=status.HTTP_400_BAD_REQUEST)

    # ✅ OTP format validation
    if not code.isdigit() or len(code) != 6:
        return Response({"error": "Invalid OTP format"}, status=status.HTTP_400_BAD_REQUEST)

    # ✅ Password strength validation (8+ characters)
    if len(new_password) < 8:
        return Response({"error": "Password must be at least 8 characters"}, status=status.HTTP_400_BAD_REQUEST)

    otp_obj = EmailOTP.objects.filter(email=email, code=code, purpose="reset", used=False).order_by("-created_at").first()
    if not otp_obj:
        return Response({"error": "Invalid or already used OTP"}, status=status.HTTP_400_BAD_REQUEST)

    if otp_obj.is_expired():
        return Response({"error": "OTP has expired. Please request a new one."}, status=status.HTTP_410_GONE)

    try:
        user = User.objects.get(email=email)
    except User.DoesNotExist:
        return Response({"error": "User not found"}, status=status.HTTP_404_NOT_FOUND)

    user.set_password(new_password)
    user.save()

    otp_obj.used = True
    otp_obj.save()
    return Response({"message": "Password reset successful"}, status=status.HTTP_200_OK)


# -----------------------------
# LOGOUT (Blacklist Refresh Token)
# -----------------------------
@api_view(["POST"])
def logout_view(request):
    refresh_token = (request.data.get("refresh") or "").strip()

    # ✅ Input Validation
    if not refresh_token:
        return Response({"error": "Refresh token is required"}, status=status.HTTP_400_BAD_REQUEST)

    try:
        token = RefreshToken(refresh_token)
        token.blacklist()
        return Response({"message": "Logged out successfully"}, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({"error": "Invalid or expired token"}, status=status.HTTP_401_UNAUTHORIZED)
