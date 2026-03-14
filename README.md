# TrackMate - Trip Tracking & Analysis Application 🚗

A comprehensive transportation tracking application built with **Flutter** (frontend) and **Django REST Framework** (backend) that monitors trips, calculates CO₂ emissions, manages trip costs, and provides detailed analytics.

## Project Structure

```
Main_app_TKM/
├── Tkm_frontend/          # Flutter Mobile Application
│   └── TRACKMATE/         # Flutter project root
│       ├── lib/           # Dart source code
│       ├── android/       # Android build configuration
│       ├── ios/           # iOS build configuration
│       ├── pubspec.yaml   # Flutter dependencies
│       └── .env.example   # Environment variables template
│
└── Tkm_backend/           # Django REST API
    └── Track_Mate/        # Django project root
        ├── manage.py      # Django management script
        ├── trackmate/     # Django settings
        ├── auth_app/      # Authentication module
        ├── trips/         # Trip management module
        ├── profile_app/   # User profile module
        ├── requirements.txt
        └── .env.example   # Environment variables template
```

## Features ✨

### Frontend (Flutter)
- 📍 Real-time GPS trip tracking with live map visualization
- 🚗 Automatic trip detection by mode of travel
- 💰 Trip cost calculation (fuel, tolls, parking)
- 🌱 CO₂ emission tracking and carbon footprint analysis
- 📊 Comprehensive statistics dashboard with charts
- 📅 Trip history and calendar view
- 🔐 Secure JWT-based authentication
- 📱 Offline-capable with local data caching

### Backend (Django REST Framework)
- 🔐 JWT token-based authentication with OTP email verification
- 🛡️ Comprehensive input validation and security measures
- 📊 RESTful API endpoints for trips, users, and analytics
- 📧 Email-based OTP verification for sign-up and password reset
- 🔒 Secure password reset flow
- 📱 Cross-platform API support

## Tech Stack

### Frontend
- **Framework:** Flutter (Dart 3.9.0+)
- **State Management:** GetX
- **Maps:** Google Maps Flutter
- **Location:** Geolocator, Geocoding
- **Charts:** FL Chart
- **HTTP Client:** Dart HTTP

### Backend
- **Framework:** Django 4.2.17
- **API:** Django REST Framework
- **Authentication:** SimpleJWT
- **Database:** SQLite (development), PostgreSQL (production)
- **Email Service:** Gmail SMTP
- **Security:** CORS headers, SSL/TLS support

## Quick Start

### Prerequisites

