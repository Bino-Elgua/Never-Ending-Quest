from flask import Blueprint, jsonify, request
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity
import datetime

auth_bp = Blueprint('auth', __name__)

# Simple user storage for demo/prototype (move to database later)
# In a real app, these would be in the PostgreSQL 'users' table
USERS = {
    "admin": "password123",
    "player1": "quest123"
}

@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.get_json() or {}
    username = data.get('username')
    password = data.get('password')
    
    if username in USERS and USERS[username] == password:
        # Create token that expires in 30 days
        expires = datetime.timedelta(days=30)
        access_token = create_access_token(identity=username, expires_delta=expires)
        return jsonify(access_token=access_token), 200
    
    return jsonify({"msg": "Bad username or password"}), 401

@auth_bp.route('/verify', methods=['GET'])
@jwt_required()
def verify():
    current_user = get_jwt_identity()
    return jsonify(logged_in_as=current_user), 200
