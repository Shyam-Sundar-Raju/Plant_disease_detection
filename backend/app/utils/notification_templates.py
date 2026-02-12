"""
Notification Template Manager
Handles i18n-based notification templates
"""
from typing import Dict, Any, Union
from app.models.schemas import NotificationType
from app.utils.localization import Localizer
import logging

logger = logging.getLogger(__name__)


class NotificationTemplateManager:
    """Manages notification templates with i18n support"""
    
    # Template mapping for different notification types
    TEMPLATE_MAPPING = {
        NotificationType.DIAGNOSIS_COMPLETE: "diagnosis_complete",
        NotificationType.TREATMENT_UPDATE: "treatment_update",
        NotificationType.WEATHER_ALERT: "weather_alert",
        NotificationType.SYSTEM: "system",
    }
    
    @classmethod
    def create_i18n_notification_data(
        cls,
        notification_type: NotificationType,
        title_key: str = None,
        message_key: str = None,
        template_params: Dict[str, Any] = None
    ) -> Dict[str, Dict[str, str]]:
        """
        Create notification data with i18n keys stored for later translation
        
        Args:
            notification_type: Type of notification
            title_key: Custom title key (optional, defaults to type-based key)
            message_key: Custom message key (optional, defaults to type-based key)
            template_params: Parameters to store for later formatting
        
        Returns:
            Dictionary with title and message containing i18n key references
        """
        template_name = cls.TEMPLATE_MAPPING.get(notification_type, "system")
        
        # Use provided keys or default to template-based keys
        title_key = title_key or f"notif.{template_name}.title"
        message_key = message_key or f"notif.{template_name}.message"
        
        # Store i18n keys for later translation
        return {
            "title": {"__i18n_key__": title_key, "__params__": template_params or {}},
            "message": {"__i18n_key__": message_key, "__params__": template_params or {}}
        }
    
    @classmethod
    def translate_notification_data(
        cls,
        notification_data: Dict[str, Dict[str, str]],
        language: str = "en"
    ) -> Dict[str, str]:
        """
        Translate notification data from i18n keys to actual text
        
        Args:
            notification_data: Notification data with i18n keys
            language: Target language code
        
        Returns:
            Dictionary with translated title and message
        """
        result = {}
        
        for field in ["title", "message"]:
            field_data = notification_data.get(field, {})
            
            if isinstance(field_data, dict) and "__i18n_key__" in field_data:
                # It's an i18n key format
                i18n_key = field_data["__i18n_key__"]
                params = field_data.get("__params__", {})
                
                # Translate with parameters
                result[field] = Localizer.translate_notification_template(
                    i18n_key, language, **params
                )
            elif isinstance(field_data, dict):
                # Standard multi-language dictionary
                result[field] = Localizer.get_localized_dict(field_data, language)
            elif isinstance(field_data, str):
                # Direct text or i18n key
                if field_data.startswith("notif."):
                    result[field] = Localizer.translate(field_data, language)
                else:
                    result[field] = field_data
            else:
                result[field] = str(field_data) if field_data else ""
        
        return result
    
    @classmethod
    def create_diagnosis_notification_data(
        cls,
        diagnosis_id: str,
        disease_name: str,
        crop_type: str = None,
        severity: str = None,
        confidence: float = None
    ) -> Dict[str, Dict[str, str]]:
        """
        Create diagnosis notification with appropriate template based on conditions
        
        Args:
            diagnosis_id: Diagnosis ID
            disease_name: Disease name
            crop_type: Crop type
            severity: Disease severity
            confidence: Diagnosis confidence
        
        Returns:
            Notification data with i18n keys
        """
        template_params = {
            "disease_name": disease_name,
            "crop_type": crop_type or "crop",
            "severity_level": severity or "medium"
        }
        
        # Determine template based on conditions
        if disease_name.lower() in ["healthy", "no_disease"]:
            return cls.create_i18n_notification_data(
                NotificationType.DIAGNOSIS_COMPLETE,
                title_key="notif.healthy_plant.title",
                message_key="notif.healthy_plant.message",
                template_params=template_params
            )
        elif confidence and confidence < 0.5:
            return cls.create_i18n_notification_data(
                NotificationType.DIAGNOSIS_COMPLETE,
                title_key="notif.low_confidence.title",
                message_key="notif.low_confidence.message",
                template_params=template_params
            )
        elif severity and severity.lower() in ["high", "critical"]:
            return cls.create_i18n_notification_data(
                NotificationType.DIAGNOSIS_COMPLETE,
                title_key="notif.severity_alert.title",
                message_key="notif.severity_alert.message",
                template_params=template_params
            )
        else:
            # Standard diagnosis notification
            return cls.create_i18n_notification_data(
                NotificationType.DIAGNOSIS_COMPLETE,
                template_params=template_params
            )
    
    @classmethod
    def create_treatment_update_notification_data(
        cls,
        crop_type: str = None,
        treatment_type: str = None
    ) -> Dict[str, Dict[str, str]]:
        """Create treatment update notification data"""
        template_params = {
            "crop_type": crop_type or "crop",
            "treatment_type": treatment_type or "treatment"
        }
        
        return cls.create_i18n_notification_data(
            NotificationType.TREATMENT_UPDATE,
            template_params=template_params
        )
    
    @classmethod
    def create_weather_alert_notification_data(
        cls,
        weather_condition: str = None,
        location: str = None
    ) -> Dict[str, Dict[str, str]]:
        """Create weather alert notification data"""
        template_params = {
            "weather_condition": weather_condition or "weather changes",
            "location": location or "your area"
        }
        
        return cls.create_i18n_notification_data(
            NotificationType.WEATHER_ALERT,
            template_params=template_params
        )
    
    @classmethod
    def create_system_notification_data(
        cls,
        system_message: str = None
    ) -> Dict[str, Dict[str, str]]:
        """Create system notification data"""
        template_params = {
            "system_message": system_message or "system update"
        }
        
        return cls.create_i18n_notification_data(
            NotificationType.SYSTEM,
            template_params=template_params
        )


# Global instance
notification_template_manager = NotificationTemplateManager()