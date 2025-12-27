import os
import traceback
from datetime import time, datetime, date
from functools import wraps

import google.generativeai as genai
import pandas as pd
from flask import Flask, jsonify, request
from flask_cors import CORS
from flask_migrate import Migrate
from flask_jwt_extended import (
    JWTManager, create_access_token, create_refresh_token,
    get_jwt, get_jwt_identity, jwt_required
)
from werkzeug.security import check_password_hash, generate_password_hash
from werkzeug.utils import secure_filename

# Lazy loading for heavy libraries to improve startup time
DeepFace = None
def load_deepface():
    global DeepFace
    if DeepFace is None:
        from deepface import DeepFace as df
        DeepFace = df
    return DeepFace

from config import Config
from models import db, User, Institution, Branch, Semester, Subject, ClassSchedule, AttendanceRecord, Batch, Section
from admin_routes import admin_bp
from security_config import create_limiter, configure_security_headers, InputValidator

KNOWN_FACES_DIR = 'known_faces'

def ensure_dirs(paths):
    for folder in paths:
        if not os.path.exists(folder):
            os.makedirs(folder)

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)
    app.config['UPLOAD_FOLDER'] = 'uploads'
    
    ensure_dirs([app.config['UPLOAD_FOLDER'], KNOWN_FACES_DIR])

    # Initialize Extensions
    db.init_app(app)
    Migrate(app, db)
    CORS(app, supports_credentials=True)
    JWTManager(app)
    limiter = create_limiter(app)
    configure_security_headers(app)

    # Register modular routes
    app.register_blueprint(admin_bp, url_prefix='/api/admin')

    # ---------- AI Helper ----------
    def call_generative_ai(prompt):
        api_key = os.getenv("GEMINI_API_KEY")
        if not api_key:
            return "1. Review today's notes. 2. Prepare for the next class."
        try:
            genai.configure(api_key=api_key)
            model = genai.GenerativeModel('gemini-1.5-flash-latest')
            response = model.generate_content(prompt)
            return response.text.replace('*', '').replace('#', '')
        except:
            return "1. Focus on weak subjects. 2. Review career goals."

    # ---------- Authentication Routes ----------
    @app.route('/api/login', methods=['POST'])
    @limiter.limit("10 per minute")
    def login():
        data = request.get_json() or {}
        college_id = data.get('college_id')
        password = data.get('password')
        
        user = User.query.filter_by(college_id=college_id).first()
        if user and user.check_password(password):
            access = create_access_token(identity=str(user.id), additional_claims={"role": user.role, "institution_id": user.institution_id})
            return jsonify({
                "token": access,
                "role": user.role,
                "user_id": user.id,
                "institution_name": user.institution.name
            }), 200
        return jsonify({"message": "Invalid credentials"}), 401

    # ---------- Super Admin Bulk Upload (Cleaned & Integrated) ----------
    @app.route('/api/admin/upload', methods=['POST'])
    @jwt_required()
    def admin_bulk_upload():
        claims = get_jwt()
        if claims.get('role') != 'admin':
            return jsonify({"message": "Admin access required"}), 403
            
        inst_id = claims.get('institution_id')
        upload_type = request.form.get('type')
        file = request.files.get('file')

        if not file: return jsonify({"message": "No file"}), 400

        try:
            df = pd.read_csv(file) if file.filename.endswith('.csv') else pd.read_excel(file)
            df.columns = [c.lower().strip().replace(' ', '_') for c in df.columns]
            
            created, updated = 0, 0
            for _, row in df.iterrows():
                if upload_type == 'students':
                    # Auto-create Batch/Section/Branch
                    batch_name = str(row.get('batch', '2021-2025'))
                    branch_code = str(row.get('branch', 'CSE'))
                    section_name = str(row.get('section', 'A'))
                    
                    batch = Batch.query.filter_by(name=batch_name, institution_id=inst_id).first()
                    if not batch:
                        batch = Batch(name=batch_name, institution_id=inst_id)
                        db.session.add(batch); db.session.flush()

                    branch = Branch.query.filter_by(code=branch_code, institution_id=inst_id).first()
                    if not branch:
                        branch = Branch(name=branch_code, code=branch_code, institution_id=inst_id)
                        db.session.add(branch); db.session.flush()

                    section = Section.query.filter_by(name=section_name, batch_id=batch.id, branch_id=branch.id).first()
                    if not section:
                        section = Section(name=section_name, batch_id=batch.id, branch_id=branch.id)
                        db.session.add(section); db.session.flush()

                    # Create/Update Student using Registration Number (College ID)
                    cid = str(row['college_id'])
                    user = User.query.filter_by(college_id=cid, institution_id=inst_id).first()
                    if not user:
                        user = User(college_id=cid, name=row['name'], role='student', institution_id=inst_id, section_id=section.id)
                        user.set_password(str(row.get('password', 'student123')))
                        db.session.add(user); created += 1
                    else:
                        user.section_id = section.id; updated += 1
            
            db.session.commit()
            return jsonify({"created": created, "updated": updated}), 200
        except Exception as e:
            db.session.rollback()
            return jsonify({"error": str(e)}), 500

    # ---------- Attendance Logic (Unified AI + DB) ----------
    @app.route('/api/mark_attendance', methods=['POST'])
    @jwt_required()
    def mark_attendance():
        file = request.files.get('attendance_photo')
        if not file: return jsonify({"message": "No photo"}), 400
        
        filename = secure_filename(file.filename)
        path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        file.save(path)
        
        try:
            df_face = load_deepface()
            # Searches the entire known_faces directory for multi-sample matches
            results = df_face.find(img_path=path, db_path=KNOWN_FACES_DIR, enforce_detection=False)
            present_ids = []
            for res in results:
                if not res.empty:
                    # Identity usually looks like 'known_faces/COLLEGE_ID/sample1.jpg'
                    identity_path = res.iloc[0].identity
                    college_id = os.path.basename(os.path.dirname(identity_path))
                    present_ids.append(college_id)
            
            return jsonify({"present_college_ids": list(set(present_ids))}), 200
        except Exception as e:
            return jsonify({"error": str(e)}), 500

    @app.route('/api/save_attendance', methods=['POST'])
    @jwt_required()
    def save_attendance():
        data = request.get_json()
        class_id = data.get('class_id')
        attendance_map = data.get('attendance') # { "COLLEGE_ID": True/False }
        inst_id = get_jwt().get('institution_id')
        
        for cid, is_present in attendance_map.items():
            student = User.query.filter_by(college_id=cid, institution_id=inst_id).first()
            if student:
                status = 'present' if is_present else 'absent'
                record = AttendanceRecord(student_id=student.id, class_id=class_id, status=status, date=date.today())
                db.session.add(record)
        db.session.commit()
        return jsonify({"message": "Success"}), 200

    return app

if __name__ == '__main__':
    app = create_app()
    app.run(debug=True)