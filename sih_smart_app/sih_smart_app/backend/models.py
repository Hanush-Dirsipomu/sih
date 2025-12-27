from flask_sqlalchemy import SQLAlchemy
from datetime import datetime
from werkzeug.security import generate_password_hash, check_password_hash

db = SQLAlchemy()

# Association table for individual student subject enrollment (Supports Open Electives)
student_subjects = db.Table('student_subjects',
    db.Column('student_id', db.Integer, db.ForeignKey('user.id'), primary_key=True),
    db.Column('subject_id', db.Integer, db.ForeignKey('subject.id'), primary_key=True)
)

class Institution(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(150), nullable=False)
    registration_code = db.Column(db.String(50), unique=True, nullable=False)
    address = db.Column(db.Text, nullable=True)
    phone = db.Column(db.String(20), nullable=True)
    email = db.Column(db.String(120), nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relationships
    branches = db.relationship('Branch', backref='institution', lazy=True, cascade='all, delete-orphan')
    users = db.relationship('User', backref='institution', lazy=True)
    batches = db.relationship('Batch', backref='institution', lazy=True)

class Batch(db.Model):
    """Handles the 4-year lifecycle (e.g., 2021-2025)"""
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(50), nullable=False) 
    institution_id = db.Column(db.Integer, db.ForeignKey('institution.id'), nullable=False)
    sections = db.relationship('Section', backref='batch', lazy=True)

class Section(db.Model):
    """Groups students (e.g., CSE-A) for shared timetables"""
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(10), nullable=False) 
    batch_id = db.Column(db.Integer, db.ForeignKey('batch.id'), nullable=False)
    branch_id = db.Column(db.Integer, db.ForeignKey('branch.id'), nullable=False)
    students = db.relationship('User', backref='section', lazy=True)
    schedules = db.relationship('ClassSchedule', backref='section', lazy=True)

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    college_id = db.Column(db.String(50), nullable=False) # Registration Number
    password_hash = db.Column(db.String(255), nullable=False)
    name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(120), nullable=True)
    role = db.Column(db.String(20), nullable=False) # 'admin', 'teacher', 'student'
    is_active = db.Column(db.Boolean, default=True)
    
    institution_id = db.Column(db.Integer, db.ForeignKey('institution.id'), nullable=False)
    branch_id = db.Column(db.Integer, db.ForeignKey('branch.id'), nullable=True)
    section_id = db.Column(db.Integer, db.ForeignKey('section.id'), nullable=True)
    current_semester_id = db.Column(db.Integer, db.ForeignKey('semester.id'), nullable=True)
    
    # Biometric Tracking
    has_face_enrolled = db.Column(db.Boolean, default=False)
    face_samples_count = db.Column(db.Integer, default=0)
    
    # Career & Goals
    weak_subjects = db.Column(db.String(200), nullable=True)
    interests = db.Column(db.String(200), nullable=True)
    career_goal = db.Column(db.String(100), nullable=True)

    # Open Elective Enrollments
    enrolled_subjects = db.relationship('Subject', secondary=student_subjects, backref='enrolled_students')

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)
    
    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

class Branch(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    code = db.Column(db.String(20), nullable=False)
    institution_id = db.Column(db.Integer, db.ForeignKey('institution.id'), nullable=False)
    semesters = db.relationship('Semester', backref='branch', lazy=True, cascade='all, delete-orphan')

class Semester(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    number = db.Column(db.Integer, nullable=False)
    branch_id = db.Column(db.Integer, db.ForeignKey('branch.id'), nullable=False)
    subjects = db.relationship('Subject', backref='semester', lazy=True, cascade='all, delete-orphan')

class Subject(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    code = db.Column(db.String(20), nullable=False)
    semester_id = db.Column(db.Integer, db.ForeignKey('semester.id'), nullable=False)

class ClassSchedule(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    subject_id = db.Column(db.Integer, db.ForeignKey('subject.id'), nullable=False)
    teacher_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    section_id = db.Column(db.Integer, db.ForeignKey('section.id'), nullable=True)
    day_of_week = db.Column(db.Integer, nullable=False)
    start_time = db.Column(db.Time, nullable=False)
    end_time = db.Column(db.Time, nullable=False)
    room = db.Column(db.String(50))

class AttendanceRecord(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    student_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    class_id = db.Column(db.Integer, db.ForeignKey('class_schedule.id'), nullable=False)
    date = db.Column(db.Date, nullable=False, default=datetime.utcnow)
    status = db.Column(db.String(20), nullable=False) # 'present', 'absent'
    timestamp = db.Column(db.DateTime, default=datetime.utcnow)