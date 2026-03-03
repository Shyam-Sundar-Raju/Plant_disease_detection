"""
Unit Tests for Notification Service
"""
import pytest
from datetime import datetime
from app.services.notification_service import NotificationService
from bson import ObjectId


@pytest.mark.unit
class TestNotificationService:
    """Test notification service"""
    
    @pytest.mark.asyncio
    async def test_create_notification(self, test_db):
        """Test create notification"""
        user_id = str(ObjectId())
        
        notification_id = await NotificationService.create_notification(
            db=test_db,
            user_id=user_id,
            notification_type="info",
            title={"en": "Test Notification"},
            message={"en": "This is a test"}
        )
        
        assert notification_id is not None
        
        # Verify in DB
        notification = await test_db.notifications.find_one({"_id": ObjectId(notification_id)})
        assert notification is not None
        assert notification["title"]["en"] == "Test Notification"
        assert notification["user_id"] == user_id
        assert notification["is_read"] is False
    
    @pytest.mark.asyncio
    async def test_get_user_notifications(self, test_db):
        """Test get user notifications"""
        user_id = str(ObjectId())
        
        # Create notifications
        await NotificationService.create_notification(test_db, user_id, "info", {"en": "Title 1"}, {"en":"Message 1"})
        await NotificationService.create_notification(test_db, user_id, "info", {"en": "Title 2"}, {"en":"Message 2"})
        
        notifications = await NotificationService.get_user_notifications(test_db, user_id)
        
        assert len(notifications) >= 2
    
    @pytest.mark.asyncio
    async def test_mark_as_read(self, test_db):
        """Test mark notification as read"""
        user_id = str(ObjectId())
        
        notification_id = await NotificationService.create_notification(
            test_db, user_id, "info", {"en": "Test"}, {"en": "Test message"}
        )
        
        await NotificationService.mark_as_read(test_db, notification_id, user_id)
        
        # Verify marked as read
        updated = await test_db.notifications.find_one({"_id": ObjectId(notification_id)})
        assert updated["is_read"] is True
    
    @pytest.mark.asyncio
    async def test_mark_all_as_read(self, test_db):
        """Test mark all notifications as read"""
        user_id = str(ObjectId())
        
        # Create multiple notifications
        await NotificationService.create_notification(test_db, user_id, "info", {"en": "Title 1"}, {"en":"Message 1"})
        await NotificationService.create_notification(test_db, user_id, "info", {"en": "Title 2"}, {"en":"Message 2"})
        
        await NotificationService.mark_all_as_read(test_db, user_id)
        
        # Verify all marked as read
        unread = await test_db.notifications.count_documents({
            "user_id": user_id,
            "is_read": False
        })
        assert unread == 0
    
    @pytest.mark.asyncio
    async def test_delete_notification(self, test_db):
        """Test delete notification"""
        user_id = str(ObjectId())
        
        notification_id = await NotificationService.create_notification(
            test_db, user_id, "info", {"en": "Test"}, {"en": "Test message"}
        )
        
        await NotificationService.delete_notification(test_db, notification_id, user_id)
        
        # Verify deleted
        deleted = await test_db.notifications.find_one({"_id": ObjectId(notification_id)})
        assert deleted is None
    
    @pytest.mark.asyncio
    async def test_get_unread_count(self, test_db):
        """Test get unread notification count"""
        user_id = str(ObjectId())
        
        # Create notifications
        await NotificationService.create_notification(test_db, user_id, "info", {"en": "Title 1"}, {"en": "Message 1"})
        await NotificationService.create_notification(test_db, user_id, "info", {"en": "Title 2"}, {"en": "Message 2"})
        
        count = await NotificationService.get_unread_count(test_db, user_id)
        
        assert count >= 2


@pytest.mark.unit
class TestNotificationTypes:
    """Test different notification types"""
    
    @pytest.mark.asyncio
    async def test_diagnosis_notification(self, test_db):
        """Test diagnosis completion notification"""
        user_id = str(ObjectId())
        
        notification_id = await NotificationService.create_notification(
            db=test_db,
            user_id=user_id,
            notification_type="diagnosis",
            title={"en": "Diagnosis Complete"},
            message={"en": "Your diagnosis is ready"}
        )
        
        notification = await test_db.notifications.find_one({"_id": ObjectId(notification_id)})
        assert notification["type"] == "diagnosis"
    
    @pytest.mark.asyncio
    async def test_alert_notification(self, test_db):
        """Test alert notification"""
        user_id = str(ObjectId())
        
        notification_id = await NotificationService.create_notification(
            db=test_db,
            user_id=user_id,
            notification_type="alert",
            title={"en": "Disease Alert"},
            message={"en": "New disease detected in your area"}
        )
        
        notification = await test_db.notifications.find_one({"_id": ObjectId(notification_id)})
        assert notification["type"] == "alert"
