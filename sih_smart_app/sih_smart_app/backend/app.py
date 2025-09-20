# File: backend/app.py
import os
import traceback
from flask import Flask, jsonify, request
from flask_cors import CORS
from flask_migrate import Migrate
from werkzeug.utils import secure_filename
from config import Config
from models import db, User, Institution, Branch, Semester, Subject, ClassSchedule, AttendanceRecord
from admin_routes import admin_bp
from auth import AuthManager, jwt_required
from datetime import time, datetime, date

# Import TensorFlow/DeepFace only when needed (lazy loading)
DeepFace = None
genai = None

def load_deepface():
    global DeepFace
    if DeepFace is None:
        from deepface import DeepFace as df
        DeepFace = df
    return DeepFace

def load_genai():
    global genai
    if genai is None:
        import google.generativeai as genai_module
        genai = genai_module
    return genai

UPLOAD_FOLDER = 'uploads'
KNOWN_FACES_DIR = 'known_faces'
for folder in [UPLOAD_FOLDER, KNOWN_FACES_DIR]:
    if not os.path.exists(folder):
        os.makedirs(folder)

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)
    app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
    db.init_app(app)
    Migrate(app, db)
    CORS(app)
    
    # Register admin blueprint
    app.register_blueprint(admin_bp, url_prefix='/api/admin')

    def call_generative_ai(prompt):
        GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
        if not GEMINI_API_KEY:
            # Return intelligent fallback suggestions based on prompt context
            if "weak" in prompt.lower() and "subjects" in prompt.lower():
                return "1. Focus on reviewing your weakest subjects during free periods. 2. Practice problem-solving in challenging topics."
            elif "career" in prompt.lower():
                return "1. Research industry trends related to your career goal. 2. Build relevant skills through online courses."
            else:
                return "1. Review today's class notes and prepare for upcoming sessions. 2. Work on assignments and projects."
        
        try:
            genai_module = load_genai()
            genai_module.configure(api_key=GEMINI_API_KEY)
            model = genai_module.GenerativeModel('gemini-1.5-flash-latest')
            response = model.generate_content(prompt)
            return response.text.replace('*', '').replace('#', '')
        except Exception as e:
            print(f"Error calling Gemini API: {e}")
            # Fallback to context-aware suggestions
            if "attendance" in prompt.lower():
                return "1. Attend all remaining classes to improve your percentage. 2. Meet with your teacher to discuss missed topics."
            else:
                return "1. Use this free time for focused study. 2. Prepare for upcoming assessments."

    # --- ROUTES ---
    # Note: Institution registration is now handled in admin_routes.py
    # This route is kept for backward compatibility
    @app.route('/api/register_institution', methods=['POST'])
    def register_institution_legacy():
        """Legacy institution registration endpoint - redirects to new admin endpoint"""
        data = request.get_json()
        
        # Transform data to match new format
        transformed_data = {
            'name': data.get('institution_name'),
            'admin_name': data.get('admin_name'),
            'admin_email': data.get('admin_email', ''),
            'admin_password': data.get('password'),
            'address': data.get('address'),
            'phone': data.get('phone'),
            'email': data.get('email')
        }
        
        # Call the new admin route function directly
        from admin_routes import register_institution
        return register_institution()

    @app.route('/api/login', methods=['POST'])
    def login():
        data = request.get_json()
        
        # Find user by college_id (can be from any institution)
        user = User.query.filter_by(college_id=data.get('college_id')).first()
        
        if user and user.check_password(data.get('password')):
            if not user.is_active:
                return jsonify({"message": "Account is deactivated"}), 401
            
            # Generate JWT token
            token = AuthManager.generate_token(
                user.id, 
                user.role, 
                user.institution_id
            )
            
            response = {
                "message": f"Welcome {user.name}!", 
                "role": user.role, 
                "user_id": user.id,
                "institution_id": user.institution_id,
                "institution_name": user.institution.name,
                "token": token
            }
            
            if user.role == 'student':
                response['profile_completed'] = bool(user.career_goal)
                response['branch_id'] = user.branch_id
                response['semester_id'] = user.current_semester_id
            elif user.role == 'teacher':
                response['department'] = user.department
                response['designation'] = user.designation
                
            return jsonify(response), 200
            
        return jsonify({"message": "Invalid credentials"}), 401
    
    @app.route('/api/student/<int:user_id>/profile', methods=['POST'])
    @jwt_required(roles=['student', 'admin'])
    def update_student_profile(user_id):
        user = User.query.get(user_id)
        if not user: return jsonify({"message": "Student not found"}), 404
        data = request.get_json()
        user.career_goal = data.get('career_goal')
        user.interests = data.get('interests')
        user.weak_subjects = data.get('weak_subjects')
        db.session.commit()
        return jsonify({"message": "Profile updated successfully!"}), 200

    @app.route('/api/student/<int:user_id>/smart_routine', methods=['GET'])
    @jwt_required(roles=['student', 'admin', 'teacher'])
    def get_smart_routine(user_id):
        user = User.query.get(user_id)
        if not user: return jsonify({"message": "User not found"}), 404
        today = date.today()
        current_time = datetime.now().time()
        
        # Get today's classes
        student_classes = ClassSchedule.query.join(Subject).join(Semester).filter(
            Semester.id == user.current_semester_id,
            ClassSchedule.day_of_week == today.weekday()
        ).order_by(ClassSchedule.start_time).all()
        
        # Calculate attendance summary for context
        subjects = Subject.query.filter_by(semester_id=user.current_semester_id).all()
        low_attendance_subjects = []
        attendance_context = ""
        
        for subject in subjects:
            class_schedules = ClassSchedule.query.filter_by(subject_id=subject.id).all()
            total_classes = 0
            attended_classes = 0
            
            for class_schedule in class_schedules:
                total_records = AttendanceRecord.query.filter_by(
                    class_id=class_schedule.id,
                    student_id=user_id
                ).count()
                
                present_records = AttendanceRecord.query.filter_by(
                    class_id=class_schedule.id,
                    student_id=user_id,
                    status='present'
                ).count()
                
                total_classes += total_records
                attended_classes += present_records
            
            if total_classes > 0:
                percentage = (attended_classes / total_classes * 100)
                if percentage < 75:
                    low_attendance_subjects.append(f"{subject.name} ({percentage:.1f}%)")
        
        if low_attendance_subjects:
            attendance_context = f" URGENT: Your attendance is below 75% in: {', '.join(low_attendance_subjects)}. You need to attend remaining classes and catch up on missed topics."
        
        # Build routine with classes
        routine = []
        alerts = []
        
        for class_item in student_classes:
            class_entry = {
                "time": class_item.start_time,
                "title": class_item.subject.name,
                "type": "class",
                "details": f"Room: {class_item.room or 'TBA'}",
                "subject_code": class_item.subject.code
            }
            routine.append(class_entry)
            
            # Check if class is starting soon (within 15 minutes)
            time_diff = datetime.combine(today, class_item.start_time) - datetime.combine(today, current_time)
            if 0 <= time_diff.total_seconds() <= 900:  # 15 minutes
                alerts.append({
                    "type": "class_reminder",
                    "message": f"Your {class_item.subject.name} class starts in {int(time_diff.total_seconds()/60)} minutes at {class_item.room or 'TBA'}!",
                    "urgency": "high"
                })
        
        # Enhanced AI prompt with attendance context
        prompt = (f"You are an AI academic advisor. Student profile: Goal='{user.career_goal}', "
                  f"Weak subjects='{user.weak_subjects}', Interests='{user.interests}'.{attendance_context} "
                  f"It's {today.strftime('%A')} and they have {len(student_classes)} classes today. "
                  f"Suggest 3 specific, actionable tasks for free periods that align with their goals and address attendance issues. "
                  f"Format as numbered list: 1. Task description. 2. Task description. 3. Task description.")
        
        ai_suggestions = call_generative_ai(prompt)
        ai_tasks = [task.strip() for task in ai_suggestions.split('\n') if task and len(task) > 2 and task[0].isdigit()]

        # Find free slots
        class_times = []
        for c in student_classes:
            class_times.extend([c.start_time, c.end_time])
        class_times.sort()
        
        # Generate free slots between 9 AM and 6 PM
        potential_slots = [time(h, 0) for h in range(9, 18)]
        free_slots = []
        
        for slot in potential_slots:
            is_free = True
            for i in range(0, len(class_times), 2):
                if i+1 < len(class_times):
                    start_time = class_times[i]
                    end_time = class_times[i+1]
                    if start_time <= slot <= end_time:
                        is_free = False
                        break
            if is_free:
                free_slots.append(slot)
        
        # Add AI tasks to free slots
        for i, task_title in enumerate(ai_tasks[:len(free_slots)]):
            clean_title = '. '.join(task_title.split('. ')[1:]) if '. ' in task_title else task_title
            routine.append({
                "time": free_slots[i],
                "title": clean_title,
                "type": "task",
                "priority": "high" if "attendance" in task_title.lower() else "medium"
            })

        # Sort routine by time
        routine.sort(key=lambda x: x['time'])
        
        # Format times for display
        formatted_routine = []
        for item in routine:
            formatted_item = {
                "time": item['time'].strftime("%I:%M %p"),
                "title": item['title'],
                "type": item['type']
            }
            if 'details' in item:
                formatted_item['details'] = item['details']
            if 'subject_code' in item:
                formatted_item['subject_code'] = item['subject_code']
            if 'priority' in item:
                formatted_item['priority'] = item['priority']
            formatted_routine.append(formatted_item)
        
        branch = Branch.query.get(user.branch_id)
        semester = Semester.query.get(user.current_semester_id)
        
        return jsonify({
            "branch": branch.name if branch else "N/A",
            "semester": f"Semester {semester.number}" if semester else "N/A",
            "routine": formatted_routine,
            "alerts": alerts,
            "low_attendance_subjects": low_attendance_subjects
        })
    
    @app.route('/api/teacher/<int:teacher_id>/timetable/today', methods=['GET'])
    @jwt_required(roles=['teacher', 'admin'])
    def get_teacher_timetable_today(teacher_id):
        today = date.today()
        todays_classes = ClassSchedule.query.filter_by(teacher_id=teacher_id, day_of_week=today.weekday()).order_by(ClassSchedule.start_time).all()
        classes_list = []
        for class_item in todays_classes:
            attendance_taken = AttendanceRecord.query.filter_by(class_id=class_item.id, date=today).first() is not None
            classes_list.append({
                "id": class_item.id, "title": class_item.subject.name, "course_code": class_item.subject.code,
                "room": class_item.room, "start_time": class_item.start_time.strftime("%I:%M %p"),
                "end_time": class_item.end_time.strftime("%I:%M %p"), "attendance_taken": attendance_taken
            })
        return jsonify(classes_list)

    @app.route('/api/class/<int:class_id>/roster', methods=['GET'])
    @jwt_required(roles=['teacher', 'admin'])
    def get_class_roster(class_id):
        class_schedule = ClassSchedule.query.get(class_id)
        if not class_schedule: return jsonify({"message": "Class not found"}), 404
        students = class_schedule.subject.semester.students
        student_list = [{"id": s.id, "name": s.name, "college_id": s.college_id} for s in students]
        return jsonify(student_list)

    @app.route('/api/class/<int:class_id>/attendance', methods=['GET'])
    @jwt_required(roles=['teacher', 'admin'])
    def get_attendance_record(class_id):
        today = date.today()
        records = AttendanceRecord.query.filter_by(class_id=class_id, date=today).all()
        if not records: return jsonify([]), 200
        attendance_list = [{"student_name": r.student.name, "college_id": r.student.college_id, "status": r.status} for r in records]
        return jsonify(attendance_list)

    @app.route('/api/mark_attendance', methods=['POST'])
    @jwt_required(roles=['teacher', 'admin'])
    def mark_attendance():
        if 'attendance_photo' not in request.files: return jsonify({"message": "No photo sent"}), 400
        file = request.files['attendance_photo']
        if file.filename == '': return jsonify({"message": "No selected file"}), 400
        filename = secure_filename(file.filename)
        filepath = os.path.join(UPLOAD_FOLDER, filename)
        file.save(filepath)
        try:
            deepface = load_deepface()
            dfs = deepface.find(img_path=filepath, db_path=KNOWN_FACES_DIR, enforce_detection=False)
            present_students = set()
            for df in dfs:
                if not df.empty:
                    best_match_path = df.iloc[0].identity
                    name = os.path.splitext(os.path.basename(best_match_path))[0]
                    present_students.add(name)
            return jsonify({"message": "Faces recognized!", "present": list(present_students)}), 200
        except Exception as e:
            return jsonify({"message": f"Error during recognition: {e}"}), 500

    @app.route('/api/save_attendance', methods=['POST'])
    @jwt_required(roles=['teacher', 'admin'])
    def save_attendance():
        data = request.get_json()
        class_id, attendance_data = data.get('class_id'), data.get('attendance')
        if not class_id or not attendance_data: return jsonify({"message": "Missing data"}), 400
        try:
            today = date.today()
            for student_name, is_present in attendance_data.items():
                student = User.query.filter_by(name=student_name).first()
                if not student: continue
                record = AttendanceRecord.query.filter_by(student_id=student.id, class_id=class_id, date=today).first()
                status = "present" if is_present else "absent"
                if record:
                    record.status, record.timestamp = status, datetime.utcnow()
                else:
                    db.session.add(AttendanceRecord(student_id=student.id, class_id=class_id, status=status, date=today))
            db.session.commit()
            return jsonify({"message": "Attendance saved!"}), 200
        except Exception as e:
            db.session.rollback()
            return jsonify({"message": f"An error occurred: {e}"}), 500

    @app.route('/api/student/<int:user_id>/attendance/summary', methods=['GET'])
    @jwt_required(roles=['student', 'admin', 'teacher'])
    def get_student_attendance_summary(user_id):
        user = User.query.get(user_id)
        if not user: return jsonify({"message": "Student not found"}), 404
        
        # Get all subjects for the student's current semester
        subjects = Subject.query.filter_by(semester_id=user.current_semester_id).all()
        summary = []
        
        for subject in subjects:
            # Get all class schedules for this subject
            class_schedules = ClassSchedule.query.filter_by(subject_id=subject.id).all()
            total_classes = 0
            attended_classes = 0
            
            for class_schedule in class_schedules:
                # Count total attendance records for this class
                total_records = AttendanceRecord.query.filter_by(
                    class_id=class_schedule.id,
                    student_id=user_id
                ).count()
                
                present_records = AttendanceRecord.query.filter_by(
                    class_id=class_schedule.id,
                    student_id=user_id,
                    status='present'
                ).count()
                
                total_classes += total_records
                attended_classes += present_records
            
            percentage = (attended_classes / total_classes * 100) if total_classes > 0 else 0
            classes_needed_75 = max(0, int((total_classes * 0.75) - attended_classes))
            is_below_threshold = percentage < 75
            
            summary.append({
                'subject_id': subject.id,
                'subject_name': subject.name,
                'subject_code': subject.code,
                'total_classes': total_classes,
                'attended_classes': attended_classes,
                'attendance_percentage': round(percentage, 1),
                'is_below_threshold': is_below_threshold,
                'classes_needed_for_75': classes_needed_75,
                'status': 'critical' if percentage < 65 else 'warning' if percentage < 75 else 'good'
            })
        
        overall_total = sum(s['total_classes'] for s in summary)
        overall_attended = sum(s['attended_classes'] for s in summary)
        overall_percentage = (overall_attended / overall_total * 100) if overall_total > 0 else 0
        
        return jsonify({
            'subjects': summary,
            'overall_attendance': {
                'total_classes': overall_total,
                'attended_classes': overall_attended,
                'percentage': round(overall_percentage, 1),
                'is_below_threshold': overall_percentage < 75
            }
        })
    
    @app.route('/api/teacher/<int:teacher_id>/semester/overview', methods=['GET'])
    @jwt_required(roles=['teacher', 'admin'])
    def get_teacher_semester_overview(teacher_id):
        # Get all subjects taught by this teacher
        class_schedules = ClassSchedule.query.filter_by(teacher_id=teacher_id).all()
        subject_summaries = []
        
        for schedule in class_schedules:
            subject = schedule.subject
            
            # Get all students enrolled in this subject's semester
            students = subject.semester.students
            student_attendance = []
            
            for student in students:
                total_classes = AttendanceRecord.query.filter_by(
                    class_id=schedule.id,
                    student_id=student.id
                ).count()
                
                attended_classes = AttendanceRecord.query.filter_by(
                    class_id=schedule.id,
                    student_id=student.id,
                    status='present'
                ).count()
                
                percentage = (attended_classes / total_classes * 100) if total_classes > 0 else 0
                
                student_attendance.append({
                    'student_id': student.id,
                    'student_name': student.name,
                    'college_id': student.college_id,
                    'total_classes': total_classes,
                    'attended_classes': attended_classes,
                    'percentage': round(percentage, 1)
                })
            
            # Calculate class averages
            total_students = len(student_attendance)
            avg_attendance = sum(s['percentage'] for s in student_attendance) / total_students if total_students > 0 else 0
            
            subject_summaries.append({
                'subject_id': subject.id,
                'subject_name': subject.name,
                'subject_code': subject.code,
                'class_schedule_id': schedule.id,
                'room': schedule.room,
                'day_of_week': schedule.day_of_week,
                'start_time': schedule.start_time.strftime('%H:%M'),
                'end_time': schedule.end_time.strftime('%H:%M'),
                'total_students': total_students,
                'average_attendance': round(avg_attendance, 1),
                'students': student_attendance
            })
        
        return jsonify({'subjects': subject_summaries})
    
    @app.route('/api/class/<int:class_id>/attendance/history', methods=['GET'])
    @jwt_required(roles=['teacher', 'admin'])
    def get_class_attendance_history(class_id):
        # Get attendance records grouped by date
        from sqlalchemy import func
        
        records_by_date = db.session.query(
            AttendanceRecord.date,
            func.count(AttendanceRecord.id).label('total'),
            func.sum(func.case([(AttendanceRecord.status == 'present', 1)], else_=0)).label('present')
        ).filter(
            AttendanceRecord.class_id == class_id
        ).group_by(AttendanceRecord.date).all()
        
        history = []
        for record in records_by_date:
            # Get detailed attendance for this date
            daily_records = AttendanceRecord.query.filter_by(
                class_id=class_id,
                date=record.date
            ).all()
            
            students = []
            for attendance in daily_records:
                students.append({
                    'student_id': attendance.student_id,
                    'student_name': attendance.student.name,
                    'college_id': attendance.student.college_id,
                    'status': attendance.status,
                    'timestamp': attendance.timestamp.isoformat()
                })
            
            history.append({
                'date': record.date.isoformat(),
                'total_students': int(record.total),
                'present_count': int(record.present or 0),
                'absent_count': int(record.total) - int(record.present or 0),
                'attendance_percentage': round((int(record.present or 0) / int(record.total) * 100), 1) if record.total > 0 else 0,
                'students': students
            })
        
        # Sort by date (most recent first)
        history.sort(key=lambda x: x['date'], reverse=True)
        
        return jsonify({'history': history})

    return app

