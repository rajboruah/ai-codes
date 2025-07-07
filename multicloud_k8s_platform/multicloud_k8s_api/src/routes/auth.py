from flask import Blueprint, request, jsonify, session
from functools import wraps
import hashlib
import secrets

auth_bp = Blueprint('auth', __name__)

# Simple in-memory user store for demo purposes
# In production, this should be a proper database with hashed passwords
USERS = {
    'admin': {
        'password_hash': hashlib.sha256('admin123'.encode()).hexdigest(),
        'role': 'admin'
    },
    'user': {
        'password_hash': hashlib.sha256('user123'.encode()).hexdigest(),
        'role': 'user'
    }
}

def require_auth(f):
    """Decorator to require authentication for routes"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session:
            return jsonify({'error': 'Authentication required'}), 401
        return f(*args, **kwargs)
    return decorated_function

def require_admin(f):
    """Decorator to require admin role for routes"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session:
            return jsonify({'error': 'Authentication required'}), 401
        
        user = USERS.get(session['user_id'])
        if not user or user['role'] != 'admin':
            return jsonify({'error': 'Admin access required'}), 403
        
        return f(*args, **kwargs)
    return decorated_function

@auth_bp.route('/login', methods=['POST'])
def login():
    """User login endpoint"""
    data = request.get_json()
    
    if not data or 'username' not in data or 'password' not in data:
        return jsonify({'error': 'Username and password required'}), 400
    
    username = data['username']
    password = data['password']
    
    # Check if user exists and password is correct
    user = USERS.get(username)
    if not user:
        return jsonify({'error': 'Invalid credentials'}), 401
    
    password_hash = hashlib.sha256(password.encode()).hexdigest()
    if password_hash != user['password_hash']:
        return jsonify({'error': 'Invalid credentials'}), 401
    
    # Create session
    session['user_id'] = username
    session['role'] = user['role']
    
    return jsonify({
        'message': 'Login successful',
        'user': {
            'username': username,
            'role': user['role']
        }
    }), 200

@auth_bp.route('/logout', methods=['POST'])
def logout():
    """User logout endpoint"""
    session.clear()
    return jsonify({'message': 'Logout successful'}), 200

@auth_bp.route('/me', methods=['GET'])
@require_auth
def get_current_user():
    """Get current user information"""
    username = session['user_id']
    user = USERS.get(username)
    
    return jsonify({
        'username': username,
        'role': user['role']
    }), 200

@auth_bp.route('/status', methods=['GET'])
def auth_status():
    """Check authentication status"""
    if 'user_id' in session:
        username = session['user_id']
        user = USERS.get(username)
        return jsonify({
            'authenticated': True,
            'user': {
                'username': username,
                'role': user['role']
            }
        }), 200
    else:
        return jsonify({'authenticated': False}), 200

