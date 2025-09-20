# File: backend/file_processor.py
import pandas as pd
import os
from werkzeug.utils import secure_filename
from security_config import allowed_file, sanitize_filename, validate_csv_headers, InputValidator
from models import db, User, Branch, Semester, Subject, ClassSchedule
from datetime import datetime, time
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class FileProcessor:
    """Enhanced file processing for CSV/Excel uploads"""
    
    def __init__(self, upload_folder):
        self.upload_folder = upload_folder
        
    def save_uploaded_file(self, file):
        """Securely save uploaded file"""
        if not file or not file.filename:
            return None, "No file provided"
        
        if not allowed_file(file.filename):
            return None, "File type not allowed. Please upload CSV or Excel files only."
        
        # Sanitize filename
        filename = sanitize_filename(secure_filename(file.filename))
        if not filename:
            return None, "Invalid filename"
        
        # Create unique filename to avoid conflicts
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        name, ext = os.path.splitext(filename)
        unique_filename = f"{name}_{timestamp}{ext}"
        
        filepath = os.path.join(self.upload_folder, unique_filename)
        
        try:
            file.save(filepath)
            return filepath, None
        except Exception as e:
            logger.error(f"Error saving file: {e}")
            return None, "Error saving file"
    
    def read_file(self, filepath):
        """Read CSV or Excel file into DataFrame"""
        try:
            file_ext = os.path.splitext(filepath)[1].lower()
            
            if file_ext == '.csv':
                df = pd.read_csv(filepath, encoding='utf-8')
            elif file_ext in ['.xlsx', '.xls']:
                df = pd.read_excel(filepath)
            else:
                return None, "Unsupported file format"
            
            # Clean column names
            df.columns = df.columns.str.strip()
            
            return df, None
        except Exception as e:
            logger.error(f"Error reading file {filepath}: {e}")
            return None, f"Error reading file: {str(e)}"
    
    def process_students_file(self, filepath, institution_id):
        """Process student data from CSV/Excel file"""
        df, error = self.read_file(filepath)
        if error:
            return None, error
        
        # Expected headers for student file
        expected_headers = ['college_id', 'name', 'email', 'phone', 'branch_code', 'semester_number', 'password']
        
        # Validate headers
        valid, error = validate_csv_headers(df.columns.tolist(), expected_headers)
        if not valid:
            return None, error
        
        results = {
            'success': [],
            'errors': [],
            'duplicates': []
        }
        
        for index, row in df.iterrows():
            try:
                # Validate data
                college_id = str(row['college_id']).strip()
                name = str(row['name']).strip()
                email = str(row['email']).strip() if pd.notna(row['email']) else None
                phone = str(row['phone']).strip() if pd.notna(row['phone']) else None
                branch_code = str(row['branch_code']).strip()
                semester_number = int(row['semester_number']) if pd.notna(row['semester_number']) else None
                password = str(row['password']).strip()
                
                # Input validation
                valid_id, id_error = InputValidator.validate_college_id(college_id)
                if not valid_id:
                    results['errors'].append(f"Row {index + 2}: {id_error}")
                    continue
                
                valid_name, name_error = InputValidator.validate_name(name)
                if not valid_name:
                    results['errors'].append(f"Row {index + 2}: {name_error}")
                    continue
                
                # Check if user already exists
                existing_user = User.query.filter_by(
                    college_id=college_id,
                    institution_id=institution_id
                ).first()
                
                if existing_user:
                    results['duplicates'].append(f"Row {index + 2}: College ID {college_id} already exists")
                    continue
                
                # Find branch
                branch = Branch.query.filter_by(
                    code=branch_code,
                    institution_id=institution_id
                ).first()
                
                if not branch:
                    results['errors'].append(f"Row {index + 2}: Branch code {branch_code} not found")
                    continue
                
                # Find semester (optional)
                semester = None
                if semester_number:
                    semester = Semester.query.filter_by(
                        number=semester_number,
                        branch_id=branch.id
                    ).first()
                
                # Create user
                user = User(
                    college_id=college_id,
                    name=name,
                    email=email,
                    phone=phone,
                    role='student',
                    institution_id=institution_id,
                    branch_id=branch.id,
                    current_semester_id=semester.id if semester else None
                )
                user.set_password(password)
                
                db.session.add(user)
                results['success'].append(f"Row {index + 2}: Student {name} ({college_id}) added successfully")
                
            except Exception as e:
                results['errors'].append(f"Row {index + 2}: {str(e)}")
        
        try:
            db.session.commit()
            logger.info(f"Processed students file: {len(results['success'])} success, {len(results['errors'])} errors")
        except Exception as e:
            db.session.rollback()
            logger.error(f"Error committing student data: {e}")
            return None, f"Database error: {str(e)}"
        
        return results, None
    
    def process_teachers_file(self, filepath, institution_id):
        """Process teacher data from CSV/Excel file"""
        df, error = self.read_file(filepath)
        if error:
            return None, error
        
        expected_headers = ['college_id', 'name', 'email', 'phone', 'department', 'designation', 'password']
        
        valid, error = validate_csv_headers(df.columns.tolist(), expected_headers)
        if not valid:
            return None, error
        
        results = {
            'success': [],
            'errors': [],
            'duplicates': []
        }
        
        for index, row in df.iterrows():
            try:
                college_id = str(row['college_id']).strip()
                name = str(row['name']).strip()
                email = str(row['email']).strip() if pd.notna(row['email']) else None
                phone = str(row['phone']).strip() if pd.notna(row['phone']) else None
                department = str(row['department']).strip() if pd.notna(row['department']) else None
                designation = str(row['designation']).strip() if pd.notna(row['designation']) else None
                password = str(row['password']).strip()
                
                # Input validation
                valid_id, id_error = InputValidator.validate_college_id(college_id)
                if not valid_id:
                    results['errors'].append(f"Row {index + 2}: {id_error}")
                    continue
                
                valid_name, name_error = InputValidator.validate_name(name)
                if not valid_name:
                    results['errors'].append(f"Row {index + 2}: {name_error}")
                    continue
                
                # Check if user already exists
                existing_user = User.query.filter_by(
                    college_id=college_id,
                    institution_id=institution_id
                ).first()
                
                if existing_user:
                    results['duplicates'].append(f"Row {index + 2}: College ID {college_id} already exists")
                    continue
                
                # Create teacher
                user = User(
                    college_id=college_id,
                    name=name,
                    email=email,
                    phone=phone,
                    role='teacher',
                    institution_id=institution_id,
                    department=department,
                    designation=designation
                )
                user.set_password(password)
                
                db.session.add(user)
                results['success'].append(f"Row {index + 2}: Teacher {name} ({college_id}) added successfully")
                
            except Exception as e:
                results['errors'].append(f"Row {index + 2}: {str(e)}")
        
        try:
            db.session.commit()
            logger.info(f"Processed teachers file: {len(results['success'])} success, {len(results['errors'])} errors")
        except Exception as e:
            db.session.rollback()
            logger.error(f"Error committing teacher data: {e}")
            return None, f"Database error: {str(e)}"
        
        return results, None
    
    def process_timetable_file(self, filepath, institution_id):
        """Process timetable data from CSV/Excel file"""
        df, error = self.read_file(filepath)
        if error:
            return None, error
        
        expected_headers = ['subject_code', 'teacher_college_id', 'room', 'day_of_week', 'start_time', 'end_time']
        
        valid, error = validate_csv_headers(df.columns.tolist(), expected_headers)
        if not valid:
            return None, error
        
        results = {
            'success': [],
            'errors': []
        }
        
        for index, row in df.iterrows():
            try:
                subject_code = str(row['subject_code']).strip()
                teacher_college_id = str(row['teacher_college_id']).strip()
                room = str(row['room']).strip() if pd.notna(row['room']) else None
                day_of_week = int(row['day_of_week'])
                start_time_str = str(row['start_time']).strip()
                end_time_str = str(row['end_time']).strip()
                
                # Validate day of week (0=Monday, 6=Sunday)
                if day_of_week < 0 or day_of_week > 6:
                    results['errors'].append(f"Row {index + 2}: Invalid day_of_week. Must be 0-6 (0=Monday)")
                    continue
                
                # Parse time strings
                try:
                    start_time = datetime.strptime(start_time_str, '%H:%M').time()
                    end_time = datetime.strptime(end_time_str, '%H:%M').time()
                except ValueError:
                    results['errors'].append(f"Row {index + 2}: Invalid time format. Use HH:MM format")
                    continue
                
                # Find subject
                subject = Subject.query.join(Semester).join(Branch).filter(
                    Subject.code == subject_code,
                    Branch.institution_id == institution_id
                ).first()
                
                if not subject:
                    results['errors'].append(f"Row {index + 2}: Subject code {subject_code} not found")
                    continue
                
                # Find teacher
                teacher = User.query.filter_by(
                    college_id=teacher_college_id,
                    institution_id=institution_id,
                    role='teacher'
                ).first()
                
                if not teacher:
                    results['errors'].append(f"Row {index + 2}: Teacher {teacher_college_id} not found")
                    continue
                
                # Create class schedule
                schedule = ClassSchedule(
                    subject_id=subject.id,
                    teacher_id=teacher.id,
                    room=room,
                    day_of_week=day_of_week,
                    start_time=start_time,
                    end_time=end_time
                )
                
                db.session.add(schedule)
                results['success'].append(f"Row {index + 2}: Schedule for {subject.name} added successfully")
                
            except Exception as e:
                results['errors'].append(f"Row {index + 2}: {str(e)}")
        
        try:
            db.session.commit()
            logger.info(f"Processed timetable file: {len(results['success'])} success, {len(results['errors'])} errors")
        except Exception as e:
            db.session.rollback()
            logger.error(f"Error committing timetable data: {e}")
            return None, f"Database error: {str(e)}"
        
        return results, None
    
    def cleanup_file(self, filepath):
        """Clean up uploaded file after processing"""
        try:
            if os.path.exists(filepath):
                os.remove(filepath)
                logger.info(f"Cleaned up file: {filepath}")
        except Exception as e:
            logger.error(f"Error cleaning up file {filepath}: {e}")