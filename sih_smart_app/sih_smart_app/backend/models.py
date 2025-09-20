# File: backend/models.py
from flask_sqlalchemy import SQLAlchemy
from datetime import datetime
from werkzeug.security import generate_password_hash, check_password_hash

db = SQLAlchemy()

# Association table for student enrollments in a specific semester
enrollments = db.Table('enrollments',
    db.Column('user_id', db.Integer, db.ForeignKey('user.id'), primary_key=True),
    db.Column('semester_id', db.Integer, db.ForeignKey('semester.id'), primary_key=True)
)

class Institution(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(150), nullable=False)
    address = db.Column(db.Text, nullable=True)
    phone = db.Column(db.String(20), nullable=True)
    email = db.Column(db.String(120), nullable=True)
    registration_code = db.Column(db.String(50), unique=True, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    is_active = db.Column(db.Boolean, default=True)
    
    # Relationships
    branches = db.relationship('Branch', backref='institution', lazy=True, cascade='all, delete-orphan')
    users = db.relationship('User', backref='institution', lazy=True)

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    college_id = db.Column(db.String(50), nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(120), nullable=True)
    phone = db.Column(db.String(20), nullable=True)
    role = db.Column(db.String(20), nullable=False)  # 'admin', 'teacher', 'student'
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    institution_id = db.Column(db.Integer, db.ForeignKey('institution.id'), nullable=False)
    
    # Student-specific fields
    branch_id = db.Column(db.Integer, db.ForeignKey('branch.id'), nullable=True)
    current_semester_id = db.Column(db.Integer, db.ForeignKey('semester.id'), nullable=True)
    weak_subjects = db.Column(db.String(200), nullable=True)
    interests = db.Column(db.String(200), nullable=True)
    career_goal = db.Column(db.String(100), nullable=True)
    
    # Teacher-specific fields  
    department = db.Column(db.String(100), nullable=True)
    designation = db.Column(db.String(100), nullable=True)
    
    def set_password(self, password):
        self.password_hash = generate_password_hash(password)
    
    def check_password(self, password):
        return check_password_hash(self.password_hash, password)
    
    def to_dict(self):
        return {
            'id': self.id,
            'college_id': self.college_id,
            'name': self.name,
            'email': self.email,
            'phone': self.phone,
            'role': self.role,
            'is_active': self.is_active,
            'branch_id': self.branch_id,
            'current_semester_id': self.current_semester_id,
            'department': self.department,
            'designation': self.designation
        }

class Branch(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    code = db.Column(db.String(20), nullable=False)
    description = db.Column(db.Text, nullable=True)
    duration_years = db.Column(db.Integer, default=4)
    institution_id = db.Column(db.Integer, db.ForeignKey('institution.id'), nullable=False)
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relationships
    semesters = db.relationship('Semester', backref='branch', lazy=True, cascade='all, delete-orphan')
    students = db.relationship('User', backref='branch', lazy=True)
    
    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'code': self.code,
            'description': self.description,
            'duration_years': self.duration_years,
            'is_active': self.is_active
        }

class Semester(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    number = db.Column(db.Integer, nullable=False)
    name = db.Column(db.String(100), nullable=True)  # e.g., "Fall 2024", "Spring 2025"
    branch_id = db.Column(db.Integer, db.ForeignKey('branch.id'), nullable=False)
    is_active = db.Column(db.Boolean, default=True)
    
    # Relationships
    subjects = db.relationship('Subject', backref='semester', lazy=True, cascade='all, delete-orphan')
    students = db.relationship('User', secondary=enrollments, backref=db.backref('semesters_enrolled', lazy='dynamic'))
    
    def to_dict(self):
        return {
            'id': self.id,
            'number': self.number,
            'name': self.name,
            'branch_id': self.branch_id,
            'is_active': self.is_active
        }

class Subject(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    code = db.Column(db.String(20), nullable=False)
    description = db.Column(db.Text, nullable=True)
    credits = db.Column(db.Integer, default=3)
    semester_id = db.Column(db.Integer, db.ForeignKey('semester.id'), nullable=False)
    is_active = db.Column(db.Boolean, default=True)
    
    # Relationships
    classes = db.relationship('ClassSchedule', backref='subject', lazy=True, cascade='all, delete-orphan')
    
    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'code': self.code,
            'description': self.description,
            'credits': self.credits,
            'semester_id': self.semester_id,
            'is_active': self.is_active
        }

class ClassSchedule(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    subject_id = db.Column(db.Integer, db.ForeignKey('subject.id'), nullable=False)
    teacher_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    room = db.Column(db.String(50), nullable=True)
    day_of_week = db.Column(db.Integer, nullable=False)  # 0=Monday, 6=Sunday
    start_time = db.Column(db.Time, nullable=False)
    end_time = db.Column(db.Time, nullable=False)
    is_active = db.Column(db.Boolean, default=True)
    
    # Relationships
    teacher = db.relationship('User', backref='classes_teaching')
    attendance_records = db.relationship('AttendanceRecord', backref='class_schedule', cascade='all, delete-orphan')
    
    def to_dict(self):
        return {
            'id': self.id,
            'subject_id': self.subject_id,
            'teacher_id': self.teacher_id,
            'room': self.room,
            'day_of_week': self.day_of_week,
            'start_time': self.start_time.strftime('%H:%M'),
            'end_time': self.end_time.strftime('%H:%M'),
            'is_active': self.is_active
        }

class AttendanceRecord(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    student_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    class_id = db.Column(db.Integer, db.ForeignKey('class_schedule.id'), nullable=False)
    date = db.Column(db.Date, nullable=False, default=datetime.utcnow)
    status = db.Column(db.String(20), nullable=False)  # 'present', 'absent', 'late'
    timestamp = db.Column(db.DateTime, default=datetime.utcnow)
    marked_by = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=True)  # Teacher who marked
    
    # Relationships
    student = db.relationship('User', foreign_keys=[student_id], backref='attendance_records')
    marker = db.relationship('User', foreign_keys=[marked_by])
    
    def to_dict(self):
        return {
            'id': self.id,
            'student_id': self.student_id,
            'class_id': self.class_id,
            'date': self.date.isoformat(),
            'status': self.status,
            'timestamp': self.timestamp.isoformat()
        }
