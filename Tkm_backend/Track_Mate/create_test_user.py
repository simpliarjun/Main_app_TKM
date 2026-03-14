#!/usr/bin/env python
import os
import django

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "trackmate.settings")
django.setup()

from auth_app.models import User

# Create test user
user, created = User.objects.get_or_create(
    email="test@example.com",
    defaults={
        "username": "testuser",
        "is_active": True,
        "is_verified": True,
    }
)

if created:
    user.set_password("test123456")
    user.save()
    print(f"✅ Created test user: test@example.com / test123456")
else:
    # Update password for existing user
    user.set_password("test123456")
    user.save()
    print(f"✅ Updated test user password: test@example.com / test123456")

print(f"✅ Test user ready!")
print(f"   Email: test@example.com")
print(f"   Password: test123456")