- **Flutter:** 3.9.0 or higher
- **Python:** 3.9+
- **Node.js** (optional, for some build tools)
- **Git:** Latest version
- **Google Maps API Keys** (Get from [Google Cloud Console](https://console.cloud.google.com/))
- **Gmail Account** (For OTP email service)

### Frontend Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/simpliarjun/Main_app_TKM.git
   cd Main_app_TKM/Tkm_frontend/TRACKMATE
   ```

2. **Create .env file from template:**
   ```bash
   cp .env.example .env
   ```

3. **Add your Google Maps API keys to `.env`:**
   ```env
   google_translate_api_key=YOUR_API_KEY_HERE
   places_api_key=YOUR_API_KEY_HERE
   directions_api_key=YOUR_API_KEY_HERE
   geocoding_api_key=YOUR_API_KEY_HERE
   API_BASE_URL=http://your-backend-server.com/api
   ```

4. **Install dependencies:**
   ```bash
   flutter pub get
   ```

5. **Run the app:**
   ```bash
   flutter run
   ```

6. **Build production APK:**
   ```bash
   flutter build apk --release
   ```

### Backend Setup

1. **Navigate to backend directory:**
   ```bash
   cd Main_app_TKM/Tkm_backend/Track_Mate
   ```

2. **Create Python virtual environment:**
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

4. **Create .env file from template:**
   ```bash
   cp .env.example .env
   ```

5. **Configure .env with your credentials:**
   ```env
   DJANGO_SECRET_KEY=your-secret-key-here
   DJANGO_DEBUG=False
   EMAIL_HOST_USER=your-gmail@gmail.com
   EMAIL_HOST_PASSWORD=your-app-password
   DB_NAME=trackmate_db
   DB_USER=trackmate_user
   DB_PASSWORD=your-db-password
   DB_HOST=localhost
   DB_PORT=5432
   ```

6. **Run migrations:**
   ```bash
   python manage.py makemigrations
   python manage.py migrate
   ```

7. **Create superuser:**
   ```bash
   python manage.py createsuperuser
   ```

8. **Run development server:**
   ```bash
   python manage.py runserver
   ```

## Environment Variables ⚙️

### Important Security Note ⚠️
**Never commit `.env` files to repository!** Sensitive information like API keys and database credentials should only be in your local `.env` files.

Use `.env.example` as a template and create your own `.env` with actual values.

#### Frontend .env Variables
- `google_translate_api_key` - Google Translate API key
- `places_api_key` - Google Places API key
- `directions_api_key` - Google Directions API key
- `geocoding_api_key` - Google Geocoding API key
- `API_BASE_URL` - Backend API base URL

#### Backend .env Variables
- `DJANGO_SECRET_KEY` - Django secret key (auto-generated)
- `DJANGO_DEBUG` - Debug mode (False in production)
- `EMAIL_HOST_USER` - Gmail account for OTP emails
- `EMAIL_HOST_PASSWORD` - Gmail app password
- `DB_NAME` - Database name
- `DB_USER` - Database user
- `DB_PASSWORD` - Database password
- `DB_HOST` - Database host
- `DB_PORT` - Database port

## API Endpoints 🔌

### Authentication
- `POST /api/auth/signup/` - User registration with OTP
- `POST /api/auth/login/` - User login
- `POST /api/auth/verify/` - OTP verification
- `POST /api/auth/forgot-password/` - Request password reset
- `POST /api/auth/reset-password/` - Reset password with OTP
- `POST /api/auth/logout/` - Logout and blacklist token

### Trips
- `GET /api/trips/` - List user trips
- `POST /api/trips/` - Create new trip
- `GET /api/trips/{id}/` - Trip details
- `PUT /api/trips/{id}/` - Update trip
- `DELETE /api/trips/{id}/` - Delete trip

### Profile
- `GET /api/profile/` - User profile details
- `PUT /api/profile/` - Update profile
- `GET /api/profile/stats/` - User statistics

## Development Workflow 🔄

### Making Changes
1. Create a feature branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes and commits:
   ```bash
   git add .
   git commit -m "Add feature: your feature description"
   ```

3. Push to GitHub:
   ```bash
   git push origin feature/your-feature-name
   ```

4. Create a Pull Request on GitHub

### Code Standards
- Follow Dart/Flutter style guide for frontend
- Follow PEP 8 for Python/Django backend
- Use meaningful commit messages
- Keep commits small and focused

## Security Considerations 🔒

1. **API Keys:** All API keys are stored in `.env` files (never in source code)
2. **Authentication:** JWT tokens with automatic refresh
3. **Email Verification:** OTP-based email verification for signup
4. **Password Security:** Passwords are cryptographically hashed
5. **CORS:** Properly configured for production domains
6. **Database:** SQL injection prevention via ORM
7. **HTTPS:** Required for production deployments

## Testing 🧪

### Backend Tests
```bash
cd Tkm_backend/Track_Mate
python manage.py test
```

### Frontend Tests
```bash
cd Tkm_frontend/TRACKMATE
flutter test
```

## Deployment 🚀

### Frontend (Android)
1. Build release APK:
   ```bash
   flutter build apk --release
   ```

2. Upload to Google Play Store using Android Studio or CLI

### Backend (Production)
1. Use production-ready server (e.g., Gunicorn, uWSGI)
2. Set `DJANGO_DEBUG=False` in production
3. Use PostgreSQL database for production
4. Configure proper ALLOWED_HOSTS in settings
5. Set up HTTPS/SSL certificates
6. Use environment variables for all secrets

## Troubleshooting 🔧

### Common Issues

**Flutter build fails:**
```bash
flutter clean
flutter pub get
flutter pub cache repair
```

**Android gradle issues:**
```bash
cd android
./gradlew clean
./gradlew build
```

**Django migration errors:**
```bash
python manage.py makemigrations
python manage.py migrate --fake-initial
```

**API connection issues:**
- Verify `API_BASE_URL` in `.env`
- Check backend server is running
- Verify CORS settings in Django

## Contributing 🤝

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License 📄

This project is licensed under the MIT License - see the LICENSE file for details.

## Support 💬

For issues, questions, or suggestions:
1. Open an issue on GitHub
2. Check existing documentation
3. Review API documentation in README

## Acknowledgments 🙏

- Flutter team for the excellent framework
- Django community for robust backend framework
- Google Maps API for location services
- All contributors and testers

---

**Last Updated:** March 14, 2026

**Project Status:** Active Development ✅
