from flask import request
from flask_restx import Resource, Namespace, fields
from flask_jwt_extended import jwt_required, get_jwt_identity
from datetime import datetime
import re

from models import db, User, Report, ReportField, AdditionalField, ReportFile
from config import send_brevo_email, Config
from email_templates import get_test_email

# Create namespace
user_ns = Namespace('users', description='User operations')

# API Models
# FIX: Removed duplicate phone_number
# FIX: Added date_of_birth, gender, medical_history, allergies
user_update_model = user_ns.model('UserUpdate', {
    'first_name': fields.String(description='First name'),
    'last_name': fields.String(description='Last name'),
    'phone_number': fields.String(description='Phone number'),
    'date_of_birth': fields.String(description='Date of Birth (YYYY-MM-DD)'),
    'gender': fields.String(description='Gender'),
    'medical_history': fields.String(description='Medical History'),
    'allergies': fields.String(description='Allergies')
})

delete_user_model = user_ns.model('DeleteUser', {
    'user_id': fields.Integer(required=True, description='ID of the user to delete'),
    'admin_password': fields.String(required=True, description='Admin password for testing')
})

test_email_model = user_ns.model('TestEmail', {
    'to_email': fields.String(required=True, description='Recipient email address'),
    'subject': fields.String(required=True, description='Email subject'),
    'body': fields.String(required=True, description='Email body/message'),
    'admin_password': fields.String(required=True, description='Admin password (testingAdmin)')
})


@user_ns.route('/profile')
class UserProfile(Resource):
    @user_ns.doc(security='Bearer Auth')
    @jwt_required()
    def get(self):
        """Get user profile information"""
        current_user_id = int(get_jwt_identity())
        user = User.query.get(current_user_id)
        
        if not user:
            return {'message': 'User not found'}, 404

        return {
            'email': user.email,
            'first_name': user.first_name,
            'last_name': user.last_name,
            'date_of_birth': str(user.date_of_birth) if user.date_of_birth else None,
            'phone_number': user.phone_number,
            'gender': user.gender,
            'medical_history': user.medical_history,
            'allergies': user.allergies,
            'created_at': str(user.created_at)
        }

    @user_ns.doc(security='Bearer Auth')
    @jwt_required()
    @user_ns.expect(user_update_model)
    def put(self):
        """Update user profile"""
        current_user_id = int(get_jwt_identity())
        user = User.query.get(current_user_id)
        
        if not user:
            return {'message': 'User not found'}, 404

        data = request.json
        try:
            # FIX: Name Validation
            if 'first_name' in data:
                if not re.match(r"^[a-zA-Z\s]+$", str(data['first_name'])):
                     return {'message': 'First name must contain only letters'}, 400
                user.first_name = data['first_name']
            
            if 'last_name' in data:
                if not re.match(r"^[a-zA-Z\s]+$", str(data['last_name'])):
                     return {'message': 'Last name must contain only letters'}, 400
                user.last_name = data['last_name']
                
            if 'phone_number' in data:
                # Basic phone validation could be added here
                user.phone_number = data['phone_number']

            # FIX: Handle Date of Birth
            if 'date_of_birth' in data:
                dob_str = data['date_of_birth']
                if dob_str:
                    try:
                        # Expects YYYY-MM-DD
                        user.date_of_birth = datetime.strptime(dob_str, '%Y-%m-%d').date()
                    except ValueError:
                         return {'message': 'Invalid date format. Use YYYY-MM-DD'}, 400

            # Store other fields
            if 'gender' in data:
                user.gender = data['gender']
            if 'medical_history' in data:
                user.medical_history = data['medical_history']
            if 'allergies' in data:
                user.allergies = data['allergies']

            db.session.commit()
            return {'message': 'Profile updated successfully'}, 200
        except Exception as e:
            db.session.rollback()
            return {'message': 'Update failed', 'error': str(e)}, 400


@user_ns.route('/delete-account')
class DeleteAccount(Resource):
    @user_ns.doc(security='Bearer Auth')
    @jwt_required()
    def delete(self):
        """Delete current user's account and all associated data"""
        current_user_id = int(get_jwt_identity())
        user = User.query.get(current_user_id)
        
        if not user:
            return {'message': 'User not found'}, 404
        
        try:
            reports = Report.query.filter_by(user_id=current_user_id).all()
            for report in reports:
                ReportField.query.filter_by(report_id=report.id).delete()
                AdditionalField.query.filter_by(report_id=report.id).delete()
                # Assuming ReportFile is imported
                # ReportFile.query.filter_by(report_id=report.id).delete()
                db.session.delete(report)
            
            AdditionalField.query.filter_by(user_id=current_user_id).delete()
            
            db.session.delete(user)
            db.session.commit()
            
            return {
                'message': 'Account deleted successfully',
                'deleted_user_id': current_user_id,
                'email': user.email
            }, 200
            
        except Exception as e:
            db.session.rollback()
            return {
                'message': 'Failed to delete account',
                'error': str(e)
            }, 500


@user_ns.route('/delete-user-testing')
class DeleteUserTesting(Resource):
    @user_ns.expect(delete_user_model)
    def delete(self):
        """Delete a user by ID - FOR TESTING ONLY"""
        data = request.json
        user_id = data.get('user_id')
        admin_password = data.get('admin_password')
        
        if not user_id or not admin_password:
            return {'message': 'user_id and admin_password are required'}, 400
        
        if admin_password != 'testingAdmin':
            return {'message': 'Invalid admin password'}, 403
        
        user = User.query.get(user_id)
        
        if not user:
            return {'message': 'User not found'}, 404
        
        try:
            reports = Report.query.filter_by(user_id=user_id).all()
            for report in reports:
                ReportField.query.filter_by(report_id=report.id).delete()
                AdditionalField.query.filter_by(report_id=report.id).delete()
                db.session.delete(report)
            
            db.session.delete(user)
            db.session.commit()
            
            return {
                'message': f'User {user.email} (ID: {user_id}) deleted successfully (TESTING MODE)',
                'deleted_user_id': user_id,
                'deleted_email': user.email
            }, 200
        except Exception as e:
            db.session.rollback()
            return {
                'message': 'Failed to delete user',
                'error': str(e)
            }, 500


@user_ns.route('/test-email')
class TestEmail(Resource):
    @user_ns.expect(test_email_model)
    def post(self):
        """Test email sending - FOR TESTING ONLY"""
        data = request.json
        to_email = data.get('to_email')
        subject = data.get('subject')
        body = data.get('body')
        admin_password = data.get('admin_password')
        
        if not all([to_email, subject, body, admin_password]):
            return {'message': 'All fields are required: to_email, subject, body, admin_password'}, 400
        
        if admin_password != 'testingAdmin':
            return {'message': 'Invalid admin password'}, 403
        
        try:
            html_content = get_test_email(body)
            success = send_brevo_email(
                recipient_email=to_email,
                subject=subject,
                html_content=html_content
            )
            
            if success:
                return {'message': 'Email sent successfully'}, 200
            else:
                return {'message': 'Failed to send email'}, 500
            
        except Exception as e:
            return {'message': 'Failed to send email', 'error': str(e)}, 500
