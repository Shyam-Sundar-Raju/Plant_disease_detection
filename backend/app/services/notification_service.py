"""
Notification Service
Handles notification creation and management with i18n support
"""
from typing import Dict, Any, List, Union
from datetime import datetime
from motor.motor_asyncio import AsyncIOMotorDatabase
from app.models.schemas import NotificationType
from app.utils.localization import Localizer
from app.utils.notification_templates import NotificationTemplateManager
from bson import ObjectId
import logging

logger = logging.getLogger(__name__)


class NotificationService:
    """Service for managing user notifications"""
    
    @staticmethod
    async def create_notification(
        db: AsyncIOMotorDatabase,
        user_id: str,
        notification_type: NotificationType,
        title: Union[Dict[str, str], str],
        message: Union[Dict[str, str], str],
        data: Dict[str, Any] = None,
        priority: str = "normal"
    ) -> str:
        """
        Create a new notification
        Support both legacy multi-language dict format and new i18n key format
        
        Args:
            db: Database connection
            user_id: User ID
            notification_type: Type of notification
            title: Multi-language title dict, i18n key, or direct text
            message: Multi-language message dict, i18n key, or direct text
            data: Additional data
        
        Returns:
            Notification ID
        """
        try:
            # Normalize title and message to consistent format
            if isinstance(title, str):
                if title.startswith("notif."):
                    # It's an i18n key
                    title = {"__i18n_key__": title, "__params__": data.get("template_params", {}) if data else {}}
                else:
                    # Direct text - convert to default language dict
                    title = {"en": title}
            
            if isinstance(message, str):
                if message.startswith("notif."):
                    # It's an i18n key
                    message = {"__i18n_key__": message, "__params__": data.get("template_params", {}) if data else {}}
                else:
                    # Direct text - convert to default language dict  
                    message = {"en": message}
            
            notification = {
                "user_id": user_id,
                "type": notification_type,
                "notification_type": notification_type,
                "title": title,
                "message": message,
                "data": data or {},
                "priority": priority,
                "is_read": False,
                "created_at": datetime.utcnow()
            }
            
            result = await db.notifications.insert_one(notification)
            return str(result.inserted_id)
            
        except Exception as e:
            logger.error(f"Error creating notification: {e}")
            raise
    
    @staticmethod
    async def get_user_notifications(
        db: AsyncIOMotorDatabase,
        user_id: str,
        language: str = "en",
        limit: int = 50,
        unread_only: bool = False
    ) -> List[Dict[str, Any]]:
        """
        Get user notifications with proper localization
        
        Args:
            db: Database connection
            user_id: User ID
            language: Preferred language
            limit: Maximum number of notifications
            unread_only: Return only unread notifications
        
        Returns:
            List of localized notifications
        """
        try:
            query = {"user_id": user_id}
            
            if unread_only:
                query["is_read"] = False
            
            cursor = db.notifications.find(query).sort("created_at", -1).limit(limit)
            notifications = await cursor.to_list(length=limit)
            
            # Localize notifications
            localized_notifications = []
            for notif in notifications:
                # Translate title and message using new template manager
                notification_data = {
                    "title": notif.get("title", {}),
                    "message": notif.get("message", {})
                }
                
                translated_content = NotificationTemplateManager.translate_notification_data(
                    notification_data, language
                )
                
                localized_notifications.append({
                    "_id": str(notif["_id"]),
                    "user_id": notif["user_id"],
                    "notification_type": notif.get("notification_type") or notif.get("type"),
                    "priority": notif.get("priority", "normal"),
                    "type": notif.get("type"),
                    "title": translated_content.get("title", ""),
                    "message": translated_content.get("message", ""),
                    "data": notif.get("data", {}),
                    "is_read": notif.get("is_read", False),
                    "created_at": notif["created_at"]
                })
            
            return localized_notifications
            
        except Exception as e:
            logger.error(f"Error getting notifications: {e}")
            raise
            
            return localized_notifications
            
        except Exception as e:
            logger.error(f"Error getting notifications: {e}")
            raise
    
    @staticmethod
    async def mark_as_read(
        db: AsyncIOMotorDatabase,
        notification_id: str,
        user_id: str
    ) -> bool:
        """
        Mark notification as read
        
        Args:
            db: Database connection
            notification_id: Notification ID
            user_id: User ID
        
        Returns:
            Success status
        """
        try:
            result = await db.notifications.update_one(
                {
                    "_id": ObjectId(notification_id),
                    "user_id": user_id
                },
                {
                    "$set": {"is_read": True}
                }
            )
            
            return result.modified_count > 0
            
        except Exception as e:
            logger.error(f"Error marking notification as read: {e}")
            return False
    
    @staticmethod
    async def mark_all_as_read(
        db: AsyncIOMotorDatabase,
        user_id: str
    ) -> int:
        """
        Mark all notifications as read for a user
        
        Args:
            db: Database connection
            user_id: User ID
        
        Returns:
            Number of notifications marked
        """
        try:
            result = await db.notifications.update_many(
                {
                    "user_id": user_id,
                    "is_read": False
                },
                {
                    "$set": {"is_read": True}
                }
            )
            
            return result.modified_count
            
        except Exception as e:
            logger.error(f"Error marking all notifications as read: {e}")
            return 0
    
    @staticmethod
    async def get_unread_count(
        db: AsyncIOMotorDatabase,
        user_id: str
    ) -> int:
        """
        Get count of unread notifications
        
        Args:
            db: Database connection
            user_id: User ID
        
        Returns:
            Unread count
        """
        try:
            count = await db.notifications.count_documents({
                "user_id": user_id,
                "is_read": False
            })
            
            return count
            
        except Exception as e:
            logger.error(f"Error getting unread count: {e}")
            return 0
    
    @staticmethod
    async def create_diagnosis_notification(
        db: AsyncIOMotorDatabase,
        user_id: str,
        diagnosis_id: str,
        disease_name: str,
        crop_type: str = None,
        severity: str = None,
        confidence: float = None
    ):
        """Create notification for completed diagnosis using i18n templates"""
        try:
            # Use template manager to create notification data with i18n keys
            notification_data = NotificationTemplateManager.create_diagnosis_notification_data(
                diagnosis_id=diagnosis_id,
                disease_name=disease_name,
                crop_type=crop_type,
                severity=severity,
                confidence=confidence
            )
            
            # Create notification with i18n key format
            await NotificationService.create_notification(
                db=db,
                user_id=user_id,
                notification_type=NotificationType.DIAGNOSIS_COMPLETE,
                title=notification_data["title"],
                message=notification_data["message"],
                data={
                    "diagnosis_id": diagnosis_id,
                    "disease_name": disease_name,
                    "crop_type": crop_type,
                    "severity": severity,
                    "confidence": confidence
                }
            )
            
        except Exception as e:
            logger.error(f"Error creating diagnosis notification: {e}")
            raise
    
    @staticmethod
    async def create_treatment_update_notification(
        db: AsyncIOMotorDatabase,
        user_id: str,
        crop_type: str = None,
        treatment_type: str = None
    ):
        """Create treatment update notification"""
        try:
            notification_data = NotificationTemplateManager.create_treatment_update_notification_data(
                crop_type=crop_type,
                treatment_type=treatment_type
            )
            
            await NotificationService.create_notification(
                db=db,
                user_id=user_id,
                notification_type=NotificationType.TREATMENT_UPDATE,
                title=notification_data["title"],
                message=notification_data["message"],
                data={
                    "crop_type": crop_type,
                    "treatment_type": treatment_type
                }
            )
            
        except Exception as e:
            logger.error(f"Error creating treatment update notification: {e}")
            raise
    
    @staticmethod
    async def create_weather_alert_notification(
        db: AsyncIOMotorDatabase,
        user_id: str,
        weather_condition: str = None,
        location: str = None
    ):
        """Create weather alert notification"""
        try:
            notification_data = NotificationTemplateManager.create_weather_alert_notification_data(
                weather_condition=weather_condition,
                location=location
            )
            
            await NotificationService.create_notification(
                db=db,
                user_id=user_id,
                notification_type=NotificationType.WEATHER_ALERT,
                title=notification_data["title"],
                message=notification_data["message"],
                data={
                    "weather_condition": weather_condition,
                    "location": location
                }
            )
            
        except Exception as e:
            logger.error(f"Error creating weather alert notification: {e}")
            raise
    
    @staticmethod
    async def create_system_notification(
        db: AsyncIOMotorDatabase,
        user_id: str,
        system_message: str = None
    ):
        """Create system notification"""
        try:
            notification_data = NotificationTemplateManager.create_system_notification_data(
                system_message=system_message
            )
            
            await NotificationService.create_notification(
                db=db,
                user_id=user_id,
                notification_type=NotificationType.SYSTEM,
                title=notification_data["title"],
                message=notification_data["message"],
                data={
                    "system_message": system_message
                }
            )
            
        except Exception as e:
            logger.error(f"Error creating system notification: {e}")
            raise


# Global service instance
notification_service = NotificationService()
