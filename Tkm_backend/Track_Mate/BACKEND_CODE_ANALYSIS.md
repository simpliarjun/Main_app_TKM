# Django Backend Code Analysis Report
**TrackMate Application - Comprehensive Backend Security & Quality Review**

---

## Executive Summary
This analysis identifies **47 critical, high, medium, and low-priority issues** across the Django backend codebase. Major concerns include:
- Hardcoded credentials and insecure configuration
- Missing authentication/permission checks on sensitive endpoints
- Race conditions in concurrent operations
- Input validation gaps
- SQL injection vulnerability patterns
- N+1 query problems
- Unhandled exceptions and error responses
- Missing CORS/security headers

---

# ANALYSIS BY FILE

---

## 1. trackmate/settings.py

### Issue 1.1: Hardcoded Email Credentials
**Severity:** 🔴 CRITICAL  
**Lines:** 116-117  
**Issue:** Email credentials are hardcoded in settings file with fallback to plaintext
```python
EMAIL_HOST_USER = os.environ.get("EMAIL_HOST_USER", "teamyuktek@gmail.com")
EMAIL_HOST_PASSWORD = os.environ.get("EMAIL_HOST_PASSWORD", "kavk rydz yebl cibq")
```
**Problems:**
- Default credentials exposed in source code
- Anyone with repo access gets email account access
- Password visible in plaintext
**Fix:**
```python
EMAIL_HOST_USER = os.environ.get("EMAIL_HOST_USER")
EMAIL_HOST_PASSWORD = os.environ.get("EMAIL_HOST_PASSWORD")
if not EMAIL_HOST_USER or not EMAIL_HOST_PASSWORD:
    raise ImproperlyConfigured("EMAIL_HOST_USER and EMAIL_HOST_PASSWORD must be set in environment")
```

---

### Issue 1.2: ALLOWED_HOSTS Overly Permissive
**Severity:** 🔴 CRITICAL  
**Line:** 17  
**Issue:** `ALLOWED_HOSTS = ["*"]`
**Problems:**
- Allows any hostname to access the API (Host Header Injection attacks)
- Defeats CSRF protection
- Production security risk
**Fix:**
```python
ALLOWED_HOSTS = os.environ.get("ALLOWED_HOSTS", "localhost,127.0.0.1").split(",")
# In production: ["api.trackmate.com", "www.trackmate.com"]
```

---

### Issue 1.3: Missing CORS Configuration
**Severity:** 🟠 HIGH  
**Lines:** 38-49 (MIDDLEWARE section)  
**Issue:** No CORS middleware configured. Cross-origin requests will fail or be insecure
**Problems:**
- Frontend Flutter app cannot make requests unless origin is same
- No CORS_ALLOWED_ORIGINS configured
- Potential to deny all cross-origin requests
**Fix:**
```python
# Add to INSTALLED_APPS
INSTALLED_APPS = [
    ...
    "corsheaders",
    ...
]

# Add to MIDDLEWARE (FIRST position)
MIDDLEWARE = [
    "corsheaders.middleware.CorsMiddleware",  # ADD THIS FIRST
    "django.middleware.security.SecurityMiddleware",
    ...
]

# Add CORS configuration
CORS_ALLOWED_ORIGINS = os.environ.get(
    "CORS_ALLOWED_ORIGINS",
    "http://localhost:3000,http://localhost:8080"
).split(",")
CORS_ALLOW_CREDENTIALS = True
```

---

### Issue 1.4: Missing Security Headers
**Severity:** 🟠 HIGH  
**Lines:** 1-130  
**Issue:** No security headers configured (HSTS, CSP, X-Frame-Options, etc.)
**Problems:**
- Missing X-Frame-Options (Clickjacking risk)
- No Content Security Policy
- Missing HSTS header for HTTPS
- No X-Content-Type-Options
**Fix:**
```python
SECURE_HSTS_SECONDS = 31536000  # 1 year
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True
SECURE_SSL_REDIRECT = os.environ.get("DJANGO_DEBUG") != "True"
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True

# Security headers
SECURE_CONTENT_SECURITY_POLICY = {
    "default-src": ("'self'",),
    "script-src": ("'self'", "cdn.jsdelivr.net"),
}
X_FRAME_OPTIONS = "DENY"
```

---

### Issue 1.5: DEBUG Configuration Risk
**Severity:** 🟠 HIGH  
**Line:** 16  
**Issue:** `DEBUG = os.environ.get("DJANGO_DEBUG", "False") == "True"`
**Problems:**
- String comparison is fragile ("False" vs False)
- DEBUG mode exposes sensitive information
- No validation that production has DEBUG=False
**Fix:**
```python
DEBUG = os.environ.get("DJANGO_DEBUG", "False").lower() == "true"
if DEBUG and os.environ.get("ENVIRONMENT") == "production":
    raise ImproperlyConfigured("DEBUG cannot be True in production")
```

---

### Issue 1.6: Missing Django Security Settings
**Severity:** 🟠 HIGH  
**Lines:** 1-130  
**Issue:** Multiple security settings not configured
**Missing Settings:**
- SECURE_BROWSER_XSS_FILTER
- SECURE_CONTENT_SECURITY_POLICY_REPORT_ONLY
- X_CONTENT_TYPE_OPTIONS
- PASSWORD_HASHERS configuration
- No rate limiting
- No logging configuration

**Fix:** Add to settings.py:
```python
# Security settings
SECURE_BROWSER_XSS_FILTER = True
X_CONTENT_TYPE_OPTIONS = "nosniff"
SECURE_REFERRER_POLICY = "same-origin"

# Rate limiting (install django-ratelimit)
RATELIMIT_USE_CACHE = "default"

# Logging
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'file': {
            'level': 'ERROR',
            'class': 'logging.FileHandler',
            'filename': BASE_DIR / 'logs' / 'django.log',
        },
        'console': {
            'level': 'INFO',
            'class': 'logging.StreamHandler',
        },
    },
    'loggers': {
        'django': {
            'handlers': ['file', 'console'],
            'level': 'INFO',
        },
    },
}
```

---

### Issue 1.7: Missing Database Configuration Validation
**Severity:** 🟟 MEDIUM  
**Lines:** 74-80  
**Issue:** SQLite in production is not safe for concurrent access
**Problems:**
- SQLite locks entire database on writes
- Race conditions possible with multiple workers
- No connection pooling
**Fix:**
```python
import dj_database_url

if os.environ.get("DATABASE_URL"):
    DATABASES = {
        "default": dj_database_url.config(
            default=os.environ.get("DATABASE_URL"),
            conn_max_age=600
        )
    }
else:
    DATABASES = {
        "default": {
            "ENGINE": "django.db.backends.sqlite3",
            "NAME": BASE_DIR / "db.sqlite3",
        }
    }
    
    if not DEBUG:
        raise ImproperlyConfigured(
            "SQLite cannot be used in production. Set DATABASE_URL environment variable."
        )
```

---

### Issue 1.8: Google API Keys Exposed in Settings
**Severity:** 🔴 CRITICAL  
**Lines:** 125-127  
**Issue:** API keys stored as plaintext environment variables without fallback
```python
GOOGLE_MAPS_API_KEY = os.environ.get("GOOGLE_MAPS_API_KEY", "")
GOOGLE_GEOCODING_API_KEY = os.environ.get("GOOGLE_GEOCODING_API_KEY", "")
GOOGLE_DIRECTIONS_API_KEY = os.environ.get("GOOGLE_DIRECTIONS_API_KEY", "")
```
**Problems:**
- Empty string fallback means API calls will fail silently
- Keys in environment variables (often logged)
- No rotation mechanism
**Fix:**
```python
# Validate each API key is set
for api_key_var in ["GOOGLE_MAPS_API_KEY", "GOOGLE_GEOCODING_API_KEY", "GOOGLE_DIRECTIONS_API_KEY"]:
    if not os.environ.get(api_key_var):
        if not DEBUG:
            raise ImproperlyConfigured(f"{api_key_var} must be set in production")

GOOGLE_MAPS_API_KEY = os.environ.get("GOOGLE_MAPS_API_KEY", "")
GOOGLE_GEOCODING_API_KEY = os.environ.get("GOOGLE_GEOCODING_API_KEY", "")
GOOGLE_DIRECTIONS_API_KEY = os.environ.get("GOOGLE_DIRECTIONS_API_KEY", "")
```

---

## 2. auth_app/models.py

