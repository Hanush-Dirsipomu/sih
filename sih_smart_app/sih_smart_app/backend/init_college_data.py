# File: backend/init_college_data.py
"""
Initialize database with college data based on the provided timetable
Run this script to populate your database with realistic data
"""

from app import create_app
from models import db, Institution, User, Branch, Semester, Subject, ClassSchedule
from datetime import time, datetime
import os

def init_college_data():
    """Initialize database with college data"""
    app = create_app()
    
    with app.app_context():
        # Clear existing data (optional - comment out to keep existing data)
        # db.drop_all()
        # db.create_all()
        
        print("Starting college data initialization...")
        
        # 1. Create Institution (Your College)
        institution = Institution.query.filter_by(name="Department of Computer Science and Engineering").first()
        if not institution:
            institution = Institution(
                name="Department of Computer Science and Engineering",
                address="College Campus, Your City",
                phone="+91-XXXXXXXXXX",
                email="cse@yourcollege.edu",
                registration_code="CSE_DEPT_2024"
            )
            db.session.add(institution)
            db.session.flush()
            print("✓ Institution created")
        else:
            print("✓ Institution already exists")
        
        # 2. Create Admin User
        admin = User.query.filter_by(college_id="ADMIN_CSE_001").first()
        if not admin:
            admin = User(
                college_id="ADMIN_CSE_001",
                name="Department Admin",
                email="admin@cse.college.edu",
                role="admin",
                institution_id=institution.id
            )
            admin.set_password("admin123")
            db.session.add(admin)
            print("✓ Admin user created (ID: ADMIN_CSE_001, Password: admin123)")
        
        # 3. Create Branch - Computer Science and Engineering
        cse_branch = Branch.query.filter_by(code="CSE", institution_id=institution.id).first()
        if not cse_branch:
            cse_branch = Branch(
                name="Computer Science and Engineering",
                code="CSE",
                description="Bachelor of Technology in Computer Science and Engineering",
                duration_years=4,
                institution_id=institution.id
            )
            db.session.add(cse_branch)
            db.session.flush()
            print("✓ CSE Branch created")
        
        # 4. Create Semesters for CSE Branch
        semesters_data = [
            {"number": 1, "name": "Semester 1 - B.Tech CSE"},
            {"number": 2, "name": "Semester 2 - B.Tech CSE"},
            {"number": 3, "name": "Semester 3 - B.Tech CSE"},
            {"number": 4, "name": "Semester 4 - B.Tech CSE"},
            {"number": 5, "name": "Semester 5 - B.Tech CSE"},
            {"number": 6, "name": "Semester 6 - B.Tech CSE"},
            {"number": 7, "name": "Semester 7 - B.Tech CSE"},
            {"number": 8, "name": "Semester 8 - B.Tech CSE"},
        ]
        
        semesters = {}
        for sem_data in semesters_data:
            semester = Semester.query.filter_by(number=sem_data["number"], branch_id=cse_branch.id).first()
            if not semester:
                semester = Semester(
                    number=sem_data["number"],
                    name=sem_data["name"],
                    branch_id=cse_branch.id
                )
                db.session.add(semester)
                db.session.flush()
            semesters[sem_data["number"]] = semester
        print("✓ Semesters created")
        
        # 5. Create Teachers based on your timetable
        teachers_data = [
            {"college_id": "TEA_001", "name": "Dr. B M V Narasimha Raju", "department": "Computer Science", "designation": "Professor"},
            {"college_id": "TEA_002", "name": "Smt. K Divya Bhavani", "department": "Computer Science", "designation": "Assistant Professor"},
            {"college_id": "TEA_003", "name": "Dr. D N S Ravi Teja", "department": "Computer Science", "designation": "Associate Professor"},
            {"college_id": "TEA_004", "name": "Laxmi Teacher", "department": "Computer Science", "designation": "Assistant Professor"},
            {"college_id": "TEA_005", "name": "Smt. P Jyotirmai", "department": "Computer Science", "designation": "Assistant Professor"},
            {"college_id": "TEA_006", "name": "Smt. A Lavanya", "department": "Computer Science", "designation": "Assistant Professor"},
            {"college_id": "TEA_007", "name": "Smt. K Ravi Ratnesh", "department": "Computer Science", "designation": "Assistant Professor"},
            {"college_id": "TEA_008", "name": "Sri. S Suresh Kumar", "department": "Computer Science", "designation": "Assistant Professor"},
            {"college_id": "TEA_009", "name": "Mrs. Ch Sumana", "department": "Computer Science", "designation": "Assistant Professor"},
            {"college_id": "TEA_010", "name": "VA-P Shankar", "department": "Computer Science", "designation": "Visiting Faculty"},
            {"college_id": "TEA_011", "name": "Dr. Smt. B Ramadevi Baba", "department": "Computer Science", "designation": "Professor"}
        ]
        
        teachers = {}
        for teacher_data in teachers_data:
            teacher = User.query.filter_by(college_id=teacher_data["college_id"]).first()
            if not teacher:
                teacher = User(
                    college_id=teacher_data["college_id"],
                    name=teacher_data["name"],
                    email=f"{teacher_data['college_id'].lower()}@cse.college.edu",
                    role="teacher",
                    department=teacher_data["department"],
                    designation=teacher_data["designation"],
                    institution_id=institution.id
                )
                teacher.set_password("teacher123")
                db.session.add(teacher)
                db.session.flush()
            teachers[teacher_data["college_id"]] = teacher
        print("✓ Teachers created")
        
        # 6. Create Subjects for Semester 3 (as shown in your timetable)
        sem3_subjects_data = [
            {"name": "Deep Learning", "code": "CS301", "teacher": "TEA_001", "credits": 3},  # Dr. B M V Narasimha Raju
            {"name": "Computer Networks", "code": "CS302", "teacher": "TEA_002", "credits": 4},  # Smt. K Divya Bhavani  
            {"name": "Natural Language Processing", "code": "CS303", "teacher": "TEA_003", "credits": 3},  # Dr. D N S Ravi Teja
            {"name": "Design Engineering", "code": "DE301", "teacher": "TEA_004", "credits": 2},  # Laxmi Teacher
            {"name": "Computer Networks Lab", "code": "CS302L", "teacher": "TEA_002", "credits": 2},  # Lab
            {"name": "NLP Lab", "code": "CS303L", "teacher": "TEA_003", "credits": 2},  # Lab
            {"name": "Deep Learning Lab", "code": "CS301L", "teacher": "TEA_001", "credits": 2},  # Lab
            {"name": "Soft Skills", "code": "SS301", "teacher": "TEA_005", "credits": 1},  # Smt. P Jyotirmai
            {"name": "Evaluation of System Science Internship", "code": "IN301", "teacher": "TEA_006", "credits": 2},  # Smt. A Lavanya
            {"name": "Eligibility Skills", "code": "ES301", "teacher": "TEA_010", "credits": 1}  # VA-P Shankar
        ]
        
        sem3_subjects = {}
        semester_3 = semesters[3]  # 3rd semester
        
        for subject_data in sem3_subjects_data:
            subject = Subject.query.filter_by(code=subject_data["code"], semester_id=semester_3.id).first()
            if not subject:
                subject = Subject(
                    name=subject_data["name"],
                    code=subject_data["code"],
                    credits=subject_data["credits"],
                    semester_id=semester_3.id
                )
                db.session.add(subject)
                db.session.flush()
            sem3_subjects[subject_data["code"]] = subject
        print("✓ Semester 3 subjects created")
        
        # 7. Create Class Schedules based on your timetable
        # Based on the timetable image: III B.Tech, ADMN-CSE, 2S1 Semester
        schedules_data = [
            # Monday (0)
            {"subject": "CS301", "teacher": "TEA_001", "day": 0, "start": "08:30", "end": "09:25", "room": "CSE-1"},
            {"subject": "CS302", "teacher": "TEA_002", "day": 0, "start": "09:25", "end": "10:20", "room": "CSE-1"},
            {"subject": "CS303", "teacher": "TEA_003", "day": 0, "start": "10:45", "end": "11:40", "room": "CSE-1"},
            {"subject": "DE301", "teacher": "TEA_004", "day": 0, "start": "11:40", "end": "12:35", "room": "CSE-1"},
            
            # Tuesday (1)
            {"subject": "CS302", "teacher": "TEA_002", "day": 1, "start": "08:30", "end": "09:25", "room": "CSE-1"},
            {"subject": "CS301L", "teacher": "TEA_001", "day": 1, "start": "09:25", "end": "11:40", "room": "CS-LAB-1"},  # 2-hour lab
            {"subject": "CS303", "teacher": "TEA_003", "day": 1, "start": "11:40", "end": "12:35", "room": "CSE-1"},
            
            # Wednesday (2)
            {"subject": "CS301", "teacher": "TEA_001", "day": 2, "start": "08:30", "end": "09:25", "room": "CSE-1"},
            {"subject": "CS302L", "teacher": "TEA_002", "day": 2, "start": "09:25", "end": "11:40", "room": "CS-LAB-2"},  # 2-hour lab
            {"subject": "ES301", "teacher": "TEA_010", "day": 2, "start": "11:40", "end": "12:35", "room": "CSE-1"},
            
            # Thursday (3)
            {"subject": "CS303", "teacher": "TEA_003", "day": 3, "start": "08:30", "end": "09:25", "room": "CSE-1"},
            {"subject": "DE301", "teacher": "TEA_004", "day": 3, "start": "09:25", "end": "10:20", "room": "CSE-1"},
            {"subject": "CS303L", "teacher": "TEA_003", "day": 3, "start": "10:45", "end": "12:35", "room": "CS-LAB-1"},  # 2-hour lab
            
            # Friday (4)
            {"subject": "SS301", "teacher": "TEA_005", "day": 4, "start": "08:30", "end": "09:25", "room": "CSE-1"},
            {"subject": "IN301", "teacher": "TEA_006", "day": 4, "start": "09:25", "end": "10:20", "room": "CSE-1"},
            {"subject": "CS301", "teacher": "TEA_001", "day": 4, "start": "10:45", "end": "11:40", "room": "CSE-1"},
            {"subject": "CS302", "teacher": "TEA_002", "day": 4, "start": "11:40", "end": "12:35", "room": "CSE-1"},
        ]
        
        for schedule_data in schedules_data:
            # Check if schedule already exists
            existing_schedule = ClassSchedule.query.filter_by(
                subject_id=sem3_subjects[schedule_data["subject"]].id,
                teacher_id=teachers[schedule_data["teacher"]].id,
                day_of_week=schedule_data["day"],
                start_time=datetime.strptime(schedule_data["start"], "%H:%M").time()
            ).first()
            
            if not existing_schedule:
                schedule = ClassSchedule(
                    subject_id=sem3_subjects[schedule_data["subject"]].id,
                    teacher_id=teachers[schedule_data["teacher"]].id,
                    room=schedule_data["room"],
                    day_of_week=schedule_data["day"],
                    start_time=datetime.strptime(schedule_data["start"], "%H:%M").time(),
                    end_time=datetime.strptime(schedule_data["end"], "%H:%M").time()
                )
                db.session.add(schedule)
        print("✓ Class schedules created")
        
        # 8. Create Sample Students
        sample_students_data = [
            {"college_id": "21B81A0501", "name": "Student One"},
            {"college_id": "21B81A0502", "name": "Student Two"}, 
            {"college_id": "21B81A0503", "name": "Student Three"},
            {"college_id": "21B81A0504", "name": "Student Four"},
            {"college_id": "21B81A0505", "name": "Student Five"},
        ]
        
        students = []
        for student_data in sample_students_data:
            student = User.query.filter_by(college_id=student_data["college_id"]).first()
            if not student:
                student = User(
                    college_id=student_data["college_id"],
                    name=student_data["name"],
                    email=f"{student_data['college_id'].lower()}@student.college.edu",
                    role="student",
                    institution_id=institution.id,
                    branch_id=cse_branch.id,
                    current_semester_id=semester_3.id,  # Enroll in 3rd semester
                    career_goal="Software Development",
                    interests="Machine Learning, Web Development",
                    weak_subjects="Computer Networks"
                )
                student.set_password("student123")
                db.session.add(student)
                students.append(student)
        print("✓ Sample students created")
        
        # Commit all changes
        db.session.commit()
        print("\n🎉 College data initialization completed successfully!")
        print("\nLogin Credentials:")
        print("=" * 50)
        print("ADMIN:")
        print("  College ID: ADMIN_CSE_001")
        print("  Password: admin123")
        print("\nTEACHERS:")
        print("  College ID: TEA_001 to TEA_011")
        print("  Password: teacher123")
        print("\nSTUDENTS:")
        print("  College ID: 21B81A0501 to 21B81A0505")
        print("  Password: student123")
        print("=" * 50)
        
        return {
            'institution': institution,
            'branch': cse_branch,
            'semester_3': semester_3,
            'subjects': sem3_subjects,
            'teachers': teachers,
            'students': students
        }

if __name__ == "__main__":
    try:
        data = init_college_data()
        print("\n✅ Database initialized with your college data!")
        print("You can now run the Flask app and login with the provided credentials.")
    except Exception as e:
        print(f"\n❌ Error initializing database: {e}")
        import traceback
        traceback.print_exc()