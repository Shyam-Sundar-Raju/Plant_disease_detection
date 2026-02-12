"""
Localization and Translation Utilities
Handles multi-language support
"""
from typing import Dict, Any, Optional
from app.core.config import settings
import logging

logger = logging.getLogger(__name__)


class Localizer:
    """Handles localization and translation"""
    
    # Translation dictionary (in production, load from database or JSON files)
    TRANSLATIONS = {
        "en": {
            "app_name": "Crop Disease Detection",
            "welcome": "Welcome",
            "diagnosis_complete": "Diagnosis Complete",
            "treatment_plan": "Treatment Plan",
            "prevention_tips": "Prevention Tips",
            "healthy_plant": "Your plant is healthy!",
            "no_treatment_needed": "No treatment is required at this time.",
            "consult_expert": "Please consult an agricultural expert",
            "low_confidence": "Low confidence in diagnosis. Please retake the image or consult an expert.",
            
            # Notification Templates
            "notif.diagnosis_complete.title": "Diagnosis Complete",
            "notif.diagnosis_complete.message": "Your crop has been diagnosed with {disease_name}. View treatment recommendations.",
            "notif.treatment_update.title": "Treatment Update",
            "notif.treatment_update.message": "New treatment recommendations are available for your {crop_type}.",
            "notif.weather_alert.title": "Weather Alert",
            "notif.weather_alert.message": "Weather conditions may affect your crops. Check the latest recommendations.",
            "notif.system.title": "System Notification",
            "notif.system.message": "Important system update or information.",
            "notif.healthy_plant.title": "Good News!",
            "notif.healthy_plant.message": "Your {crop_type} plant is healthy! Keep up the good care.",
            "notif.severity_alert.title": "Severity Alert",
            "notif.severity_alert.message": "The disease severity is {severity_level}. Immediate action recommended.",
            "notif.low_confidence.title": "Unclear Diagnosis",
            "notif.low_confidence.message": "Diagnosis confidence is low. Consider retaking the image or consulting an expert.",
        },
        "hi": {  # Hindi
            "app_name": "फसल रोग का पता लगाना",
            "welcome": "स्वागत है",
            "diagnosis_complete": "निदान पूर्ण",
            "treatment_plan": "उपचार योजना",
            "prevention_tips": "रोकथाम के सुझाव",
            "healthy_plant": "आपका पौधा स्वस्थ है!",
            "no_treatment_needed": "इस समय किसी उपचार की आवश्यकता नहीं है।",
            "consult_expert": "कृपया कृषि विशेषज्ञ से परामर्श करें",
            "low_confidence": "निदान में कम विश्वास। कृपया छवि को फिर से लें या किसी विशेषज्ञ से परामर्श करें।",
            
            # Notification Templates
            "notif.diagnosis_complete.title": "निदान पूर्ण",
            "notif.diagnosis_complete.message": "आपकी फसल में {disease_name} का निदान किया गया है। उपचार की सिफारिशें देखें।",
            "notif.treatment_update.title": "उपचार अपडेट",
            "notif.treatment_update.message": "आपके {crop_type} के लिए नई उपचार सिफारिशें उपलब्ध हैं।",
            "notif.weather_alert.title": "मौसम चेतावनी",
            "notif.weather_alert.message": "मौसमी स्थितियां आपकी फसलों को प्रभावित कर सकती हैं। नवीनतम सिफारिशें जांचें।",
            "notif.system.title": "सिस्टम सूचना",
            "notif.system.message": "महत्वपूर्ण सिस्टम अपडेट या जानकारी।",
            "notif.healthy_plant.title": "अच्छी खबर!",
            "notif.healthy_plant.message": "आपका {crop_type} पौधा स्वस्थ है! अच्छी देखभाल जारी रखें।",
            "notif.severity_alert.title": "गंभीरता चेतावनी",
            "notif.severity_alert.message": "रोग की गंभीरता {severity_level} है। तत्काल कार्रवाई की सिफारिश।",
            "notif.low_confidence.title": "अस्पष्ट निदान",
            "notif.low_confidence.message": "निदान की विश्वसनीयता कम है। छवि को फिर से लेने या विशेषज्ञ से सलाह लेने पर विचार करें।",
        },
        "kn": {  # Kannada
            "app_name": "ಬೆಳೆ ರೋಗ ಪತ್ತೆ",
            "welcome": "ಸ್ವಾಗತ",
            "diagnosis_complete": "ರೋಗನಿರ್ಣಯ ಪೂರ್ಣಗೊಂಡಿದೆ",
            "treatment_plan": "ಚಿಕಿತ್ಸಾ ಯೋಜನೆ",
            "prevention_tips": "ತಡೆಗಟ್ಟುವ ಸಲಹೆಗಳು",
            "healthy_plant": "ನಿಮ್ಮ ಸಸ್ಯ ಆರೋಗ್ಯಕರವಾಗಿದೆ!",
            "no_treatment_needed": "ಈ ಸಮಯದಲ್ಲಿ ಯಾವುದೇ ಚಿಕಿತ್ಸೆ ಅಗತ್ಯವಿಲ್ಲ.",
            "consult_expert": "ದಯವಿಟ್ಟು ಕೃಷಿ ತಜ್ಞರನ್ನು ಸಂಪರ್ಕಿಸಿ",
            "low_confidence": "ರೋಗನಿರ್ಣಯದಲ್ಲಿ ಕಡಿಮೆ ವಿಶ್ವಾಸ. ದಯವಿಟ್ಟು ಚಿತ್ರವನ್ನು ಮರುಪಡೆಯಿರಿ ಅಥವಾ ತಜ್ಞರನ್ನು ಸಂಪರ್ಕಿಸಿ.",
            
            # Notification Templates
            "notif.diagnosis_complete.title": "ರೋಗನಿರ್ಣಯ ಪೂರ್ಣಗೊಂಡಿದೆ",
            "notif.diagnosis_complete.message": "ನಿಮ್ಮ ಬೆಳೆಗೆ {disease_name} ರೋಗನಿರ್ಣಯ ಆಗಿದೆ. ಚಿಕಿತ್ಸಾ ಶಿಫಾರಸುಗಳನ್ನು ವೀಕ್ಷಿಸಿ.",
            "notif.treatment_update.title": "ಚಿಕಿತ್ಸೆ ನವೀಕರಣ",
            "notif.treatment_update.message": "ನಿಮ್ಮ {crop_type} ಗಾಗಿ ಹೊಸ ಚಿಕಿತ್ಸಾ ಶಿಫಾರಸುಗಳು ಲಭ್ಯವಿದೆ.",
            "notif.weather_alert.title": "ಹವಾಮಾನ ಎಚ್ಚರಿಕೆ",
            "notif.weather_alert.message": "ಹವಾಮಾನ ಪರಿಸ್ಥಿತಿಗಳು ನಿಮ್ಮ ಬೆಳೆಗಳ ಮೇಲೆ ಪರಿಣಾಮ ಬೀರಬಹುದು. ಇತ್ತೀಚಿನ ಶಿಫಾರಸುಗಳನ್ನು ಪರಿಶೀಲಿಸಿ.",
            "notif.system.title": "ಸಿಸ್ಟಂ ಅಧಿಸೂಚನೆ",
            "notif.system.message": "ಪ್ರಮುಖ ಸಿಸ್ಟಂ ನವೀಕರಣ ಅಥವಾ ಮಾಹಿತಿ.",
            "notif.healthy_plant.title": "ಒಳ್ಳೆಯ ಸುದ್ದಿ!",
            "notif.healthy_plant.message": "ನಿಮ್ಮ {crop_type} ಸಸ್ಯ ಆರೋಗ್ಯಕರವಾಗಿದೆ! ಒಳ್ಳೆಯ ಆರೈಕೆ ಮುಂದುವರಿಸಿ.",
            "notif.severity_alert.title": "ತೀವ್ರತೆ ಎಚ್ಚರಿಕೆ",
            "notif.severity_alert.message": "ರೋಗದ ತೀವ್ರತೆ {severity_level} ಆಗಿದೆ. ತಕ್ಷಣ ಕ್ರಮ ಶಿಫಾರಸಿಸಲಾಗುತ್ತದೆ.",
            "notif.low_confidence.title": "ಅಸ್ಪಷ್ಟ ನಿರ್ಣಯ",
            "notif.low_confidence.message": "ನಿರ್ಣಯದ ವಿಶ್ವಾಸಾರ್ಹತೆ ಕಡಿಮೆ. ಚಿತ್ರವನ್ನು ಮರುಹೊಂದಿಸುವುದನ್ನು ಅಥವಾ ತಜ್ಞರನ್ನು ಸಂಪರ್ಕಿಸುವುದನ್ನು ಪರಿಗಣಿಸಿ.",
        },
        "ta": {  # Tamil
            "app_name": "பயிர் நோய் கண்டறிதல்",
            "welcome": "வரவேற்பு",
            "diagnosis_complete": "நோய் கண்டறிதல் முடிந்தது",
            "treatment_plan": "சிகிச்சை திட்டம்",
            "prevention_tips": "தடுப்பு குறிப்புகள்",
            "healthy_plant": "உங்கள் செடி ஆரோக்கியமாக உள்ளது!",
            "no_treatment_needed": "இந்த நேரத்தில் எந்த சிகிச்சையும் தேவையில்லை.",
            "consult_expert": "தயவுசெய்து விவசாய நிபுணரை அணுகவும்",
            "low_confidence": "நோய் கண்டறிதலில் குறைந்த நம்பிக்கை. படத்தை மீண்டும் எடுக்கவும் அல்லது நிபுணரை அணுகவும்.",
            
            # Notification Templates
            "notif.diagnosis_complete.title": "நோய் கண்டறிதல் முடிந்தது",
            "notif.diagnosis_complete.message": "உங்கள் பயிருக்கு {disease_name} நோய் கண்டறியப்பட்டுள்ளது. சிகிச்சை பரிந்துரைகளைப் பார்க்கவும்.",
            "notif.treatment_update.title": "சிகிச்சைத் தகவல்",
            "notif.treatment_update.message": "உங்கள் {crop_type}க்கு புதிய சிகிச்சை பரிந்துரைகள் கிடைத்துள்ளன.",
            "notif.weather_alert.title": "வானிலை எச்சரிக்கை",
            "notif.weather_alert.message": "வானிலை நிலைமைகள் உங்கள் பயிர்களை பாதிக்கலாம். சமீபத்திய பரிந்துரைகளைச் சரிபார்க்கவும்.",
            "notif.system.title": "கணினி அறிவிப்பு",
            "notif.system.message": "முக்கியமான கணினி மேம்பாடு அல்லது தகவல்.",
            "notif.healthy_plant.title": "நல்ல செய்தி!",
            "notif.healthy_plant.message": "உங்கள் {crop_type} செடி ஆரோக்கியமாக உள்ளது! நல்ல பராமரிப்பைத் தொடரவும்.",
            "notif.severity_alert.title": "தீவிரத்வ எச்சரிக்கை",
            "notif.severity_alert.message": "நோயின் தீவிரத்வம் {severity_level} ஆக உள்ளது. உடனடி நடவடிக்கை பரிந்துரைக்கப்படுகிறது.",
            "notif.low_confidence.title": "தெளிவற்ற நோய் கண்டறிதல்",
            "notif.low_confidence.message": "நோய் கண்டறிதலின் நம்பகத்தன்மை குறைவாக உள்ளது. படத்தை மீண்டும் எடுக்கவும் அல்லது நிபுணரை அணுகவும்.",
        },
        "te": {  # Telugu
            "app_name": "పంట వ్యాధి గుర్తింపు",
            "welcome": "స్వాగతం",
            "diagnosis_complete": "రోగ నిర్ధారణ పూర్తయింది",
            "treatment_plan": "చికిత్స పథకం",
            "prevention_tips": "నివారణ చిట్కాలు",
            "healthy_plant": "మీ మొక్క ఆరోగ్యంగా ఉంది!",
            "no_treatment_needed": "ఈ సమయంలో ఎటువంటి చికిత్స అవసరం లేదు.",
            "consult_expert": "దయచేసి వ్యవసాయ నిపుణుడిని సంప్రదించండి",
            "low_confidence": "రోగ నిర్ధారణలో తక్కువ నమ్మకం. చిత్రాన్ని మళ్లీ తీయండి లేదా నిపుణుడిని సంప్రదించండి.",
            
            # Notification Templates
            "notif.diagnosis_complete.title": "రోగ నిర్ధారణ పూర్తయింది",
            "notif.diagnosis_complete.message": "మీ పంటకు {disease_name} నిర్ధారించబడింది. చికిత్స సిఫార్సులను చూడండి.",
            "notif.treatment_update.title": "చికిత్స నవీకరణ",
            "notif.treatment_update.message": "మీ {crop_type} కోసం కొత్త చికిత్స సిఫార్సులు అందుబాటులో ఉన్నాయి.",
            "notif.weather_alert.title": "వాతావరణ హెచ్చరిక",
            "notif.weather_alert.message": "వాతావరణ పరిస్థితులు మీ పంటలను ప్రభావితం చేయవచ్చు. తాజా సిఫార్సులను చూడండి.",
            "notif.system.title": "సిస్టమ్ నోటిఫికేషన్",
            "notif.system.message": "ముఖ్యమైన సిస్టమ్ అప్డేట్ లేదా సమాచారం.",
            "notif.healthy_plant.title": "మంచి వార్తలు!",
            "notif.healthy_plant.message": "మీ {crop_type} మొక్క ఆరోగ్యంగా ఉంది! మంచి సంరక్షణను కొనసాగించండి.",
            "notif.severity_alert.title": "తీవ్రత హెచ్చరిక",
            "notif.severity_alert.message": "వ్యాధి తీవ్రత {severity_level}గా ఉంది. తక్షణ చర్య సిఫార్సు చేయబడుతుంది.",
            "notif.low_confidence.title": "అస్పష్టమైన నిర్ధారణ",
            "notif.low_confidence.message": "నిర్ధారణలో నమ్మకం తక్కువగా ఉంది. చిత్రాన్ని మళ్లీ తీయడం లేదా నిపుణుడిని సంప్రదించడం పరిగణించండి.",
        },
    }
    
    @classmethod
    def translate_notification_template(cls, template_key: str, language: str = "en", **kwargs) -> str:
        """
        Get translated notification template with parameters
        
        Args:
            template_key: Notification template key (e.g., 'notif.diagnosis_complete.title')
            language: Target language code
            **kwargs: Template parameters for formatting
        
        Returns:
            Formatted translated string
        """
        return cls.translate(template_key, language, **kwargs)
    
    @classmethod
    def get_notification_content(cls, notification_type: str, content_type: str, language: str = "en", **kwargs) -> str:
        """
        Get notification content by type and content type
        
        Args:
            notification_type: Type of notification (e.g., 'diagnosis_complete')
            content_type: 'title' or 'message'
            language: Target language code
            **kwargs: Template parameters
        
        Returns:
            Localized content
        """
        template_key = f"notif.{notification_type}.{content_type}"
        return cls.translate_notification_template(template_key, language, **kwargs)
    
    @classmethod
    def translate(cls, key: str, language: str = "en", **kwargs) -> str:
        """
        Get translated string for a key
        
        Args:
            key: Translation key
            language: Target language code
            **kwargs: Format parameters
        
        Returns:
            Translated string
        """
        # Check if language is supported
        if language not in settings.SUPPORTED_LANGUAGES:
            logger.warning(f"Language {language} not supported, falling back to English")
            language = settings.DEFAULT_LANGUAGE
        
        # Get translation
        translations = cls.TRANSLATIONS.get(language, cls.TRANSLATIONS["en"])
        text = translations.get(key, cls.TRANSLATIONS["en"].get(key, key))
        
        # Format with parameters if provided
        if kwargs:
            try:
                text = text.format(**kwargs)
            except KeyError as e:
                logger.error(f"Missing format parameter: {e}")
        
        return text
    
    @classmethod
    def get_localized_dict(cls, data: Dict[str, str], language: str = "en") -> str:
        """
        Extract localized value from a multi-language dictionary
        Supports both direct translations and i18n key lookups
        
        Args:
            data: Dictionary with language codes as keys OR i18n key string
            language: Preferred language
        
        Returns:
            Localized string
        """
        if not data:
            return ""
        
        # Check if it's a single i18n key instead of dictionary
        if isinstance(data, str):
            # It's an i18n key, translate it
            return cls.translate(data, language)
        
        # Check if it's i18n key format
        if len(data) == 1 and '__i18n_key__' in data:
            i18n_key = data['__i18n_key__']
            return cls.translate(i18n_key, language)
            
        # Standard multi-language dictionary format
        # Try preferred language
        if language in data:
            return data[language]
        
        # Fall back to default language
        if settings.DEFAULT_LANGUAGE in data:
            return data[settings.DEFAULT_LANGUAGE]
        
        # Return first available
        return next(iter(data.values()), "")
    
    @classmethod
    def localize_remediation(cls, treatment_data: Dict[str, Any], language: str = "en") -> Dict[str, Any]:
        """
        Localize treatment/remediation data
        
        Args:
            treatment_data: Treatment data with multi-language fields
            language: Target language
        
        Returns:
            Localized treatment data
        """
        localized = {}
        
        for key, value in treatment_data.items():
            if isinstance(value, dict) and language in value:
                localized[key] = value[language]
            elif isinstance(value, dict) and settings.DEFAULT_LANGUAGE in value:
                localized[key] = value[settings.DEFAULT_LANGUAGE]
            elif isinstance(value, list):
                localized[key] = [cls.get_localized_dict(item, language) if isinstance(item, dict) else item for item in value]
            else:
                localized[key] = value
        
        return localized
    
    @classmethod
    def detect_language_from_header(cls, accept_language: Optional[str]) -> str:
        """
        Detect language from Accept-Language header
        
        Args:
            accept_language: Accept-Language header value
        
        Returns:
            Detected language code
        """
        if not accept_language:
            return settings.DEFAULT_LANGUAGE
        
        # Parse Accept-Language header (e.g., "en-US,en;q=0.9,hi;q=0.8")
        languages = []
        for lang in accept_language.split(','):
            if ';' in lang:
                code, quality = lang.split(';')
                try:
                    q = float(quality.split('=')[1])
                except:
                    q = 1.0
            else:
                code = lang
                q = 1.0
            
            # Extract base language code (e.g., "en" from "en-US")
            base_code = code.strip().split('-')[0].lower()
            languages.append((base_code, q))
        
        # Sort by quality
        languages.sort(key=lambda x: x[1], reverse=True)
        
        # Find first supported language
        for lang_code, _ in languages:
            if lang_code in settings.SUPPORTED_LANGUAGES:
                return lang_code
        
        return settings.DEFAULT_LANGUAGE
    
    @classmethod
    def get_simple_vocabulary(cls, text: str, language: str = "en") -> str:
        """
        Convert technical terms to simple farmer-friendly words
        
        Args:
            text: Technical text
            language: Target language
        
        Returns:
            Simplified text
        """
        # Technical to simple mappings (expandable)
        SIMPLIFICATIONS = {
            "en": {
                "pathogen": "disease-causing organism",
                "fungicide": "anti-fungal medicine",
                "pesticide": "pest killer",
                "chlorosis": "yellowing of leaves",
                "necrosis": "dead tissue",
                "lesion": "infected spot",
            }
        }
        
        simplifications = SIMPLIFICATIONS.get(language, {})
        
        for technical, simple in simplifications.items():
            text = text.replace(technical, simple)
        
        return text


# Helper functions for easy access
def t(key: str, language: str = "en", **kwargs) -> str:
    """Shorthand for translate"""
    return Localizer.translate(key, language, **kwargs)


def get_language_from_request(accept_language: Optional[str], user_preference: Optional[str] = None) -> str:
    """
    Get language from request, prioritizing user preference
    
    Args:
        accept_language: Accept-Language header
        user_preference: User's saved language preference
    
    Returns:
        Language code to use
    """
    if user_preference and user_preference in settings.SUPPORTED_LANGUAGES:
        return user_preference
    
    return Localizer.detect_language_from_header(accept_language)