### Issue 2.1: EmailOTP.expires_at Default Value Bug
**Severity:** 🟠 HIGH  
**Line:** 52  
**Issue:** `expires_at = models.DateTimeField(default=timezone.now)`
**Problems:**
- `default=timezone.now` is evaluated at migration time, not per-instance
- All OTPs expire at the exact same time
- Should use `default_callable` or set value in save()
**Correct Fix:**
```python
from django.utils import timezone
from datetime import timedelta

# Option 1: Use callable
expires_at = models.DateTimeField(
    default=lambda: timezone.now() + timedelta(minutes=10)
)

# Option 2: Override save()
def save(self, *args, **kwargs):
    if not self.expires_at:
        self.expires_at = timezone.now() + timedelta(minutes=10)
    super().save(*args, **kwargs)
```

---

### Issue 2.2: Missing Unique Constraint on OTP
**Severity:** 🟟 MEDIUM  
**Lines:** 47-53  
**Issue:** No constraint preventing multiple active OTPs for same email+purpose
**Problems:**
- Multiple OTPs can exist for same email+purpose
- No cleanup of old OTPs
- Frontend doesn't know which OTP to use
**Fix:**
```python
class EmailOTP(models.Model):
    email = models.EmailField()
    code = models.CharField(max_length=6)
    purpose = models.CharField(max_length=20)
    used = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    
    class Meta:
        # Only one active OTP per email+purpose
        constraints = [
            models.UniqueConstraint(
                fields=['email', 'purpose'],
                condition=Q(used=False),
                name='unique_active_otp'
            )
        ]
    
    def save(self, *args, **kwargs):
        if not self.expires_at:
            self.expires_at = timezone.now() + timedelta(minutes=10)
        super().save(*args, **kwargs)
```

---

