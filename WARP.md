# WARP.md - Smart Attendance System

This file provides guidance to WARP (warp.dev) when working with the Smart Attendance System codebase.

## Project Overview

This repository contains a **complete Smart Attendance System** developed for the Smart India Hackathon (SIH), featuring real college data integration and production-ready architecture:

1. **Backend**: Flask API with JWT authentication, face recognition, AI integration, and comprehensive admin management
2. **Frontend**: Flutter mobile app with professional UI and complete functionality
3. **Real Data**: Integrated with actual CSE department timetable, faculty, and student data
4. **Project Review Ready**: Clean, professional interface perfect for demonstrations

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
pip install flask flask-sqlalchemy flask-migrate flask-cors
pip install deepface tensorflow PyJWT google-generativeai
pip install werkzeug pillow

# Initialize database with real college data (IMPORTANT!)
python init_college_data.py

# Run server
python app.py
```

**Note**: The `init_college_data.py` script populates your database with:
- CSE Department structure based on the provided timetable
- All teachers from the actual timetable (Dr. B M V Narasimha Raju, etc.)
- Complete Semester 3 subjects and class schedules
- Sample students enrolled and ready for testing

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
# Admin Login (Full Management Access)
curl -X POST http://localhost:5000/api/login \
  -H "Content-Type: application/json" \
  -d '{"college_id": "ADMIN_CSE_001", "password": "admin123"}'

# Teacher Login (Dr. B M V Narasimha Raju)
curl -X POST http://localhost:5000/api/login \
  -H "Content-Type: application/json" \
  -d '{"college_id": "TEA_001", "password": "teacher123"}'

# Student Login
curl -X POST http://localhost:5000/api/login \
  -H "Content-Type: application/json" \
  -d '{"college_id": "21B81A0501", "password": "student123"}'

# Use token for authenticated operations
curl -X GET http://localhost:5000/api/admin/users \
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

## Key Features - Project Review Ready

### 🎓 Real College Data Integration
1. **CSE Department Structure**: Based on actual timetable from your college
2. **Live Faculty Data**: All teachers from the timetable (Dr. B M V Narasimha Raju, Smt. K Divya Bhavani, etc.)
3. **Complete Schedule**: Real Monday-Friday timetable with proper subjects and timings
4. **Production Ready**: Clean, professional interface perfect for project demonstrations

### 👨‍💼 Complete Admin Management
1. **Timetable Creation**: Visual interface to create and manage class schedules
2. **Teacher Assignment**: Assign real faculty to actual subjects with time slots
3. **User Management**: Complete CRUD operations for students and teachers
4. **Academic Structure**: Manage branches, semesters, and subjects hierarchically
5. **Student Enrollment**: Semester-wise enrollment with real data

### 🔐 Enterprise Security & Architecture
1. **JWT Authentication**: Secure token-based authentication system
2. **Role-Based Access**: Admin, Teacher, Student permissions with data isolation
3. **Optimized Performance**: Lazy loading for TensorFlow/DeepFace components
4. **API Security**: Comprehensive input validation and error handling

### 🤖 Smart AI Features
1. **Face Recognition**: DeepFace integration for biometric attendance
2. **AI Study Suggestions**: Context-aware recommendations based on attendance
3. **Smart Daily Routines**: Personalized schedules with real timetable integration
4. **Attendance Predictions**: "Attend next 3 classes to reach 75%" warnings

### 📱 Professional Mobile App
1. **Clean UI/UX**: Modern Flutter interface with consistent theming
2. **Real-time Sync**: Live data updates across all user roles
3. **Responsive Design**: Works perfectly on all screen sizes
4. **Demo Ready**: Professional quality suitable for project reviews
