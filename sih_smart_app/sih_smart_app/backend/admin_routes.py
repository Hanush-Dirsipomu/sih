# File: backend/admin_routes.py
from flask import Blueprint, request, jsonify
from models import db, User, Institution, Branch, Semester, Subject, ClassSchedule
from auth import admin_required, jwt_required, get_user_institution_id, AuthManager
from datetime import datetime, time
import uuid

admin_bp = Blueprint('admin', __name__)

def get_current_user_institution():
    """Get current user's institution ID from JWT token"""
    institution_id = get_user_institution_id()
    if not institution_id:
        return None, jsonify({'error': 'Institution access required'}), 403
    return institution_id, None, None

# INSTITUTION MANAGEMENT
@admin_bp.route('/institutions', methods=['POST'])
def register_institution():
    """Register a new institution with admin user"""
    try:
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['name', 'admin_name', 'admin_email', 'admin_password']
        if not all(field in data for field in required_fields):
            return jsonify({'error': 'Missing required fields'}), 400
        
        # Generate unique registration code
        registration_code = f"INST_{str(uuid.uuid4())[:8].upper()}"
        
        # Create institution
        institution = Institution(
            name=data['name'],
            address=data.get('address'),
            phone=data.get('phone'),
            email=data.get('email'),
            registration_code=registration_code
        )
        db.session.add(institution)
        db.session.flush()
        
        # Create admin user
        admin = User(
            college_id=f"ADMIN_{registration_code}",
            name=data['admin_name'],
            email=data['admin_email'],
            role='admin',
            institution_id=institution.id
        )
        admin.set_password(data['admin_password'])
        db.session.add(admin)
        db.session.commit()
        
        return jsonify({
            'message': 'Institution registered successfully',
            'institution_id': institution.id,
            'registration_code': registration_code,
            'admin_id': admin.id
        }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

# USER MANAGEMENT
@admin_bp.route('/users', methods=['GET'])
@admin_required
def get_users():
    """Get all users in the institution"""
    institution_id, error_response, status_code = get_current_user_institution()
    if error_response:
        return error_response, status_code
    
    role_filter = request.args.get('role')
    query = User.query.filter_by(institution_id=institution_id)
    
    if role_filter:
        query = query.filter_by(role=role_filter)
    
    users = query.all()
    return jsonify([user.to_dict() for user in users])

@admin_bp.route('/users', methods=['POST'])
@admin_required
def create_user():
    """Create a new user (student/teacher)"""
    institution_id, error_response, status_code = get_current_user_institution()
    if error_response:
        return error_response, status_code
    
    try:
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['name', 'college_id', 'password', 'role']
        if not all(field in data for field in required_fields):
            return jsonify({'error': 'Missing required fields'}), 400
        
        if data['role'] not in ['student', 'teacher']:
            return jsonify({'error': 'Invalid role'}), 400
        
        # Check if college_id already exists in this institution
        existing_user = User.query.filter_by(
            college_id=data['college_id'],
            institution_id=institution_id
        ).first()
        if existing_user:
            return jsonify({'error': 'College ID already exists'}), 400
        
        user = User(
            college_id=data['college_id'],
            name=data['name'],
            email=data.get('email'),
            phone=data.get('phone'),
            role=data['role'],
            institution_id=institution_id,
            department=data.get('department'),
            designation=data.get('designation')
        )
        user.set_password(data['password'])
        db.session.add(user)
        db.session.commit()
        
        return jsonify({
            'message': 'User created successfully',
            'user': user.to_dict()
        }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@admin_bp.route('/users/<int:user_id>', methods=['PUT'])
@admin_required
def update_user(user_id):
    """Update user details"""
    institution_id, error_response, status_code = get_current_user_institution()
    if error_response:
        return error_response, status_code
    
    try:
        user = User.query.filter_by(id=user_id, institution_id=institution_id).first()
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        data = request.get_json()
        
        # Update fields
        updatable_fields = ['name', 'email', 'phone', 'department', 'designation', 'is_active']
        for field in updatable_fields:
            if field in data:
                setattr(user, field, data[field])
        
        if 'password' in data and data['password']:
            user.set_password(data['password'])
        
        db.session.commit()
        return jsonify({'message': 'User updated successfully', 'user': user.to_dict()})
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@admin_bp.route('/users/<int:user_id>', methods=['DELETE'])
@admin_required
def delete_user(user_id):
    """Delete/deactivate user"""
    institution_id, error_response, status_code = get_current_user_institution()
    if error_response:
        return error_response, status_code
    
    try:
        user = User.query.filter_by(id=user_id, institution_id=institution_id).first()
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        if user.role == 'admin':
            return jsonify({'error': 'Cannot delete admin user'}), 403
        
        # Soft delete by deactivating
        user.is_active = False
        db.session.commit()
        
        return jsonify({'message': 'User deactivated successfully'})
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

# BRANCH MANAGEMENT
@admin_bp.route('/branches', methods=['GET'])
@admin_required
def get_branches():
    """Get all branches in the institution"""
    institution_id, error_response, status_code = get_current_user_institution()
    if error_response:
        return error_response, status_code
    
    branches = Branch.query.filter_by(institution_id=institution_id).all()
    return jsonify([branch.to_dict() for branch in branches])

@admin_bp.route('/branches', methods=['POST'])
@admin_required
def create_branch():
    """Create a new branch"""
    institution_id, error_response, status_code = get_current_user_institution()
    if error_response:
        return error_response, status_code
    
    try:
        data = request.get_json()
        
        required_fields = ['name', 'code']
        if not all(field in data for field in required_fields):
            return jsonify({'error': 'Missing required fields'}), 400
        
        branch = Branch(
            name=data['name'],
            code=data['code'],
            description=data.get('description'),
            duration_years=data.get('duration_years', 4),
            institution_id=institution_id
        )
        db.session.add(branch)
        db.session.commit()
        
        return jsonify({
            'message': 'Branch created successfully',
            'branch': branch.to_dict()
        }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@admin_bp.route('/branches/<int:branch_id>', methods=['PUT'])
@admin_required
def update_branch(branch_id):
    """Update branch details"""
    institution_id, error_response, status_code = get_current_user_institution()
    if error_response:
        return error_response, status_code
    
    try:
        branch = Branch.query.filter_by(id=branch_id, institution_id=institution_id).first()
        if not branch:
            return jsonify({'error': 'Branch not found'}), 404
        
        data = request.get_json()
        updatable_fields = ['name', 'code', 'description', 'duration_years', 'is_active']
        
        for field in updatable_fields:
            if field in data:
                setattr(branch, field, data[field])
        
        db.session.commit()
        return jsonify({'message': 'Branch updated successfully', 'branch': branch.to_dict()})
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

# SEMESTER MANAGEMENT
@admin_bp.route('/branches/<int:branch_id>/semesters', methods=['GET'])
@admin_required
def get_semesters(branch_id):
    """Get all semesters for a branch"""
    institution_id, error_response, status_code = get_current_user_institution()
    if error_response:
        return error_response, status_code
    
    # Verify branch belongs to institution
    branch = Branch.query.filter_by(id=branch_id, institution_id=institution_id).first()
    if not branch:
        return jsonify({'error': 'Branch not found'}), 404
    
    semesters = Semester.query.filter_by(branch_id=branch_id).all()
    return jsonify([semester.to_dict() for semester in semesters])

@admin_bp.route('/branches/<int:branch_id>/semesters', methods=['POST'])
@admin_required
def create_semester(branch_id):
    """Create a new semester for a branch"""
    institution_id, error_response, status_code = get_current_user_institution()
    if error_response:
        return error_response, status_code
    
    try:
        # Verify branch belongs to institution
        branch = Branch.query.filter_by(id=branch_id, institution_id=institution_id).first()
        if not branch:
            return jsonify({'error': 'Branch not found'}), 404
        
        data = request.get_json()
        
        if 'number' not in data:
            return jsonify({'error': 'Semester number is required'}), 400
        
        semester = Semester(
            number=data['number'],
            name=data.get('name'),
            branch_id=branch_id
        )
        db.session.add(semester)
        db.session.commit()
        
        return jsonify({
            'message': 'Semester created successfully',
            'semester': semester.to_dict()
        }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

# SUBJECT MANAGEMENT
@admin_bp.route('/semesters/<int:semester_id>/subjects', methods=['GET'])
@admin_required
def get_subjects(semester_id):
    """Get all subjects for a semester"""
    institution_id, error_response, status_code = get_current_user_institution()
    if error_response:
        return error_response, status_code
    
    # Verify semester belongs to institution
    semester = Semester.query.join(Branch).filter(
        Semester.id == semester_id,
        Branch.institution_id == institution_id
    ).first()
    
    if not semester:
        return jsonify({'error': 'Semester not found'}), 404
    
    subjects = Subject.query.filter_by(semester_id=semester_id).all()
    return jsonify([subject.to_dict() for subject in subjects])

@admin_bp.route('/semesters/<int:semester_id>/subjects', methods=['POST'])
@admin_required
def create_subject(semester_id):
    """Create a new subject for a semester"""
    institution_id, error_response, status_code = get_current_user_institution()
    if error_response:
        return error_response, status_code
    
    try:
        # Verify semester belongs to institution
        semester = Semester.query.join(Branch).filter(
            Semester.id == semester_id,
            Branch.institution_id == institution_id
        ).first()
        
        if not semester:
            return jsonify({'error': 'Semester not found'}), 404
        
        data = request.get_json()
        required_fields = ['name', 'code']
        
        if not all(field in data for field in required_fields):
            return jsonify({'error': 'Missing required fields'}), 400
        
        subject = Subject(
            name=data['name'],
            code=data['code'],
            description=data.get('description'),
            credits=data.get('credits', 3),
            semester_id=semester_id
        )
        db.session.add(subject)
        db.session.commit()
        
        return jsonify({
            'message': 'Subject created successfully',
            'subject': subject.to_dict()
        }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

# TIMETABLE/CLASS SCHEDULE MANAGEMENT
@admin_bp.route('/subjects/<int:subject_id>/schedule', methods=['GET'])
@admin_required
def get_class_schedule(subject_id):
    """Get class schedules for a subject"""
    institution_id, error_response, status_code = get_current_user_institution()
    if error_response:
        return error_response, status_code
    
    # Verify subject belongs to institution
    subject = Subject.query.join(Semester).join(Branch).filter(
        Subject.id == subject_id,
        Branch.institution_id == institution_id
    ).first()
    
    if not subject:
        return jsonify({'error': 'Subject not found'}), 404
    
    schedules = ClassSchedule.query.filter_by(subject_id=subject_id).all()
    schedule_data = []
    
    for schedule in schedules:
        schedule_dict = schedule.to_dict()
        schedule_dict['teacher_name'] = schedule.teacher.name if schedule.teacher else None
        schedule_dict['subject_name'] = schedule.subject.name
        schedule_data.append(schedule_dict)
    
    return jsonify(schedule_data)

@admin_bp.route('/subjects/<int:subject_id>/schedule', methods=['POST'])
@admin_required
def create_class_schedule(subject_id):
    """Create a new class schedule"""
    institution_id, error_response, status_code = get_current_user_institution()
    if error_response:
        return error_response, status_code
    
    try:
        # Verify subject belongs to institution
        subject = Subject.query.join(Semester).join(Branch).filter(
            Subject.id == subject_id,
            Branch.institution_id == institution_id
        ).first()
        
        if not subject:
            return jsonify({'error': 'Subject not found'}), 404
        
        data = request.get_json()
        required_fields = ['teacher_id', 'day_of_week', 'start_time', 'end_time']
        
        if not all(field in data for field in required_fields):
            return jsonify({'error': 'Missing required fields'}), 400
        
        # Verify teacher belongs to institution
        teacher = User.query.filter_by(
            id=data['teacher_id'],
            institution_id=institution_id,
            role='teacher'
        ).first()
        
        if not teacher:
            return jsonify({'error': 'Teacher not found'}), 404
        
        # Parse time strings
        start_time = datetime.strptime(data['start_time'], '%H:%M').time()
        end_time = datetime.strptime(data['end_time'], '%H:%M').time()
        
        schedule = ClassSchedule(
            subject_id=subject_id,
            teacher_id=data['teacher_id'],
            room=data.get('room'),
            day_of_week=data['day_of_week'],
            start_time=start_time,
            end_time=end_time
        )
        db.session.add(schedule)
        db.session.commit()
        
        return jsonify({
            'message': 'Class schedule created successfully',
            'schedule': schedule.to_dict()
        }), 201
        
    except ValueError:
        return jsonify({'error': 'Invalid time format. Use HH:MM'}), 400
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

# STUDENT ENROLLMENT
@admin_bp.route('/students/<int:student_id>/enroll', methods=['POST'])
@admin_required
def enroll_student(student_id):
    """Enroll a student in a semester"""
    institution_id, error_response, status_code = get_current_user_institution()
    if error_response:
        return error_response, status_code
    
    try:
        # Verify student belongs to institution
        student = User.query.filter_by(
            id=student_id,
            institution_id=institution_id,
            role='student'
        ).first()
        
        if not student:
            return jsonify({'error': 'Student not found'}), 404
        
        data = request.get_json()
        
        if 'semester_id' not in data:
            return jsonify({'error': 'Semester ID is required'}), 400
        
        # Verify semester belongs to institution
        semester = Semester.query.join(Branch).filter(
            Semester.id == data['semester_id'],
            Branch.institution_id == institution_id
        ).first()
        
        if not semester:
            return jsonify({'error': 'Semester not found'}), 404
        
        # Update student's branch and semester
        student.branch_id = semester.branch_id
        student.current_semester_id = data['semester_id']
        
        # Add to semester enrollment
        if semester not in student.semesters_enrolled:
            student.semesters_enrolled.append(semester)
        
        db.session.commit()
        
        return jsonify({'message': 'Student enrolled successfully'})
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

# DASHBOARD STATS
@admin_bp.route('/dashboard/stats', methods=['GET'])
@admin_required
def get_dashboard_stats():
    """Get dashboard statistics for the institution"""
    institution_id, error_response, status_code = get_current_user_institution()
    if error_response:
        return error_response, status_code
    
    try:
        stats = {
            'total_students': User.query.filter_by(
                institution_id=institution_id, 
                role='student', 
                is_active=True
            ).count(),
            'total_teachers': User.query.filter_by(
                institution_id=institution_id, 
                role='teacher', 
                is_active=True
            ).count(),
            'total_branches': Branch.query.filter_by(
                institution_id=institution_id, 
                is_active=True
            ).count(),
            'total_subjects': Subject.query.join(Semester).join(Branch).filter(
                Branch.institution_id == institution_id,
                Subject.is_active == True
            ).count()
        }
        
        return jsonify(stats)
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500