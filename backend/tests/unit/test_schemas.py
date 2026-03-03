"""
Unit Tests for Schema Models
"""
import pytest
from datetime import datetime
from pydantic import ValidationError
from app.models.schemas import (
    UserCreate,
    UserLogin,
    DiagnosisResponse,
    NotificationCreate,
    PasswordReset as PasswordResetRequest
)


@pytest.mark.unit
class TestUserSchemas:
    """Test user-related schemas"""
    
    def test_user_create_valid(self):
        """Test valid user creation schema"""
        user = UserCreate(
            name="John Doe",
            email="john@example.com",
            password="SecurePass123!",
            phone="1234567890",
            preferred_language="en"
        )
        
        assert user.email == "john@example.com"
        assert user.name == "John Doe"
    
    def test_user_create_invalid_email(self):
        """Test user creation with invalid email"""
        with pytest.raises(ValidationError):
            UserCreate(
                name="John Doe",
                email="invalid-email",
                password="SecurePass123!",
                phone="1234567890"
            )
    
    def test_user_login_valid(self):
        """Test valid login schema"""
        login = UserLogin(
            username="test@example.com",
            password="password123"
        )
        
        assert login.username == "test@example.com"
    
    def test_user_login_invalid(self):
        """Test invalid login schema"""
        with pytest.raises(ValidationError):
            UserLogin(
                username="invalid"
            )


@pytest.mark.unit
class TestDiagnosisSchemas:
    """Test diagnosis-related schemas"""
    
    def test_diagnosis_response_valid(self):
        """Test valid diagnosis response"""
        diagnosis = DiagnosisResponse(
            id="507f1f77bcf86cd799439011",
            user_id="507f1f77bcf86cd799439012",
            crop_type="tomato",
            disease_id="tomato_early_blight",
            disease_name="Early Blight",
            confidence=0.92,
            severity="medium",
            is_healthy=False,
            created_at=datetime.utcnow(),
            image_url="http://example.com/test.jpg"
        )
        
        assert diagnosis.crop_type == "tomato"
        assert diagnosis.confidence == 0.92
    
    def test_diagnosis_missing_image_url(self):
        """Test diagnosis validation error on missing required fields"""
        with pytest.raises(ValidationError):
            DiagnosisResponse(
                id="507f1f77bcf86cd799439011",
                user_id="507f1f77bcf86cd799439012",
                crop_type="tomato",
                disease_id="test",
                disease_name="Test",
                confidence=0.9,
                severity="medium",
                is_healthy=False,
                created_at=datetime.utcnow()
                # Missing image_url
            )


@pytest.mark.unit
class TestNotificationSchemas:
    """Test notification-related schemas"""
    
    def test_notification_create_valid(self):
        """Test valid notification creation"""
        notification = NotificationCreate(
            user_id="user_123",
            title="Test Notification",
            message="This is a test message",
            notification_type="system"
        )
        
        assert notification.title == "Test Notification"
        assert notification.notification_type == "system"
    
    def test_notification_type_validation(self):
        """Test notification type validation"""
        # Create with invalid type
        with pytest.raises(ValidationError):
            NotificationCreate(
                user_id="user_123",
                title="Test",
                message="Test message",
                notification_type="invalid_type"
            )


@pytest.mark.unit
class TestPasswordResetSchemas:
    """Test password reset schemas"""
    
    def test_password_reset_request_valid(self):
        """Test valid password reset request"""
        reset = PasswordResetRequest(
            username="test@example.com"
        )
        
        assert reset.username == "test@example.com"
    
    def test_password_reset_missing_username(self):
        """Test password reset with missing username"""
        with pytest.raises(ValidationError):
            PasswordResetRequest()
