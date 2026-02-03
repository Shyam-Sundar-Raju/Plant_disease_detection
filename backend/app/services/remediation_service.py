"""
Remediation Service
Handles treatment recommendations and remediation logic
"""
from typing import Dict, Any, List, Optional
from motor.motor_asyncio import AsyncIOMotorDatabase
from app.models.schemas import TreatmentType, SeverityLevel
from app.utils.localization import Localizer
import logging

logger = logging.getLogger(__name__)


class RemediationService:
    """Service for disease remediation and treatment recommendations"""
    

    KNOWLEDGE_BASE = {
        "tomato_early_blight": {
            "disease_id": "tomato_early_blight",
            "name": {
                "en": "Early Blight",
                "hi": "प्रारंभिक झुलसा",
                "kn": "ಆರಂಭಿಕ ಬ್ಲೈಟ್",
                "ta": "ஆரம்ப வாட்டம்",
                "te": "ప్రారంభ బ్లైట్"
            },
            "description": {
                "en": "A fungal disease affecting tomato leaves and stems",
                "hi": "टमाटर की पत्तियों और तनों को प्रभावित करने वाली फफूंद रोग"
            },
            "organic_treatment": {
                "type": "organic",
                "steps": [
                    {
                        "step_number": 1,
                        "description": {
                            "en": "Remove and destroy infected leaves immediately",
                            "hi": "संक्रमित पत्तियों को तुरंत हटाएं और नष्ट करें"
                        },
                        "icon": "remove",
                        "safety_warning": {
                            "en": "Wear gloves while handling infected plants",
                            "hi": "संक्रमित पौधों को संभालते समय दस्ताने पहनें"
                        }
                    },
                    {
                        "step_number": 2,
                        "description": {
                            "en": "Apply neem oil spray (5ml per liter of water)",
                            "hi": "नीम का तेल स्प्रे करें (प्रति लीटर पानी में 5ml)"
                        },
                        "icon": "spray",
                        "duration": {
                            "en": "Every 7 days",
                            "hi": "हर 7 दिन में"
                        }
                    },
                    {
                        "step_number": 3,
                        "description": {
                            "en": "Improve air circulation around plants",
                            "hi": "पौधों के चारों ओर हवा का संचार बेहतर करें"
                        },
                        "icon": "air"
                    }
                ],
                "dosage": {
                    "en": "5ml neem oil per liter of water",
                    "hi": "प्रति लीटर पानी में 5ml नीम का तेल"
                },
                "frequency": {
                    "en": "Once every 7 days for 3 weeks",
                    "hi": "3 सप्ताह के लिए हर 7 दिन में एक बार"
                },
                "cost_estimate": "low"
            },
            "chemical_treatment": {
                "type": "chemical",
                "steps": [
                    {
                        "step_number": 1,
                        "description": {
                            "en": "Apply Chlorothalonil-based fungicide (2g per liter)",
                            "hi": "क्लोरोथैलोनिल आधारित फफूंदनाशक लगाएं (प्रति लीटर 2g)"
                        },
                        "icon": "spray",
                        "safety_warning": {
                            "en": "Use protective equipment: mask, gloves, and goggles",
                            "hi": "सुरक्षा उपकरण उपयोग करें: मास्क, दस्ताने और चश्मा"
                        }
                    },
                    {
                        "step_number": 2,
                        "description": {
                            "en": "Spray during early morning or late evening",
                            "hi": "सुबह जल्दी या देर शाम को स्प्रे करें"
                        },
                        "icon": "time"
                    },
                    {
                        "step_number": 3,
                        "description": {
                            "en": "Do not harvest for 7 days after application",
                            "hi": "आवेदन के 7 दिन बाद तक फसल न काटें"
                        },
                        "icon": "wait",
                        "safety_warning": {
                            "en": "Keep away from water sources",
                            "hi": "पानी के स्रोतों से दूर रखें"
                        }
                    }
                ],
                "dosage": {
                    "en": "2g per liter of water",
                    "hi": "प्रति लीटर पानी में 2g"
                },
                "frequency": {
                    "en": "Once every 10 days, maximum 3 applications",
                    "hi": "हर 10 दिन में एक बार, अधिकतम 3 अनुप्रयोग"
                },
                "cost_estimate": "medium"
            },
            "prevention_steps": {
                "en": [
                    "Practice crop rotation with non-solanaceous crops",
                    "Ensure proper spacing between plants (18-24 inches)",
                    "Water at the base of plants, avoid wetting foliage",
                    "Apply mulch to prevent soil splash",
                    "Remove plant debris at season end"
                ],
                "hi": [
                    "गैर-सोलानेसियस फसलों के साथ फसल चक्र का अभ्यास करें",
                    "पौधों के बीच उचित दूरी सुनिश्चित करें (18-24 इंच)",
                    "पौधों के आधार पर पानी दें, पत्तियों को गीला करने से बचें",
                    "मिट्टी के छींटे को रोकने के लिए मल्च लगाएं",
                    "सीज़न के अंत में पौधे के मलबे को हटा दें"
                ]
            },
            "severity_guidance": {
                "low": {
                    "en": "Apply organic treatment only. Monitor daily.",
                    "hi": "केवल जैविक उपचार लगाएं। दैनिक निगरानी करें।"
                },
                "medium": {
                    "en": "Start with organic treatment. If no improvement in 7 days, switch to chemical.",
                    "hi": "जैविक उपचार से शुरू करें। 7 दिनों में सुधार न होने पर रासायनिक पर स्विच करें।"
                },
                "high": {
                    "en": "Immediate chemical intervention required. Remove heavily infected plants.",
                    "hi": "तत्काल रासायनिक हस्तक्षेप की आवश्यकता है। अत्यधिक संक्रमित पौधों को हटा दें।"
                }
            }
        },
        "tomato_healthy": {
            "disease_id": "tomato_healthy",
            "name": {
                "en": "Healthy Plant",
                "hi": "स्वस्थ पौधा",
                "kn": "ಆರೋಗ್ಯಕರ ಸಸ್ಯ",
                "ta": "ஆரோக்கியமான தாவரம்",
                "te": "ఆరోగ్యకరమైన మొక్క"
            },
            "description": {
                "en": "Your plant appears healthy with no signs of disease",
                "hi": "आपका पौधा स्वस्थ दिखाई देता है और बीमारी के कोई लक्षण नहीं हैं"
            },
            "prevention_steps": {
                "en": [
                    "Continue regular watering and fertilization",
                    "Monitor plants weekly for any changes",
                    "Maintain good air circulation",
                    "Practice preventive spraying during monsoon"
                ],
                "hi": [
                    "नियमित पानी देना और उर्वरक देना जारी रखें",
                    "किसी भी परिवर्तन के लिए साप्ताहिक पौधों की निगरानी करें",
                    "अच्छा हवा संचार बनाए रखें",
                    "मानसून के दौरान निवारक छिड़काव का अभ्यास करें"
                ]
            }
        }
    }
    
    @staticmethod
    async def get_remediation(
        db: AsyncIOMotorDatabase,
        disease_id: str,
        severity: str,
        treatment_type: str = "organic",
        language: str = "en"
    ) -> Dict[str, Any]:
        """
        Get remediation recommendations
        
        Args:
            db: Database connection
            disease_id: Disease identifier
            severity: Disease severity level
            treatment_type: Type of treatment (organic/chemical)
            language: Language for recommendations
        
        Returns:
            Localized remediation data
        """
        try:
            # First try to get from database
            knowledge = await db.knowledge_base.find_one({"disease_id": disease_id})
            
            # Fall back to mock data
            if not knowledge:
                knowledge = RemediationService.KNOWLEDGE_BASE.get(disease_id, {})
            
            if not knowledge:
                raise ValueError(f"No knowledge base found for disease: {disease_id}")
            
            # Get localized disease name
            disease_name = Localizer.get_localized_dict(knowledge.get("name", {}), language)
            
            # Get treatment based on type
            if treatment_type == "chemical":
                treatment_data = knowledge.get("chemical_treatment", {})
            else:
                treatment_data = knowledge.get("organic_treatment", {})
            
            # Localize treatment steps
            localized_steps = []
            for step in treatment_data.get("steps", []):
                localized_step = {
                    "step_number": step["step_number"],
                    "description": Localizer.get_localized_dict(step.get("description", {}), language),
                    "icon": step.get("icon"),
                    "duration": Localizer.get_localized_dict(step.get("duration", {}), language) if step.get("duration") else None,
                    "safety_warning": Localizer.get_localized_dict(step.get("safety_warning", {}), language) if step.get("safety_warning") else None
                }
                localized_steps.append(localized_step)
            
            # Get prevention tips
            prevention_tips = knowledge.get("prevention_steps", {}).get(language, [])
            
            # Get severity-specific guidance
            severity_guidance = knowledge.get("severity_guidance", {}).get(severity, {})
            guidance_text = Localizer.get_localized_dict(severity_guidance, language) if severity_guidance else None
            
            # Safety warnings
            safety_warnings = []
            for step in localized_steps:
                if step.get("safety_warning"):
                    safety_warnings.append(step["safety_warning"])
            
            # Check if expert consultation needed
            expert_consultation_required = (
                severity in ["high", "critical"] or
                treatment_type == "chemical"
            )
            
            return {
                "disease_id": disease_id,
                "disease_name": disease_name,
                "severity": severity,
                "treatment": {
                    "type": treatment_type,
                    "steps": localized_steps,
                    "dosage": Localizer.get_localized_dict(treatment_data.get("dosage", {}), language),
                    "frequency": Localizer.get_localized_dict(treatment_data.get("frequency", {}), language),
                    "cost_estimate": treatment_data.get("cost_estimate"),
                },
                "prevention_tips": prevention_tips,
                "safety_warnings": safety_warnings,
                "severity_guidance": guidance_text,
                "expert_consultation_required": expert_consultation_required
            }
            
        except Exception as e:
            logger.error(f"Error getting remediation: {e}")
            raise
    
    @staticmethod
    async def get_healthy_plant_guidance(
        language: str = "en"
    ) -> Dict[str, Any]:
        """Get guidance for healthy plants"""
        knowledge = RemediationService.KNOWLEDGE_BASE.get("tomato_healthy", {})
        
        return {
            "disease_id": "healthy",
            "disease_name": Localizer.get_localized_dict(knowledge.get("name", {}), language),
            "message": Localizer.get_localized_dict(knowledge.get("description", {}), language),
            "prevention_tips": knowledge.get("prevention_steps", {}).get(language, []),
            "no_treatment_needed": True
        }


# Global service instance
remediation_service = RemediationService()
