# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

This repository contains a **complete multi-institutional Smart Attendance System** for educational institutions, developed for the Smart India Hackathon (SIH). The project is enterprise-ready with:

1. **Backend**: Flask API with JWT authentication, face recognition, AI integration, and multi-institutional support
2. **Frontend**: Flutter mobile app with comprehensive admin dashboard for complete institution management
3. **Features**: Any college can register, create dynamic academic structures, and manage their own attendance system

## Development Environment Setup

### Backend (Flask)

To set up and run the Flask backend:

```bash
cd sih_smart_app/backend
python -m venv venv
.\venv\Scripts\activate  # Windows
source venv/bin/activate  # Linux/macOS
pip install -r requirements.txt
flask run
```

The server will start on http://localhost:5000 with API endpoints available at http://localhost:5000/api/.

### Frontend (Flutter)

To set up and run the Flutter mobile app:

```bash
cd sih_smart_app/frontend/mobile_app
flutter pub get
flutter run
```

## Common Development Tasks

### Backend Development

#### Running Flask Development Server

```bash
cd sih_smart_app/sih_smart_app/backend
# Install dependencies
pip install -r requirements.txt
pip install PyJWT google-generativeai

# Run server
python app.py
```

#### Database Management

The application uses SQLAlchemy with enhanced models for multi-institutional support:

```bash
cd sih_smart_app/sih_smart_app/backend
flask db init      # Only needed for first-time setup
flask db migrate -m "Description"  # Create migration
flask db upgrade   # Apply migration
```

#### Testing JWT Authentication

```bash
# Login to get JWT token
curl -X POST http://localhost:5000/api/login \
  -H "Content-Type: application/json" \
  -d '{"college_id": "admin", "password": "password", "role": "admin"}'

# Use token for admin operations
curl -X GET http://localhost:5000/api/admin/dashboard/stats \
  -H "Authorization: Bearer <jwt-token>"
```

#### Running Tests

```bash
cd sih_smart_app/sih_smart_app/backend
pytest  # When tests are added
```

### Frontend Development

#### Run Flutter App

```bash
cd sih_smart_app/sih_smart_app/frontend/mobile_app
flutter pub get    # Install dependencies
flutter run        # Run on connected device
```

#### Run Flutter App on Specific Device

```bash
cd sih_smart_app/sih_smart_app/frontend/mobile_app
flutter devices    # List available devices
flutter run -d <device_id>
```

#### Build for Production

```bash
cd sih_smart_app/sih_smart_app/frontend/mobile_app
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release
```

#### Development Tools

```bash
cd sih_smart_app/sih_smart_app/frontend/mobile_app
flutter test       # Run tests
dart format .      # Format code
flutter analyze    # Analyze code quality
```

## Architecture Overview

### Backend Architecture (Multi-Institutional)

The backend is a comprehensive Flask application with enterprise-grade features:

- **app.py**: Main Flask application with JWT-secured routes
- **auth.py**: JWT authentication system with role-based access control
- **admin_routes.py**: Complete admin management API (institutions, users, academics)
- **models.py**: Enhanced SQLAlchemy models with proper relationships and data isolation
- **config.py**: Development configuration
- **production_config.py**: Production-ready configuration

Key components:
- **JWT Authentication**: Secure token-based authentication for all API endpoints
- **Multi-Institutional Support**: Complete data isolation between institutions
- **Role-Based Access**: Admin, Teacher, Student permissions with appropriate restrictions
- **Database Models**: Institution, User, Branch, Semester, Subject, ClassSchedule, AttendanceRecord
- **Face Recognition**: DeepFace integration for biometric attendance
- **AI Integration**: Google Gemini API for personalized study suggestions

### Frontend Architecture (Complete Admin System)

The Flutter mobile app is a comprehensive multi-institutional management platform:

- **main.dart**: Entry point with JWT-aware routing and theme
- **services/api_service.dart**: Complete API integration with JWT token management
- **screens/**: Full-featured screens for all user roles and admin functions
  - **admin_main_dashboard.dart**: Real-time statistics and navigation hub
  - **admin_user_management.dart**: Complete CRUD for students and teachers
  - **admin_branch_management.dart**: Academic structure management
  - **admin_subject_management.dart**: Hierarchical subject management
  - **admin_timetable_management.dart**: Visual schedule creation
  - **admin_enrollment_management.dart**: Guided student enrollment
  - **login_screen.dart**: JWT authentication
  - **student_dashboard.dart**: AI-powered student interface
  - **teacher_dashboard.dart**: Attendance recording interface

The mobile app supports complete institutional management:
1. **Admin**: Full institution setup and management capabilities
2. **Teacher**: Class management and biometric attendance recording
3. **Student**: Smart routines and attendance tracking

### API Communication

The mobile app uses JWT-secured communication with the Flask backend:
- **Base URLs**: Configured in `api_service.dart` (`http://10.0.2.2:5000/api` for development)
- **Authentication**: JWT tokens stored in SharedPreferences and sent with all API requests
- **Security**: Bearer token authentication for all protected endpoints
- **Error Handling**: Comprehensive error handling with user-friendly messages

## Database Schema

The application uses the following database models:

- **User**: Stores information for students, teachers, and administrators
- **Institution**: Educational institutions registered in the system
- **Branch**: Different courses/departments within an institution
- **Semester**: Semesters within each branch
- **Subject**: Subjects taught in each semester
- **ClassSchedule**: Timetable for classes
- **AttendanceRecord**: Records of student attendance

## Key Features

### 🏢 Multi-Institutional Platform
1. **Institution Registration**: Any college can register and get their own system
2. **Data Isolation**: Complete separation of data between institutions
3. **Scalable Architecture**: Supports unlimited institutions and users

### 👨‍💼 Comprehensive Admin Dashboard
1. **Real-time Statistics**: Live dashboard with user, branch, and subject counts
2. **User Management**: Complete CRUD operations for students and teachers
3. **Academic Structure**: Create branches, semesters, and subjects hierarchically
4. **Timetable Management**: Visual schedule creation with teacher assignments
5. **Student Enrollment**: Guided workflow for semester enrollment

### 🔐 Enterprise Security
1. **JWT Authentication**: Secure token-based authentication system
2. **Role-Based Access**: Admin, Teacher, Student permissions
3. **Password Security**: Werkzeug hashed password storage
4. **API Security**: Input validation and error handling

### 🤖 Smart Features
1. **Biometric Attendance**: DeepFace integration for face recognition
2. **AI-Powered Suggestions**: Gemini API for personalized study recommendations
3. **Smart Routines**: Dynamic daily schedules with AI-generated tasks
4. **Cross-Platform**: Flutter app for iOS, Android, and Web

### 📊 Complete Workflow
1. **Institution Setup**: Registration → Admin creation → Academic structure
2. **User Management**: Add teachers and students with role-specific data
3. **Timetable Creation**: Assign teachers to subjects with schedules
4. **Daily Operations**: Attendance recording and student routine management
