# File: backend/security_config.py
import os
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from flask_talisman import Talisman
import validators
import re
from passlib.context import CryptContext
from email_validator import validate_email, EmailNotValidError

class SecurityConfig:
    """Enhanced security configuration for the application"""
    
    # Password strength requirements
    MIN_PASSWORD_LENGTH = 8
    REQUIRE_UPPERCASE = True
    REQUIRE_LOWERCASE = True
    REQUIRE_NUMBERS = True
    REQUIRE_SPECIAL_CHARS = True
    
    # Rate limiting settings
    RATE_LIMIT_DEFAULT = "100/hour"
    RATE_LIMIT_LOGIN = "5/minute"
    RATE_LIMIT_REGISTER = "3/minute"
    RATE_LIMIT_UPLOAD = "10/hour"
    
    # File upload settings
    MAX_FILE_SIZE = 16 * 1024 * 1024  # 16MB
    ALLOWED_EXTENSIONS = {'csv', 'xlsx', 'xls'}
    
    # JWT settings
    JWT_ACCESS_TOKEN_EXPIRES = 3600  # 1 hour
    JWT_REFRESH_TOKEN_EXPIRES = 604800  # 7 days

def create_limiter(app):
    """Create and configure rate limiter"""
    limiter = Limiter(
        app=app,
        key_func=get_remote_address,
        default_limits=[SecurityConfig.RATE_LIMIT_DEFAULT]
    )
    return limiter

def configure_security_headers(app):
    """Configure security headers using Talisman"""
    csp = {
        'default-src': "'self'",
        'script-src': ["'self'", "'unsafe-inline'", 'cdnjs.cloudflare.com'],
        'style-src': ["'self'", "'unsafe-inline'", 'fonts.googleapis.com'],
        'font-src': ["'self'", 'fonts.gstatic.com'],
        'img-src': ["'self'", 'data:', 'https:'],
        'connect-src': ["'self'"]
    }
    
    Talisman(
        app,
        force_https=False,  # Set to True in production
        strict_transport_security=True,
        content_security_policy=csp,
        referrer_policy='strict-origin-when-cross-origin'
    )

def validate_password(password):
    """Validate password strength"""
    errors = []
    
    if len(password) < SecurityConfig.MIN_PASSWORD_LENGTH:
        errors.append(f"Password must be at least {SecurityConfig.MIN_PASSWORD_LENGTH} characters long")
    
    if SecurityConfig.REQUIRE_UPPERCASE and not re.search(r'[A-Z]', password):
        errors.append("Password must contain at least one uppercase letter")
    
    if SecurityConfig.REQUIRE_LOWERCASE and not re.search(r'[a-z]', password):
        errors.append("Password must contain at least one lowercase letter")
    
    if SecurityConfig.REQUIRE_NUMBERS and not re.search(r'\d', password):
        errors.append("Password must contain at least one number")
    
    if SecurityConfig.REQUIRE_SPECIAL_CHARS and not re.search(r'[!@#$%^&*(),.?":{}|<>]', password):
        errors.append("Password must contain at least one special character")
    
    return errors

def validate_email_format(email):
    """Validate email format"""
    try:
        validate_email(email)
        return True, None
    except EmailNotValidError as e:
        return False, str(e)

def validate_phone_number(phone):
    """Validate phone number format"""
    if not phone:
        return True, None
    
    # Basic phone validation (adjust pattern as needed)
    pattern = r'^[\+]?[1-9][\d]{0,15}$'
    if re.match(pattern, phone.replace(' ', '').replace('-', '')):
        return True, None
    else:
        return False, "Invalid phone number format"

def sanitize_filename(filename):
    """Sanitize uploaded filename"""
    # Remove path components
    filename = os.path.basename(filename)
    # Remove or replace dangerous characters
    filename = re.sub(r'[<>:"/\\|?*]', '_', filename)
    # Limit length
    if len(filename) > 255:
        name, ext = os.path.splitext(filename)
        filename = name[:255-len(ext)] + ext
    return filename

def allowed_file(filename):
    """Check if file extension is allowed"""
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in SecurityConfig.ALLOWED_EXTENSIONS

def validate_csv_headers(headers, expected_headers):
    """Validate CSV headers match expected format"""
    missing_headers = set(expected_headers) - set(headers)
    extra_headers = set(headers) - set(expected_headers)
    
    if missing_headers:
        return False, f"Missing required headers: {', '.join(missing_headers)}"
    
    if extra_headers:
        return False, f"Unexpected headers found: {', '.join(extra_headers)}"
    
    return True, None

class InputValidator:
    """Input validation utilities"""
    
    @staticmethod
    def validate_college_id(college_id):
        """Validate college ID format"""
        if not college_id or len(college_id) < 3:
            return False, "College ID must be at least 3 characters long"
        
        # Allow alphanumeric and some special characters
        if not re.match(r'^[A-Za-z0-9_-]+$', college_id):
            return False, "College ID can only contain letters, numbers, underscores, and hyphens"
        
        return True, None
    
    @staticmethod
    def validate_name(name):
        """Validate name format"""
        if not name or len(name.strip()) < 2:
            return False, "Name must be at least 2 characters long"
        
        if len(name) > 100:
            return False, "Name must be less than 100 characters"
        
        # Allow letters, spaces, and some special characters
        if not re.match(r'^[A-Za-z\s\.\-\']+$', name):
            return False, "Name can only contain letters, spaces, periods, hyphens, and apostrophes"
        
        return True, None
    
    @staticmethod
    def validate_role(role):
        """Validate user role"""
        allowed_roles = ['admin', 'teacher', 'student']
        if role not in allowed_roles:
            return False, f"Role must be one of: {', '.join(allowed_roles)}"
        return True, None

def create_password_context():
    """Create password hashing context"""
    return CryptContext(schemes=["bcrypt"], deprecated="auto")

# Password context instance
pwd_context = create_password_context()

def hash_password(password):
    """Hash password using bcrypt"""
    return pwd_context.hash(password)

def verify_password(password, hashed):
    """Verify password against hash"""
    return pwd_context.verify(password, hashed)