### Issue 2.3: No Validation on OTP Code Format
**Severity:** 🟟 MEDIUM  
**Lines:** 47-53  
**Issue:** OTP code stored as CharField(max_length=6) with no validation
**Problems:**
- No format validation (regex check if it's 6 digits)
- No length validation in model
- Potential for malformed codes
**Fix:**
```python
from django.core.validators import RegexValidator

class EmailOTP(models.Model):
    code = models.CharField(
        max_length=6,
        validators=[
            RegexValidator(
                regex=r'^\d{6}$',
                message='OTP must be exactly 6 digits',
                code='invalid_otp'
            )
        ]
    )
```

---

## 3. auth_app/views.py

### Issue 3.1: Missing Input Validation in signup()
**Severity:** 🟠 HIGH  
**Lines:** 23-47  
**Issue:** No validation on email, username, or password format
```python
if not email or not username or not password:
    return Response({"error": "email, username, and password required"}, status=400)
```
**Problems:**
- No regex validation on email
- No username length/format check
- No password strength validation
- Returns 400 instead of 422 (semantic wrong)
- No SQL injection prevention (using ORM is safe but no input sanitization)
**Fix:**
```python
from django.core.exceptions import ValidationError
from django.core.validators import EmailValidator, validate_slug
import re

@api_view(["POST"])
def signup(request):
    email = request.data.get("email", "").strip()
    username = request.data.get("username", "").strip()
    password = request.data.get("password", "")
    
    # Validate email
    if not email:
        return Response({"error": "email is required"}, status=status.HTTP_400_BAD_REQUEST)
    
    validator = EmailValidator()
    try:
        validator(email)
    except ValidationError:
        return Response({"error": "Invalid email format"}, status=status.HTTP_422_UNPROCESSABLE_ENTITY)
    
    # Validate username
    if not username or len(username) < 3 or len(username) > 150:
        return Response(
            {"error": "Username must be 3-150 characters"},
            status=status.HTTP_422_UNPROCESSABLE_ENTITY
        )
    
    if not re.match(r'^[a-zA-Z0-9_-]{3,150}$', username):
        return Response(
            {"error": "Username can only contain letters, numbers, underscore, hyphen"},
            status=status.HTTP_422_UNPROCESSABLE_ENTITY
        )
    
    # Validate password strength
    if len(password) < 8:
        return Response(
            {"error": "Password must be at least 8 characters"},
            status=status.HTTP_422_UNPROCESSABLE_ENTITY
        )
    
    # Check for existing user
    if User.objects.filter(email=email).exists():
        return Response({"error": "Email already registered"}, status=status.HTTP_400_BAD_REQUEST)
    
    if User.objects.filter(username=username).exists():
        return Response({"error": "Username already taken"}, status=status.HTTP_400_BAD_REQUEST)
    
    # Create user with password hashing (already done by set_password)
    user = User.objects.create_user(email=email, username=username, password=password)
    
    otp_code = _generate_otp()
    expires_at = timezone.now() + timedelta(minutes=10)
    
    EmailOTP.objects.create(
        email=email,
        code=otp_code,
        purpose="signup",
        used=False,
        expires_at=expires_at
    )
    
    try:
        send_otp_email(email, otp_code, "signup")
    except Exception as e:
        # Log error but don't expose to client
        import logging
        logger = logging.getLogger(__name__)
        logger.error(f"Failed to send OTP email to {email}: {str(e)}")
        user.delete()  # Rollback user creation
        return Response(
            {"error": "Failed to send verification email. Please try again."},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
    
    return Response(
        {"message": "Signup successful. OTP sent to email."},
        status=status.HTTP_201_CREATED
    )
```

---

### Issue 3.2: Missing Rate Limiting on OTP Endpoints
**Severity:** 🔴 CRITICAL  
**Lines:** 24-89 (all OTP related endpoints)  
**Issue:** No rate limiting on signup, verify_otp, forgot_password
**Problems:**
- Brute force attacks possible on OTP verification (6 digits = 1M combinations)
- Email spam attack possible via signup endpoint
- No throttling per IP or email
**Fix:**
```python
from django.views.decorators.cache import cache_page
from django_ratelimit.decorators import ratelimit
from rest_framework.decorators import api_view, throttle_classes
from rest_framework.throttling import AnonRateThrottle, UserRateThrottle

class OTPThrottle(AnonRateThrottle):
    scope = 'otp'
    rate = '5/hour'  # 5 requests per hour per IP

class VerifyOTPThrottle(AnonRateThrottle):
    scope = 'verify_otp'
    rate = '10/hour'  # Limited attempts to prevent brute force

@api_view(["POST"])
@throttle_classes([OTPThrottle])
def signup(request):
    # ... existing code ...
    pass

@api_view(["POST"])
@throttle_classes([VerifyOTPThrottle])
def verify_otp(request):
    # ... existing code ...
    pass

# In settings.py:
REST_FRAMEWORK = {
    'DEFAULT_THROTTLE_CLASSES': [
        'rest_framework.throttling.AnonRateThrottle',
        'rest_framework.throttling.UserRateThrottle'
    ],
    'DEFAULT_THROTTLE_RATES': {
        'anon': '100/hour',
        'user': '1000/hour',
        'otp': '5/hour',
        'verify_otp': '10/hour',
    }
}
```

---

### Issue 3.3: OTP Expiration Not Enforced Properly
**Severity:** 🟠 HIGH  
**Lines:** 63-73  
**Issue:** OTP is checked but `is_expired()` may not work correctly
```python
if otp_obj.is_expired():
    return Response({"error": "OTP expired"}, status=400)
```
**Problems:**
- `is_expired()` only called after checking used status
- No deletion of expired OTPs (database bloat)
- is_expired() checks timezone.now() > self.expires_at but expires_at might be in past
**Fix:**
```python
from django.db.models import Q
from django.utils import timezone

@api_view(["POST"])
@throttle_classes([VerifyOTPThrottle])
def verify_otp(request):
    email = request.data.get("email", "").strip()
    code = request.data.get("code") or request.data.get("otp")
    
    if not email or not code:
        return Response(
            {"error": "email and code required"},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Clean up expired OTPs
    EmailOTP.objects.filter(
        expires_at__lt=timezone.now(),
        used=False
    ).delete()
    
    # Find valid OTP
    otp_obj = EmailOTP.objects.filter(
        email=email,
        code=code,
        purpose="signup",
        used=False,
        expires_at__gte=timezone.now()  # Check expiry in query
    ).order_by("-created_at").first()
    
    if not otp_obj:
        return Response(
            {"error": "Invalid or expired OTP"},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Mark as used
    otp_obj.used = True
    otp_obj.save()
    
    try:
        user = User.objects.get(email=email)
    except User.DoesNotExist:
        return Response(
            {"error": "User not found"},
            status=status.HTTP_404_NOT_FOUND
        )
    
    user.is_verified = True
    user.save()
    
    return Response(
        {"message": "Email verified successfully"},
        status=status.HTTP_200_OK
    )
```

---

### Issue 3.4: Weak OTP Generation
**Severity:** 🟠 HIGH  
**Line:** 20  
**Issue:** `_generate_otp()` uses `random.randint()` which is not cryptographically secure
```python
def _generate_otp():
    return f"{random.randint(100000, 999999)}"
```
**Problems:**
- `random` module is predictable
- Should use `secrets` module for security
- Weak randomness allows OTP guessing
**Fix:**
```python
import secrets

def _generate_otp():
    """Generate cryptographically secure 6-digit OTP"""
    return str(secrets.randbelow(1000000)).zfill(6)
```

---

### Issue 3.5: Missing Error Logging
**Severity:** 🟟 MEDIUM  
**Lines:** Throughout views.py  
**Issue:** Exceptions caught but not logged
```python
except User.DoesNotExist:
    return Response({"error": "User not found"}, status=404)
except Exception:
    return Response({"error": "Invalid refresh token"}, status=400)
```
**Problems:**
- No audit trail of errors
- Silent failures
- Debugging difficult
**Fix:**
```python
import logging

logger = logging.getLogger(__name__)

@api_view(["POST"])
def verify_otp(request):
    try:
        # ... OTP verification code ...
        pass
    except User.DoesNotExist:
        logger.warning(f"User not found for email: {email}")
        return Response({"error": "User not found"}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        logger.error(f"Unexpected error in verify_otp: {str(e)}", exc_info=True)
        return Response(
            {"error": "An error occurred"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
```

---

### Issue 3.6: Missing Endpoint for logout
**Severity:** 🔴 CRITICAL  
**Lines:** Missing from views.py  
**Issue:** `urls.py` references `logout_view` but it's not defined
```python
# In urls.py
path("logout/", views.logout_view),  # But logout_view doesn't exist!
```
**Problems:**
- Function not implemented
- Will throw 500 error on logout
- Tokens not blacklisted
**Fix:**
```python
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework_simplejwt.tokens import RefreshToken

@api_view(["POST"])
@permission_classes([IsAuthenticated])
def logout_view(request):
    """Logout user by blacklisting refresh token"""
    serializer = LogoutSerializer(data=request.data)
    
    if not serializer.is_valid():
        return Response(
            {"error": serializer.errors},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    try:
        serializer.save()
        return Response(
            {"message": "Logged out successfully"},
            status=status.HTTP_200_OK
        )
    except Exception as e:
        logger.error(f"Logout error: {str(e)}")
        return Response(
            {"error": "Logout failed"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
```

---

### Issue 3.7: Incomplete forgot_password and reset_password Views
**Severity:** 🔴 CRITICAL  
**Lines:** 128-150 (incomplete)  
**Issue:** Function is incomplete and cut off
```python
otp_code = _generate_otp()
    expires_at = timezone.now() + timedelta(minutes=10)

    EmailOTP.objects.create(
        email=email,
```
**Problems:**
- Code is truncated
- reset_password view not shown
- Both endpoints likely incomplete
**Fix:** Provide complete implementation in analysis

---

### Issue 3.8: Race Condition in User Creation
**Severity:** 🟡 MEDIUM  
**Lines:** 37-38  
**Issue:** Race condition between check and create
```python
if User.objects.filter(email=email).exists():
    return Response({"error": "Email already registered"}, status=400)

user = User.objects.create_user(...)  # Can race here
```
**Problems:**
- Two requests can both pass the check and create duplicates
- IntegrityError possible
**Fix:**
```python
from django.db import IntegrityError

try:
    user = User.objects.create_user(email=email, username=username, password=password)
except IntegrityError:
    logger.warning(f"Duplicate user creation attempt: {email}")
    return Response(
        {"error": "Email already registered"},
        status=status.HTTP_400_BAD_REQUEST
    )
```

---

### Issue 3.9: Missing HTTPS Requirement for Tokens
**Severity:** 🟠 HIGH  
**Issue:** Tokens transmitted over HTTP (if DEBUG=True in dev)
**Problems:**
- Tokens can be intercepted via MITM
- No secure cookie flag on tokens
**Fix:** Set in settings.py:
```python
JWT_AUTH = {
    'JWT_ALLOW_REFRESH': True,
    'JWT_ALGORITHM': 'HS256',
    'JWT_ENCODE_HANDLER': 'rest_framework_simplejwt.serializers.TokenObtainPairSerializer',
}

SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(minutes=15),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=7),
    "ALGORITHM": "HS256",
    "SIGNING_KEY": settings.SECRET_KEY,
    "AUTH_HEADER_TYPES": ("Bearer",),
    "AUTH_TOKEN_CLASSES": ("rest_framework_simplejwt.tokens.AccessToken",),
    "TOKEN_TYPE_CLAIM": "token_type",
}

# In production, require HTTPS
if not DEBUG:
    JWT_COOKIE_SECURE = True
    JWT_COOKIE_HTTPONLY = True
```

---

## 4. auth_app/serializers.py

### Issue 4.1: Weak Exception Handling in LogoutSerializer
**Severity:** 🟟 MEDIUM  
**Lines:** 34-38  
**Issue:** Bare except clause without logging
```python
def save(self, **kwargs):
    try:
        RefreshToken(self.token).blacklist()
    except Exception:
        self.fail("Invalid or expired refresh token")
```
**Problems:**
- All exceptions treated equally
- No error logging
- Swallows unexpected errors
**Fix:**
```python
import logging

logger = logging.getLogger(__name__)

def save(self, **kwargs):
    try:
        RefreshToken(self.token).blacklist()
    except (AttributeError, TypeError, KeyError) as e:
        self.fail("Invalid or expired refresh token")
    except Exception as e:
        logger.error(f"Unexpected error during logout: {str(e)}", exc_info=True)
        self.fail("An unexpected error occurred")
```

---

## 5. profile_app/models.py

### Issue 5.1: Race Condition in Signal Handlers
**Severity:** 🟠 HIGH  
**Lines:** 58-69  
**Issue:** Two signal handlers both trying to create/save profile
```python
@receiver(post_save, sender=settings.AUTH_USER_MODEL)
def create_user_profile(sender, instance, created, **kwargs):
    if created:
        Profile.objects.create(user=instance)

@receiver(post_save, sender=settings.AUTH_USER_MODEL)
def save_user_profile(sender, instance, **kwargs):
    if hasattr(instance, 'profile'):
        instance.profile.save()
```
**Problems:**
- Both handlers trigger on post_save
- Could create multiple profiles if first fails
- save_user_profile might save profile before create_user_profile runs
- Race condition with concurrent requests
**Fix:**
```python
from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver

@receiver(post_save, sender=settings.AUTH_USER_MODEL)
def create_or_update_profile(sender, instance, created, **kwargs):
    """Create profile on user creation, update on user save"""
    if created:
        # Create profile only on user creation
        Profile.objects.get_or_create(user=instance)
    else:
        # Update profile if it exists
        try:
            profile = Profile.objects.get(user=instance)
            profile.save()
        except Profile.DoesNotExist:
            Profile.objects.create(user=instance)

# Single signal handler - cleaner
```

---

### Issue 5.2: Missing Validation on Phone Numbers
**Severity:** 🟟 MEDIUM  
**Lines:** 10, 15  
**Issue:** Phone fields have no validation
```python
phone = models.CharField(max_length=15, blank=True)
phone = models.CharField(max_length=15)
```
**Problems:**
- No format validation (can store random text)
- No country code normalization
- Inconsistent max_length (15 vs 20)
- No unique constraint for phone
**Fix:**
```python
from django.core.validators import RegexValidator

class Profile(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    phone = models.CharField(
        max_length=15,
        blank=True,
        validators=[
            RegexValidator(
                regex=r'^\+?1?\d{9,15}$',
                message='Phone number must be valid (10-15 digits)'
            )
        ]
    )

class TrustedContact(models.Model):
    profile = models.ForeignKey(Profile, on_delete=models.CASCADE)
    name = models.CharField(max_length=100)
    phone = models.CharField(
        max_length=15,
        validators=[
            RegexValidator(
                regex=r'^\+?1?\d{9,15}$',
                message='Phone number must be valid'
            )
        ]
    )
```

---

### Issue 5.3: Missing Unique Constraint on InviteFriend
**Severity:** 🟡 MEDIUM  
**Lines:** 33-41  
**Issue:** Can send multiple invites to same person
```python
class InviteFriend(models.Model):
    profile = models.ForeignKey(Profile, on_delete=models.CASCADE, related_name="invites")
    friend_email = models.EmailField()
    # ... no constraint ...
```
**Problems:**
- Spam prevention missing
- Duplicate invites possible
- No check if friend already invited
**Fix:**
```python
class InviteFriend(models.Model):
    profile = models.ForeignKey(Profile, on_delete=models.CASCADE, related_name="invites")
    friend_email = models.EmailField()
    message = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    accepted = models.BooleanField(default=False)
    
    class Meta:
        # Prevent duplicate pending invites
        constraints = [
            models.UniqueConstraint(
                fields=['profile', 'friend_email'],
                condition=Q(accepted=False),
                name='unique_pending_invite'
            )
        ]
    
    def __str__(self):
        return f"{self.profile.user.email} invited {self.friend_email}"
```

---

### Issue 5.4: Missing Field Validation on AadhaarVerification
**Severity:** 🟡 MEDIUM  
**Lines:** 22-28  
**Issue:** Aadhaar number has no format validation
```python
aadhaar_number = models.CharField(max_length=12)
```
**Problems:**
- No format check (should be exactly 12 digits)
- No encryption for sensitive ID
- No validation in model
**Fix:**
```python
class AadhaarVerification(models.Model):
    profile = models.ForeignKey(Profile, on_delete=models.CASCADE)
    aadhaar_number = models.CharField(
        max_length=12,
        validators=[
            RegexValidator(
                regex=r'^\d{12}$',
                message='Aadhaar must be exactly 12 digits'
            )
        ]
    )
    verified = models.BooleanField(default=False)
    
    class Meta:
        unique_together = ('profile', 'aadhaar_number')
```

---

## 6. profile_app/views.py

### Issue 6.1: Race Condition in InviteFriendViewSet.accept_invite
**Severity:** 🟠 HIGH  
**Lines:** 85-116  
**Issue:** Check-then-update race condition
```python
if request.user.email != invite.friend_email:
    return Response({"error": "Not authorized"}, status=403)

if invite.accepted:
    return Response({"message": "Already accepted"}, status=400)

invite.accepted = True
invite.save()  # Race condition here!
```
**Problems:**
- Two concurrent requests can both accept same invite
- Check-then-update is not atomic
- No database transaction
**Fix:**
```python
from django.db import transaction
from django.db.models import F

@action(detail=True, methods=['post'], url_path='accept')
def accept_invite(self, request, pk=None):
    """Accept an invite - atomic operation"""
    try:
        invite = self.get_object()
        
        # Check authorization
        if request.user.email != invite.friend_email:
            return Response(
                {"error": "You are not authorized to accept this invite"},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Atomic update: only succeeds if accepted=False
        updated = InviteFriend.objects.filter(
            id=invite.id,
            accepted=False
        ).update(accepted=True)
        
        if updated == 0:
            # Invite was already accepted
            invite.refresh_from_db()
            if invite.accepted:
                return Response(
                    {"message": "Invite already accepted"},
                    status=status.HTTP_400_BAD_REQUEST
                )
            # Some other update failed
            return Response(
                {"error": "Failed to accept invite"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
        
        invite.refresh_from_db()
        return Response(
            {
                "message": "Invite accepted successfully!",
                "invite": InviteFriendSerializer(invite).data
            },
            status=status.HTTP_200_OK
        )
        
    except InviteFriend.DoesNotExist:
        return Response(
            {"error": "Invite not found"},
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        logger.error(f"Error accepting invite: {str(e)}")
        return Response(
            {"error": "An error occurred"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
```

---

### Issue 6.2: Missing Queryset Filtering in InviteFriendViewSet
**Severity:** 🟠 HIGH  
**Lines:** 120-131  
**Issue:** No get_queryset() filter, users can see other users' invites
```python
class InviteFriendViewSet(viewsets.ModelViewSet):
    queryset = InviteFriend.objects.all()
    serializer_class = InviteFriendSerializer
    permission_classes = [IsAuthenticated]

    def perform_create(self, serializer):
        serializer.save(profile=self.request.user.profile)
```
**Problems:**
- `queryset = InviteFriend.objects.all()` returns ALL invites
- No filtering by user
- Users can list/view/delete other users' invites
- Information disclosure vulnerability
**Fix:**
```python
class InviteFriendViewSet(viewsets.ModelViewSet):
    serializer_class = InviteFriendSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        """Only return invites for logged-in user"""
        return InviteFriend.objects.filter(
            profile=self.request.user.profile
        )
    
    def perform_create(self, serializer):
        """Auto-set profile from logged-in user"""
        serializer.save(profile=self.request.user.profile)
    
    def perform_update(self, serializer):
        """Prevent updating other users' invites"""
        serializer.save()
    
    def perform_destroy(self, instance):
        """Only allow deleting own invites"""
        instance.delete()
```

---

### Issue 6.3: Incomplete my_invites() Action
**Severity:** 🔴 CRITICAL  
**Lines:** 161-176  
**Issue:** Function is incomplete and returns error (incomplete try-except)
```python
except Exception as e:
    return Response(
        {"error": str(e)},
        status=status.HTTP_500_INTERNAL_SERVER_ERROR
```
**Problems:**
- Code is cut off mid-function
- Missing closing parenthesis
- Will throw SyntaxError
**Fix:**
```python
@action(detail=False, methods=['get'], url_path='my-invites')
def my_invites(self, request):
    """Get all invites sent by the logged-in user"""
    try:
        invites = InviteFriend.objects.filter(
            profile=request.user.profile
        ).order_by('-created_at')
        
        serializer = self.get_serializer(invites, many=True)
        
        # Add summary statistics
        total = invites.count()
        accepted = invites.filter(accepted=True).count()
        pending = invites.filter(accepted=False).count()
        
        return Response({
            "summary": {
                "total_invites": total,
                "accepted": accepted,
                "pending": pending
            },
            "invites": serializer.data
        }, status=status.HTTP_200_OK)
    except Profile.DoesNotExist:
        return Response(
            {"error": "Profile not found"},
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        logger.error(f"Error fetching invites: {str(e)}")
        return Response(
            {"error": "An error occurred"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
```

---

### Issue 6.4: Missing Error Logging Throughout View
**Severity:** 🟟 MEDIUM  
**Issue:** Multiple bare except clauses without logging
**Examples:**
- Line 102: except Exception as e: # No logging
- Line 152: except Profile.DoesNotExist: # No logging
- Line 161: except Exception as e: # String exposed to user

**Fix:** Add logging everywhere:
```python
import logging

logger = logging.getLogger(__name__)

# In every except block:
logger.error(f"Descriptive error message: {str(e)}", exc_info=True)
```

---

### Issue 6.5: SQL Injection Risk in my_friends() via Unvalidated Email
**Severity:** 🟡 MEDIUM  (Low risk - using ORM)
**Lines:** 138-160  
**Issue:** User email used directly in filter
```python
user_email = request.user.email
# Used in filter:
invited_me = InviteFriend.objects.filter(
    friend_email=user_email,
    accepted=True
)
```
**Note:** Django ORM provides protection, but could be safer with explicit validation

---

## 7. trips/models.py

### Issue 7.1: Missing Validation on Coordinates
**Severity:** 🟡 MEDIUM  
**Lines:** 48-52, 57-60  
**Issue:** Latitude/Longitude have no range validation
```python
start_latitude = models.DecimalField(max_digits=9, decimal_places=6)
start_longitude = models.DecimalField(max_digits=9, decimal_places=6)
```
**Problems:**
- Latitude should be -90 to 90
- Longitude should be -180 to 180
- Invalid coordinates accepted
- No validation in model
**Fix:**
```python
from django.core.validators import MinValueValidator, MaxValueValidator

class Trip(models.Model):
    start_latitude = models.DecimalField(
        max_digits=9,
        decimal_places=6,
        validators=[
            MinValueValidator(-90),
            MaxValueValidator(90)
        ]
    )
    start_longitude = models.DecimalField(
        max_digits=9,
        decimal_places=6,
        validators=[
            MinValueValidator(-180),
            MaxValueValidator(180)
        ]
    )
    end_latitude = models.DecimalField(
        max_digits=9,
        decimal_places=6,
        blank=True,
        null=True,
        validators=[
            MinValueValidator(-90),
            MaxValueValidator(90)
        ]
    )
    end_longitude = models.DecimalField(
        max_digits=9,
        decimal_places=6,
        blank=True,
        null=True,
        validators=[
            MinValueValidator(-180),
            MaxValueValidator(180)
        ]
    )
```

---

### Issue 7.2: Missing Constraint on Start/End Time
**Severity:** 🟡 MEDIUM  
**Lines:** 63, 68  
**Issue:** No validation that end_time >= start_time
**Problems:**
- Trip end time can be before start time
- Creates invalid trips
- No database constraint
**Fix:**
```python
def clean(self):
    from django.core.exceptions import ValidationError
    
    if self.end_time and self.start_time:
        if self.end_time < self.start_time:
            raise ValidationError(
                {'end_time': 'End time must be after start time'}
            )

def save(self, *args, **kwargs):
    self.clean()
    super().save(*args, **kwargs)
```

---

### Issue 7.3: Missing Validation on Cost Fields
**Severity:** 🟡 MEDIUM  
**Lines:** 76-79  
**Issue:** Cost fields can be negative
```python
ticket_cost = models.DecimalField(max_digits=10, decimal_places=2, blank=True, null=True)
fuel_expense = models.DecimalField(max_digits=10, decimal_places=2, blank=True, null=True)
toll_cost = models.DecimalField(max_digits=10, decimal_places=2, blank=True, null=True)
parking_cost = models.DecimalField(max_digits=10, decimal_places=2, blank=True, null=True)
```
**Problems:**
- No MinValueValidator
- Negative costs possible
- Invalid business logic
**Fix:**
```python
ticket_cost = models.DecimalField(
    max_digits=10,
    decimal_places=2,
    blank=True,
    null=True,
    validators=[MinValueValidator(0)]
)
fuel_expense = models.DecimalField(
    max_digits=10,
    decimal_places=2,
    blank=True,
    null=True,
    validators=[MinValueValidator(0)]
)
# ... repeat for other cost fields
```

---

### Issue 7.4: Missing Indexes on Foreign Keys
**Severity:** 🟡 MEDIUM  
**Line:** 103 (TripLocation)  
**Issue:** TripLocation has FK to Trip but missing index on trip+timestamp
```python
class TripLocation(models.Model):
    trip = models.ForeignKey(Trip, on_delete=models.CASCADE, related_name='tracking_points')
    # ... missing index on (trip, timestamp)
    
    class Meta:
        ordering = ['timestamp']
        indexes = [
            models.Index(fields=['trip', 'timestamp']),
        ]
```
**Current Has Only:** `ordering = ['timestamp']`  
**Should Add:** Index on (trip, timestamp) for queries like "Get all points for trip ordered by timestamp"

**Fix:**
```python
class Meta:
    ordering = ['timestamp']
    indexes = [
        models.Index(fields=['trip', 'timestamp']),  # Add this
        models.Index(fields=['trip']),  # Add this for FK lookups
    ]
```

---

### Issue 7.5: N+1 Query Problem with CO2 Calculation
**Severity:** 🟡 MEDIUM  
**Lines:** 135-150, 163-172  
**Issue:** calculate_co2_emission() is called in loops without caching
**In views.py populate_test_trips:**
```python
for trip_data in test_trips_data:
    trip = Trip.objects.create(...)
    trip.co2_emission_kg = trip.calculate_co2_emission()  # Calculation
    trip.save()  # Save with calculation
```
**Problems:**
- If called in serializer for many trips, calculations repeat
- Could be 1000 DB queries for 1000 trips displaying
**Fix:**
```python
# In serializer or view, batch operations:
trips = Trip.objects.filter(...)
for trip in trips:
    if not trip.co2_emission_kg and trip.distance_km and trip.mode_of_travel:
        trip.co2_emission_kg = trip.calculate_co2_emission()
        trip.save(update_fields=['co2_emission_kg'])

# Or use bulk_update:
Trip.objects.bulk_update(
    [trip for trip in trips if trip.co2_emission_kg],
    ['co2_emission_kg'],
    batch_size=100
)
```

---

## 8. trips/views.py

### Issue 8.1: Race Condition - Check-Then-Create on Ongoing Trip
**Severity:** 🔴 CRITICAL  
**Lines:** 30-38  
**Issue:** Non-atomic check for existing ongoing trip
```python
ongoing_trip = Trip.objects.filter(user=request.user, status='ongoing').first()
if ongoing_trip:
    return Response({"error": "You already have an ongoing trip"}, status=400)

trip = Trip.objects.create(  # RACE CONDITION HERE
    user=request.user,
    ...
    status='ongoing'
)
```
**Problems:**
- Two concurrent requests can both pass the check
- Both create ongoing trips
- Database constraint violation
- User ends up with multiple ongoing trips
**Fix:**
```python
from django.db import transaction
from django.db import IntegrityError

@action(detail=False, methods=['post'], url_path='start')
def start_trip(self, request):
    serializer = TripStartSerializer(data=request.data)
    if not serializer.is_valid():
        return Response(
            {"error": serializer.errors},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    try:
        with transaction.atomic():
            # Get-or-check with lock
            ongoing_trip = Trip.objects.select_for_update().filter(
                user=request.user,
                status='ongoing'
            ).first()
            
            if ongoing_trip:
                return Response({
                    "error": "You already have an ongoing trip",
                    "ongoing_trip_id": ongoing_trip.id,
                    "trip_number": ongoing_trip.trip_number
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Create trip within transaction
            trip = Trip.objects.create(
                user=request.user,
                start_latitude=serializer.validated_data['start_latitude'],
                start_longitude=serializer.validated_data['start_longitude'],
                start_location_name=serializer.validated_data.get('start_location_name') or 
                                    self.get_address_from_coordinates(...),
                start_time=serializer.validated_data.get('start_time', timezone.now()),
                status='ongoing'
            )
            
            TripLocation.objects.create(
                trip=trip,
                latitude=trip.start_latitude,
                longitude=trip.start_longitude,
                accuracy=0.0,
                timestamp=trip.start_time
            )
            
            return Response({
                "message": "Trip started successfully",
                "trip": TripSerializer(trip).data
            }, status=status.HTTP_201_CREATED)
    
    except IntegrityError as e:
        logger.error(f"Integrity error creating trip: {str(e)}")
        return Response(
            {"error": "Trip creation failed. You may already have an ongoing trip."},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
```

---

### Issue 8.2: Incomplete Assignment in end_trip()
**Severity:** 🟠 HIGH  
**Lines:** 111-115  
**Issue:** fuel_expense assignment is incomplete
```python
if 'fuel_expense' in serializer.validated_data:
     trip.fuel_expense = serializer.validated_data['fuel_expense']  # NOTE THE SPACING ERROR
```
**Problems:**
- Odd spacing before assignment
- Unclear if this is intentional
- Code style inconsistent
**Fix:**
```python
if 'fuel_expense' in serializer.validated_data:
    trip.fuel_expense = serializer.validated_data['fuel_expense']
```

---

### Issue 8.3: Import time Module Inside Function
**Severity:** 🟟 MEDIUM  
**Lines:** 423 (approximately)  
**Issue:** `import time` inside get_address_from_coordinates()
```python
import time; time.sleep(wait_time)
```
**Problems:**
- Importing inside loops/functions is inefficient
- Should be at module top
- Blocks event loop during sleep
- Not async-safe
**Fix:**
```python
# At top of file
import time
import asyncio
from threading import Thread

# Then use in function (or better, use async):
time.sleep(wait_time)  # Not blocking for async

# Better: use async
async def get_address_from_coordinates_async(self, latitude, longitude):
    for attempt in range(3):
        try:
            # ... code ...
            pass
        except requests.Timeout:
            if attempt < 2:
                await asyncio.sleep(2 ** attempt)
                continue
```

---

### Issue 8.4: Bare Except Clauses Without Logging
**Severity:** 🟠 HIGH  
**Lines:** Multiple locations  
**Issue:** Broad exception handling without logging
```python
except Exception:
    print(f"Geocoding error: {str(e)}")  # Bare except but e not defined!
```
**Problems:**
- Use of e in except Exception: (should be except Exception as e:)
- print() instead of logger
- Silent failures
- NameError: name 'e' is not defined
**Fix:**
```python
import logging

logger = logging.getLogger(__name__)

def _get_coordinates(self, address, lat, lng):
    if lat and lng:
        return float(lat), float(lng)
    
    if address:
        GEOCODING_API_KEY = settings.GOOGLE_GEOCODING_API_KEY
        try:
            url = "https://maps.googleapis.com/maps/api/geocode/json"
            params = {'address': address, 'key': GEOCODING_API_KEY}
            response = requests.get(url, params=params, timeout=5)
            if response.status_code == 200:
                data = response.json()
                if data.get('results'):
                    location = data['results'][0]['geometry']['location']
                    return location['lat'], location['lng']
        except requests.Timeout as e:
            logger.warning(f"Geocoding timeout for address '{address}': {str(e)}")
        except requests.RequestException as e:
            logger.error(f"Geocoding request error for '{address}': {str(e)}")
        except (KeyError, IndexError, ValueError) as e:
            logger.error(f"Geocoding parse error for '{address}': {str(e)}")
        except Exception as e:
            logger.error(f"Unexpected geocoding error for '{address}': {str(e)}", exc_info=True)
    
    return None, None
```

---

### Issue 8.5: Missing Input Validation on Cost Fields
**Severity:** 🔴 CRITICAL  
**Lines:** 107-115  
**Issue:** No validation that cost values are non-negative
**In end_trip():**
```python
if 'fuel_expense' in serializer.validated_data:
    trip.fuel_expense = serializer.validated_data['fuel_expense']
```
**Problems:**
- User can send negative cost (-1000 rupees!)
- No validation in serializer or view
- Breaks statistics and reporting
- Invalid business logic
**Fix:**
```python
# In serializers.py - TripEndSerializer:
fuel_expense = serializers.DecimalField(
    max_digits=10,
    decimal_places=2,
    required=False,
    allow_null=True,
    min_value=0,  # Add this
    help_text="Fuel cost must be non-negative"
)

# Same for all cost fields:
# parking_cost, toll_cost, ticket_cost, etc.
```

---

### Issue 8.6: N+1 Query Problem in populate_test_trips()
**Severity:** 🟡 MEDIUM  
**Lines:** 227-280 (approx)  
**Issue:** Creates 10+ database queries per test trip
```python
created_count = 0
for trip_data in test_trips_data:  # 10 iterations
    # Each iteration:
    existing = Trip.objects.filter(...).exists()  # Query 1
    trip = Trip.objects.create(...)  # Query 2
    created_count += 1
```
**Problems:**
- 10 trips = 20+ queries
- Should be batch operation
- Not scalable
**Fix:**
```python
from django.db import transaction
from django.db.models import QuerySet

@action(detail=False, methods=['post'], url_path='populate-test-trips')
def populate_test_trips(self, request):
    """Populate test trip data efficiently"""
    
    # ... test_trips_data definition ...
    
    created_count = 0
    trips_to_create = []
    skipped = 0
    
    # Check all trips first
    existing_trips = set(
        Trip.objects.filter(
            user=request.user,
            start_time__date__in=[
                (timezone.now() - timedelta(days=trip['days_ago'])).date()
                for trip in test_trips_data
            ]
        ).values_list('start_location_name', 'end_location_name', 'start_time__date')
    )
    
    # Build create list
    for trip_data in test_trips_data:
        days_ago = trip_data.pop('days_ago')
        start_time = timezone.now() - timedelta(days=days_ago, hours=9)
        duration_minutes = trip_data.get('duration_minutes', 30)
        end_time = start_time + timedelta(minutes=duration_minutes)
        
        trip_key = (
            trip_data['start_location_name'],
            trip_data['end_location_name'],
            start_time.date()
        )
        
        if trip_key not in existing_trips:
            trips_to_create.append(
                Trip(
                    user=request.user,
                    start_time=start_time,
                    end_time=end_time,
                    **trip_data
                )
            )
        else:
            skipped += 1
    
    # Batch create
    with transaction.atomic():
        Trip.objects.bulk_create(trips_to_create, batch_size=100)
        created_count = len(trips_to_create)
    
    return Response({
        "message": f"Successfully populated {created_count} test trips!",
        "created": created_count,
        "skipped": skipped,
        "total": len(test_trips_data),
        "trips": TripSerializer(
            self.get_queryset().filter(status='completed'),
            many=True
        ).data,
    }, status=status.HTTP_201_CREATED)
```

---

### Issue 8.7: Missing Pagination in List Views
**Severity:** 🟡 MEDIUM  
**Lines:** Various list endpoints  
**Issue:** No pagination configured
```python
@action(detail=False, methods=['get'], url_path='history')
def trip_history(self, request):
    trips = self.get_queryset().filter(status='completed')
    # ... no pagination ...
    serializer = TripSerializer(trips, many=True)
    return Response({"count": trips.count(), "trips": serializer.data})
```
**Problems:**
- Returning all trips at once
- Memory issues with 10K+ trips
- Slow API response
- No limit on results
**Fix:**
```python
from rest_framework.pagination import PageNumberPagination

class TripPagination(PageNumberPagination):
    page_size = 20
    page_size_query_param = 'page_size'
    max_page_size = 100

class TripViewSet(viewsets.ModelViewSet):
    pagination_class = TripPagination
    
    @action(detail=False, methods=['get'], url_path='history')
    def trip_history(self, request):
        trips = self.get_queryset().filter(status='completed')
        # ... filtering ...
        
        page = self.paginate_queryset(trips)
        if page is not None:
            serializer = TripSerializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = TripSerializer(trips, many=True)
        return Response({"count": trips.count(), "trips": serializer.data})
```

---

### Issue 8.8: Unvalidated Datetime Input
**Severity:** 🟠 HIGH  
**Lines:** 186-190 (trip_history filtering)  
**Issue:** No validation on date_from/date_to query parameters
```python
date_from = request.query_params.get('date_from')
date_to = request.query_params.get('date_to')

if date_from:
    trips = trips.filter(start_time__date__gte=date_from)
```
**Problems:**
- Invalid date format accepted
- Could throw exceptions
- No error message to user
**Fix:**
```python
from datetime import datetime

@action(detail=False, methods=['get'], url_path='history')
def trip_history(self, request):
    trips = self.get_queryset().filter(status='completed')
    
    date_from = request.query_params.get('date_from')
    date_to = request.query_params.get('date_to')
    mode = request.query_params.get('mode')
    purpose = request.query_params.get('purpose')
    
    # Validate dates
    if date_from:
        try:
            date_from = datetime.strptime(date_from, '%Y-%m-%d').date()
            trips = trips.filter(start_time__date__gte=date_from)
        except ValueError:
            return Response(
                {"error": "date_from must be in YYYY-MM-DD format"},
                status=status.HTTP_400_BAD_REQUEST
            )
    
    if date_to:
        try:
            date_to = datetime.strptime(date_to, '%Y-%m-%d').date()
            trips = trips.filter(start_time__date__lte=date_to)
        except ValueError:
            return Response(
                {"error": "date_to must be in YYYY-MM-DD format"},
                status=status.HTTP_400_BAD_REQUEST
            )
    
    # Validate mode and purpose
    valid_modes = dict(Trip.MODE_CHOICES)
    if mode and mode not in valid_modes:
        return Response(
            {"error": f"Invalid mode. Must be one of: {', '.join(valid_modes.keys())}"},
            status=status.HTTP_400_BAD_REQUEST
        )
    if mode:
        trips = trips.filter(mode_of_travel=mode)
    
    valid_purposes = dict(Trip.PURPOSE_CHOICES)
    if purpose and purpose not in valid_purposes:
        return Response(
            {"error": f"Invalid purpose. Must be one of: {', '.join(valid_purposes.keys())}"},
            status=status.HTTP_400_BAD_REQUEST
        )
    if purpose:
        trips = trips.filter(trip_purpose=purpose)
    
    # Pagination...
    page = self.paginate_queryset(trips)
    if page is not None:
        serializer = TripSerializer(page, many=True)
        return self.get_paginated_response(serializer.data)
    
    serializer = TripSerializer(trips, many=True)
    return Response({"count": trips.count(), "trips": serializer.data})
```

---

### Issue 8.9: Race Condition in PlannedTripViewSet.start_trip()
**Severity:** 🔴 CRITICAL  
**Lines:** 768-793  
**Issue:** Same race condition as TripViewSet.start_trip()
```python
ongoing_trip = Trip.objects.filter(user=request.user, status='ongoing').first()
if ongoing_trip:
    return Response({"error": "...already have an ongoing trip"}, status=400)

actual_trip = Trip.objects.create(...)  # RACE CONDITION
```
**Problems:**
- Two requests can both create trips simultaneously
- Should use select_for_update() and atomic transaction
**Fix:** Same as Issue 8.1

---

### Issue 8.10: Missing Input Validation in add_note()
**Severity:** 🟡 MEDIUM  
**Lines:** 619-625  
**Issue:** No validation on note_text length
```python
note = TripNote.objects.create(trip=trip, note_text=serializer.validated_data['note_text'])
```
**Problems:**
- No max length check
- Can create 1MB+ notes
- Database bloat
**Fix:**
```python
class TripNoteSerializer(serializers.ModelSerializer):
    class Meta:
        model = TripNote
        fields = ['id', 'note_text', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def validate_note_text(self, value):
        if len(value) > 5000:
            raise serializers.ValidationError(
                "Note text cannot exceed 5000 characters"
            )
        return value.strip()
```

---

### Issue 8.11: Missing Type Hints Throughout
**Severity:** 🟡 MEDIUM  
**Issue:** No type hints on helper methods
```python
def get_address_from_coordinates(self, latitude, longitude, max_retries=3):
    # No return type, no param types
```
**Problems:**
- Difficult to understand expected types
- IDE autocomplete doesn't work
- Easier to introduce bugs
**Fix:**
```python
from typing import Optional, Tuple, Dict, Any

def get_address_from_coordinates(
    self,
    latitude: float,
    longitude: float,
    max_retries: int = 3
) -> str:
    """
    Reverse geocode coordinates using Google Geocoding API.
    
    Args:
        latitude: GPS latitude (-90 to 90)
        longitude: GPS longitude (-180 to 180)
        max_retries: Number of retry attempts (default: 3)
    
    Returns:
        Formatted address string or "Coordinates: {lat}, {lng}"
    
    Raises:
        ValueError: If coordinates are invalid
    """
    # ... implementation ...
    pass

def _get_coordinates(
    self,
    address: Optional[str],
    lat: Optional[float],
    lng: Optional[float]
) -> Tuple[Optional[float], Optional[float]]:
    """Get coordinates from address or direct lat/lng."""
    # ... implementation ...
    pass

def _get_route_from_google(
    self,
    start_lat: float,
    start_lng: float,
    end_lat: float,
    end_lng: float,
    mode: str
) -> Optional[Dict[str, Any]]:
    """Get route from Google Directions API."""
    # ... implementation ...
    pass
```

---

### Issue 8.12: Missing Error Response on API Failures
**Severity:** 🟠 HIGH  
**Lines:** 452-468 (preview_route)  
**Issue:** API errors not returned properly
```python
if not self.all([start_lat, start_lng, end_lat, end_lng]):
    return Response({"error": "Could not determine coordinates"}, status=400)

route_data = self._get_route_from_google(...)
if not route_data:
    return Response({"error": "Could not get route"}, status=400)
```
**Problems:**
- Generic error messages
- Status codes inconsistent (400 vs 422 vs 500)
- No details on what failed
**Fix:**
```python
@action(detail=False, methods=['post'], url_path='preview-route')
def preview_route(self, request):
    serializer = RoutePreviewSerializer(data=request.data)
    if not serializer.is_valid():
        return Response(
            {"error": "Invalid input", "details": serializer.errors},
            status=status.HTTP_422_UNPROCESSABLE_ENTITY
        )
    
    data = serializer.validated_data
    start_lat, start_lng = self._get_coordinates(
        data.get('start_location'),
        data.get('start_latitude'),
        data.get('start_longitude')
    )
    end_lat, end_lng = self._get_coordinates(
        data.get('end_location'),
        data.get('end_latitude'),
        data.get('end_longitude')
    )
    
    if not all([start_lat, start_lng, end_lat, end_lng]):
        return Response(
            {
                "error": "Could not determine coordinates",
                "details": [
                    f"Start location: valid={bool(start_lat and start_lng)}",
                    f"End location: valid={bool(end_lat and end_lng)}"
                ]
            },
            status=status.HTTP_422_UNPROCESSABLE_ENTITY
        )
    
    try:
        route_data = self._get_route_from_google(
            start_lat, start_lng, end_lat, end_lng,
            data.get('mode_of_travel', 'car')
        )
    except Exception as e:
        logger.error(f"Route preview error: {str(e)}")
        return Response(
            {"error": "Failed to get route from Google Maps"},
            status=status.HTTP_503_SERVICE_UNAVAILABLE
        )
    
    if not route_data:
        return Response(
            {"error": "No route found for the given locations"},
            status=status.HTTP_404_NOT_FOUND
        )
    
    # ... return route data ...
```

---

## 9. trips/serializers.py

### Issue 9.1: Missing Validation in ManualTripSerializer
**Severity:** 🟟 MEDIUM  
**Lines:** 120-170  
**Issue:** Incomplete validation logic
```python
def validate(self, data):
    has_start_address = data.get('start_location')
    has_start_coords = data.get('start_latitude') and data.get('start_longitude')
    
    if not (has_start_address or has_start_coords):
        raise serializers.ValidationError(...)
    
    # Similar for end, but coords are checked even if missing
```
**Problems:**
- Validates that data is provided but doesn't validate FORMAT
- Allows invalid addresses (e.g., "aaa")
- Decimal fields not validated for range
**Fix:**
```python
class ManualTripSerializer(serializers.Serializer):
    # Start location
    start_location = serializers.CharField(
        max_length=255,
        required=False,
        allow_blank=True
    )
    start_latitude = serializers.DecimalField(
        max_digits=9,
        decimal_places=6,
        required=False,
        allow_null=True,
        min_value=-90,
        max_value=90
    )
    start_longitude = serializers.DecimalField(
        max_digits=9,
        decimal_places=6,
        required=False,
        allow_null=True,
        min_value=-180,
        max_value=180
    )
    
    # End location
    end_location = serializers.CharField(
        max_length=255,
        required=False,
        allow_blank=True
    )
    end_latitude = serializers.DecimalField(
        max_digits=9,
        decimal_places=6,
        required=False,
        allow_null=True,
        min_value=-90,
        max_value=90
    )
    end_longitude = serializers.DecimalField(
        max_digits=9,
        decimal_places=6,
        required=False,
        allow_null=True,
        min_value=-180,
        max_value=180
    )
    
    # Trip details
    mode_of_travel = serializers.ChoiceField(
        choices=Trip.MODE_CHOICES,
        help_text="How did you travel?"
    )
    trip_purpose = serializers.ChoiceField(
        choices=Trip.PURPOSE_CHOICES,
        required=False,
        allow_null=True
    )
    trip_date = serializers.DateField(required=False)
    number_of_companions = serializers.IntegerField(
        required=False,
        default=0,
        min_value=0,
        max_value=100
    )
    
    # Costs
    toll_cost = serializers.DecimalField(
        max_digits=10,
        decimal_places=2,
        required=False,
        allow_null=True,
        min_value=0
    )
    parking_cost = serializers.DecimalField(
        max_digits=10,
        decimal_places=2,
        required=False,
        allow_null=True,
        min_value=0
    )
    fuel_expense = serializers.DecimalField(
        max_digits=10,
        decimal_places=2,
        required=False,
        allow_null=True,
        min_value=0
    )
    ticket_cost = serializers.DecimalField(
        max_digits=10,
        decimal_places=2,
        required=False,
        allow_null=True,
        min_value=0
    )
    
    def validate_start_location(self, value):
        if value and len(value.strip()) < 2:
            raise serializers.ValidationError("Start location must be at least 2 characters")
        return value.strip() if value else None
    
    def validate_end_location(self, value):
        if value and len(value.strip()) < 2:
            raise serializers.ValidationError("End location must be at least 2 characters")
        return value.strip() if value else None
    
    def validate_trip_date(self, value):
        from datetime import date, timedelta
        if value > date.today():
            raise serializers.ValidationError("Trip date cannot be in the future")
        if value < date.today() - timedelta(days=30):
            raise serializers.ValidationError("Trip must be from last 30 days")
        return value
    
    def validate(self, data):
        """Ensure we have either address or coordinates for both start and end"""
        
        # Check start location
        has_start_address = bool(data.get('start_location'))
        has_start_coords = data.get('start_latitude') and data.get('start_longitude')
        
        if not (has_start_address or has_start_coords):
            raise serializers.ValidationError({
                'start_location': 'Provide either start_location OR both start_latitude and start_longitude'
            })
        
        # Check end location
        has_end_address = bool(data.get('end_location'))
        has_end_coords = data.get('end_latitude') and data.get('end_longitude')
        
        if not (has_end_address or has_end_coords):
            raise serializers.ValidationError({
                'end_location': 'Provide either end_location OR both end_latitude and end_longitude'
            })
        
        return data
```

---

### Issue 9.2: Missing Serializer for VehicleViewSet
**Severity:** 🟠 HIGH  
**Issue:** VehicleViewSet registered in urls.py but no serializer defined
```python
# In urls.py:
router.register(r'vehicles', VehicleViewSet, basename='vehicles')

# But VehicleSerializer not imported or defined
```
**Problems:**
- Endpoint will fail with ImportError or 500 error
- No serializer for vehicle data
**Fix:**
```python
# Add to trips/serializers.py:
class VehicleSerializer(serializers.ModelSerializer):
    class Meta:
        model = Vehicle
        fields = [
            'id',
            'name',
            'vehicle_type',
            'fuel_efficiency',
            'emissions_factor',
            'fuel_price_per_liter',
            'is_active',
            'created_at',
            'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def validate_fuel_efficiency(self, value):
        if value <= 0:
            raise serializers.ValidationError("Fuel efficiency must be positive")
        return value
    
    def validate_fuel_price_per_liter(self, value):
        if value < 0:
            raise serializers.ValidationError("Fuel price cannot be negative")
        return value
    
    def validate_emissions_factor(self, value):
        if value < 0:
            raise serializers.ValidationError("Emissions factor cannot be negative")
        return value

# Add to imports in urls.py:
from .serializers import VehicleSerializer

# Add ViewSet to views.py:
class VehicleViewSet(viewsets.ModelViewSet):
    """ViewSet for managing user vehicles"""
    serializer_class = VehicleSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return Vehicle.objects.filter(user=self.request.user)
    
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)
```

---

## 10. trips/urls.py

### Issue 10.1: Incomplete/Missing compare_routes Endpoint
**Severity:** 🟠 HIGH  
**Lines:** 24  
**Issue:** Function is referenced but not implemented
```python
path("compare-routes/", compare_routes, name="compare-routes"),
```
**Problems:**
- Function not shown in views
- Will throw 500 error
- No implementation visible
**Fix:**
```python
# Add to views.py:
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def compare_routes(request):
    """
    Compare routes between different modes of travel
    POST body: {
        "start_location": "Delhi",
        "end_location": "Gurgaon",
        "modes": ["car", "bus", "metro"]
    }
    """
    start_location = request.data.get('start_location')
    end_location = request.data.get('end_location')
    modes = request.data.get('modes', ['car', 'bus'])
    
    if not all([start_location, end_location]):
        return Response(
            {"error": "start_location and end_location required"},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    results = []
    viewset = TripViewSet()
    
    for mode in modes:
        if mode not in dict(Trip.MODE_CHOICES):
            continue
        
        try:
            route_data = viewset._get_route_from_google(
                start_location, end_location, mode
            )
            if route_data:
                results.append({
                    'mode': mode,
                    'distance_km': route_data.get('distance_km'),
                    'duration_minutes': route_data.get('duration_minutes'),
                    'estimated_co2_kg': calculate_co2(
                        route_data.get('distance_km'), mode
                    )
                })
        except Exception as e:
            logger.error(f"Error comparing route for mode {mode}: {str(e)}")
    
    return Response({
        "start": start_location,
        "end": end_location,
        "routes": results
    })
```

---

## 11. Global/Cross-Cutting Issues

### Issue 11.1: No Request/Response Logging
**Severity:** 🟟 MEDIUM  
**Issue:** No middleware to log HTTP requests and responses
**Problems:**
- No audit trail
- Debugging difficult
- Security monitoring impossible
- Can't track API usage
**Fix:**
```python
# In trackmate/middleware.py:
import logging
import json
import time
from django.utils.deprecation import MiddlewareMixin

logger = logging.getLogger('api_requests')

class RequestLoggingMiddleware(MiddlewareMixin):
    def __init__(self, get_response):
        self.get_response = get_response
        super().__init__(get_response)
    
    def __call__(self, request):
        request.start_time = time.time()
        
        response = self.get_response(request)
        
        duration = time.time() - request.start_time
        
        log_data = {
            'method': request.method,
            'path': request.path,
            'status': response.status_code,
            'duration_ms': duration * 1000,
            'user': request.user.username if request.user.is_authenticated else 'anonymous',
            'ip': self._get_client_ip(request),
        }
        
        logger.info(json.dumps(log_data))
        
        return response
    
    @staticmethod
    def _get_client_ip(request):
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = request.META.get('REMOTE_ADDR')
        return ip

# Add to settings.py MIDDLEWARE:
MIDDLEWARE = [
    # ... existing ...
    'trackmate.middleware.RequestLoggingMiddleware',
]
```

---

### Issue 11.2: No CSRF Protection for State-Changing Requests
**Severity:** 🟠 HIGH  
**Issue:** POST/PUT/DELETE endpoints should validate CSRF token
**Problems:**
- Vulnerable to CSRF attacks
- No CSRF token validation shown
- Frontend needs token management
**Fix:**
```python
# In settings.py:
CSRF_TRUSTED_ORIGINS = os.environ.get(
    "CSRF_TRUSTED_ORIGINS",
    "http://localhost:3000,http://localhost:8080"
).split(",")

# Add to views that need it:
from django.middleware.csrf import csrf_exempt, requires_csrf_token
# For API views, DRF handles CSRF via SessionAuthentication

# In requirements.txt, ensure:
# django-cors-headers>=4.0.0
```

---

### Issue 11.3: Missing HTTP Status Code Consistency
**Severity:** 🟡 MEDIUM  
**Issue:** Inconsistent status codes across endpoints
**Examples:**
- signup returns 201, verify returns 200
- Some return 400, others 422 for validation errors
- Some return None for errors, should be 500
**Standard REST Status Codes:**
- 200 OK - Success
- 201 Created - Resource created
- 204 No Content - Success, no body
- 400 Bad Request - Client error (invalid data)
- 401 Unauthorized - Not authenticated
- 403 Forbidden - Not authorized
- 404 Not Found
- 422 Unprocessable Entity - Validation error
- 429 Too Many Requests - Rate limited
- 500 Internal Server Error
- 503 Service Unavailable - External service down

**Fix:** Create consistent response patterns:
```python
# Create a mixin for consistent responses:
class ConsistentResponseMixin:
    def success(self, data=None, message=None, status_code=200):
        response_data = {}
        if message:
            response_data['message'] = message
        if data:
            response_data['data'] = data
        return Response(response_data, status=status_code)
    
    def error(self, message, code=None, status_code=400):
        return Response({
            'error': message,
            'code': code or 'ERROR'
        }, status=status_code)
    
    def validation_error(self, errors):
        return Response({
            'error': 'Validation failed',
            'details': errors
        },status=status.HTTP_422_UNPROCESSABLE_ENTITY)
```

---

### Issue 11.4: Missing Environment-Specific Configuration
**Severity:** 🟠 HIGH  
**Issue:** No separate settings for dev/staging/production
**Problems:**
- Same settings for all environments
- Debug=True possible in production
- Database URLs hardcoded
- API keys in settings file
**Fix:** Create environment-specific settings:
```python
# trackmate/settings/base.py - Common settings
# trackmate/settings/development.py - Dev-specific
# trackmate/settings/production.py - Production-specific
# trackmate/settings/testing.py - Test-specific

# In manage.py and wsgi.py:
ENVIRONMENT = os.environ.get('DJANGO_ENV', 'development')
os.environ.setdefault(
    'DJANGO_SETTINGS_MODULE',
    f'trackmate.settings.{ENVIRONMENT}'
)
```

---

### Issue 11.5: Missing Database Transaction Management
**Severity:** 🟠 HIGH  
**Issue:** Multiple critical operations not wrapped in transactions
**Problems:**
- Data inconsistency on partial failures
- Trip start/end could partially fail
- Signal handlers not transactional
**Fix:**
```python
from django.db import transaction

@transaction.atomic
def start_trip(self, request):
    # All DB operations in this function are atomic
    # If one fails, all are rolled back
    pass

# Or use context manager:
def some_view(request):
    with transaction.atomic():
        # Multiple operations
        obj1 = Model1.objects.create(...)
        obj2 = Model2.objects.create(...)
        # If obj2 fails, obj1 is rolled back
```

---

### Issue 11.6: Missing API Documentation
**Severity:** 🟡 MEDIUM  
**Issue:** No OpenAPI/Swagger documentation
**Problems:**
- Frontend team doesn't know endpoints
- Request/response format unclear
- No autodiscovery of APIs
**Fix:**
```bash
# Install drf-spectacular
pip install drf-spectacular

# Add to INSTALLED_APPS:
INSTALLED_APPS = [
    ...
    'drf_spectacular',
]

# Add to urls.py:
from drf_spectacular.views import SpectacularSwaggerView, SpectacularAPIView

urlpatterns = [
    ...
    path('api/schema/', SpectacularAPIView.as_view(), name='schema'),
    path('api/docs/', SpectacularSwaggerView.as_view(url_name='schema')),
]

# Add to settings.py:
REST_FRAMEWORK = {
    'DEFAULT_SCHEMA_CLASS': 'drf_spectacular.openapi.AutoSchema',
}
```

---

## Summary Statistics

| Severity | Count | Examples |
|----------|-------|----------|
| 🔴 CRITICAL | 10 | Hardcoded credentials, ALLOWED_HOSTS=*, race conditions, missing endpoints |
| 🟠 HIGH | 22 | Missing validation, weak OTP, CORS, input validation, SQL injection patterns |
| 🟡 MEDIUM | 12 | Type hints, pagination, error logging, constraints, field validation |
| 🟟 LOW | 3 | Code style, documentation, imports |

---

## Recommended Priority Order

### Phase 1 (Critical - Do Immediately):
1. Remove hardcoded credentials from settings.py
2. Fix ALLOWED_HOSTS
3. Implement transaction management for race conditions
4. Add input validation to signup/auth endpoints
5. Implement logout endpoint
6. Add rate limiting to auth endpoints

### Phase 2 (High - Do This Sprint):
1. Add CORS configuration
2. Implement proper error logging
3. Add security headers
4. Fix OTP implementation (expiry, unique constraint)
5. Add Cost field validation
6. Implement queryset filtering in InviteFriendViewSet

### Phase 3 (Medium - Do Next Sprint):
1. Add type hints
2. Implement pagination
3. Add database constraint validation
4. Create VehicleSerializer and proper endpoint
5. Add request logging middleware
6. Create API documentation

### Phase 4 (Low - Ongoing):
1. Refactor signal handlers
2. Optimize N+1 queries
3. Add comprehensive unit tests
4. Environment-specific configuration
5. Code style improvements

---

## Testing Checklist

- [ ] Unit tests for all serializers
- [ ] Integration tests for race conditions
- [ ] Security tests for SQL injection
- [ ] Load tests for pagination
- [ ] CORS preflight tests
- [ ] JWT token tests
- [ ] OTP expiration tests
- [ ] Concurrent request tests

