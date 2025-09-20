# File: backend/auth.py
import jwt
from datetime import datetime, timedelta
from flask import current_app, request, jsonify
from functools import wraps
from models import User, db

class AuthManager:
    @staticmethod
    def generate_token(user_id, role, institution_id):
        """Generate JWT token for user"""
        payload = {
            'user_id': user_id,
            'role': role,
            'institution_id': institution_id,
            'exp': datetime.utcnow() + timedelta(days=7),  # Token expires in 7 days
            'iat': datetime.utcnow()
        }
        
        token = jwt.encode(
            payload, 
            current_app.config['SECRET_KEY'], 
            algorithm='HS256'
        )
        
        return token
    
    @staticmethod
    def decode_token(token):
        """Decode JWT token and return payload"""
        try:
            payload = jwt.decode(
                token, 
                current_app.config['SECRET_KEY'], 
                algorithms=['HS256']
            )
            return payload
        except jwt.ExpiredSignatureError:
            return None
        except jwt.InvalidTokenError:
            return None
    
    @staticmethod
    def get_current_user():
        """Get current user from JWT token"""
        token = None
        
        # Check for token in Authorization header
        if 'Authorization' in request.headers:
            auth_header = request.headers['Authorization']
            try:
                token = auth_header.split(" ")[1]  # Bearer <token>
            except IndexError:
                return None
        
        if not token:
            return None
        
        payload = AuthManager.decode_token(token)
        if not payload:
            return None
        
        user = User.query.get(payload['user_id'])
        if not user or not user.is_active:
            return None
        
        return user, payload

def jwt_required(roles=None):
    """Decorator to require JWT authentication"""
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            result = AuthManager.get_current_user()
            
            if not result:
                return jsonify({'error': 'Authentication required'}), 401
            
            user, payload = result
            
            # Check role if specified
            if roles and user.role not in roles:
                return jsonify({'error': 'Insufficient permissions'}), 403
            
            # Add user info to request context
            request.current_user = user
            request.current_payload = payload
            
            return f(*args, **kwargs)
        return decorated_function
    return decorator

def admin_required(f):
    """Decorator to require admin role"""
    return jwt_required(roles=['admin'])(f)

def get_user_institution_id():
    """Get current user's institution ID"""
    if hasattr(request, 'current_user'):
        return request.current_user.institution_id
    return None