app = create_app()

with app.app_context():
    db.create_all()
    if not User.query.first():
        print("Database is empty, creating complete dummy data...")
        try:
            # Create demo institution with unique registration code
            import uuid
            registration_code = f"DEMO_{str(uuid.uuid4())[:8].upper()}"
            
            inst = Institution(
                name="SRKR Engineering College", 
                address="123 College Street, City",
                phone="+1234567890",
                email="admin@srkr.edu",
                registration_code=registration_code
            )
            db.session.add(inst)
            db.session.commit()
            
            # Create Computer Science branch
            cs_branch = Branch(
                name="Computer Science", 
                code="CSE",
                description="Computer Science and Engineering Department",
                duration_years=4,
                institution_id=inst.id
            )
            db.session.add(cs_branch)
            db.session.commit()

            # Create users with hashed passwords
            admin = User(
                college_id='admin', 
                name='SIH Admin', 
                email='admin@srkr.edu',
                role='admin', 
                institution_id=inst.id
            )
            admin.set_password('password')
            
            teacher = User(
                college_id='teacher1', 
                name='Dr. Smith', 
                email='smith@srkr.edu',
                role='teacher', 
                department='Computer Science',
                designation='Professor',
                institution_id=inst.id
            )
            teacher.set_password('password')
            
            student = User(
                college_id='S001', 
                name='Test Student', 
                email='student@srkr.edu',
                role='student', 
                institution_id=inst.id, 
                branch_id=cs_branch.id
            )
            student.set_password('password')
            
            db.session.add_all([admin, teacher, student])
            db.session.commit()

            # Create semester
            sem5 = Semester(number=5, name="Semester 5 - Fall 2024", branch_id=cs_branch.id)
            db.session.add(sem5)
            db.session.commit()
            
            # Enroll student
            student.current_semester_id = sem5.id
            sem5.students.append(student)
            
            # Create subjects
            sub1 = Subject(
                name="Operating Systems", 
                code="CS301", 
                description="Introduction to Operating System concepts",
                credits=3,
                semester_id=sem5.id
            )
            sub2 = Subject(
                name="Databases", 
                code="CS302", 
                description="Database Management Systems",
                credits=3,
                semester_id=sem5.id
            )
            db.session.add_all([sub1, sub2])
            db.session.commit()

            # Create class schedules (Friday is weekday 4)
            class1 = ClassSchedule(
                subject_id=sub1.id, 
                teacher_id=teacher.id, 
                room="301A", 
                day_of_week=4, 
                start_time=time(11,0), 
                end_time=time(12,0)
            )
            class2 = ClassSchedule(
                subject_id=sub2.id, 
                teacher_id=teacher.id, 
                room="301B", 
                day_of_week=4, 
                start_time=time(14,0), 
                end_time=time(15,0)
            )
            db.session.add_all([class1, class2])
            db.session.commit()

            print(f"Complete dummy data created successfully! Registration Code: {registration_code}")
        except Exception:
            print(f"!!!!!!!!!! AN ERROR OCCURRED DURING DATABASE SETUP !!!!!!!!!!!")
            print(traceback.format_exc())
            db.session.rollback()

if __name__ == '__main__':
    app.run(debug=True)