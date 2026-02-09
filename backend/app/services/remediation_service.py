"""
Remediation Service
Handles treatment recommendations and remediation logic
"""
from typing import Dict, Any, Optional
from pathlib import Path
import json
import logging

from motor.motor_asyncio import AsyncIOMotorDatabase
from app.utils.localization import Localizer

logger = logging.getLogger(__name__)


class RemediationService:
    """Service for disease remediation and treatment recommendations"""

    _JSON_KNOWLEDGE_BASE: Optional[Dict[str, Any]] = None

    @staticmethod
    def _load_json_knowledge_base() -> Dict[str, Any]:
        if RemediationService._JSON_KNOWLEDGE_BASE is not None:
            return RemediationService._JSON_KNOWLEDGE_BASE

        repo_root = Path(__file__).resolve().parents[3]
        candidate_paths = [
            repo_root / "backend" / "app" / "data" / "remediation.json",
        ]

        knowledge_base: Dict[str, Any] = {}
        for path in candidate_paths:
            if path.exists():
                try:
                    knowledge_base = json.loads(path.read_text(encoding="utf-8"))
                except (OSError, json.JSONDecodeError) as exc:
                    logger.warning("Failed to load remediation data from %s: %s", path, exc)
                    knowledge_base = {}
                break

        RemediationService._JSON_KNOWLEDGE_BASE = (
            knowledge_base if isinstance(knowledge_base, dict) else {}
        )
        return RemediationService._JSON_KNOWLEDGE_BASE

    @staticmethod
    def _get_json_knowledge(disease_id: str) -> Dict[str, Any]:
        knowledge_base = RemediationService._load_json_knowledge_base()
        if not knowledge_base:
            return {}

        if disease_id in knowledge_base:
            return knowledge_base[disease_id]

        disease_id_lower = disease_id.lower()
        for key, value in knowledge_base.items():
            if key.lower() == disease_id_lower:
                return value

        return {}

    @staticmethod
    def _localize_treatment(treatment_data: Dict[str, Any], language: str) -> Dict[str, Any]:
        localized_steps = []
        for step in treatment_data.get("steps", []) or []:
            localized_steps.append({
                "step_number": step.get("step_number"),
                "description": Localizer.get_localized_dict(step.get("description", {}), language),
                "icon": step.get("icon"),
                "duration": Localizer.get_localized_dict(step.get("duration", {}), language) if step.get("duration") else None,
                "safety_warning": Localizer.get_localized_dict(step.get("safety_warning", {}), language) if step.get("safety_warning") else None
            })

        return {
            "type": treatment_data.get("type"),
            "steps": localized_steps,
            "dosage": Localizer.get_localized_dict(treatment_data.get("dosage", {}), language),
            "frequency": Localizer.get_localized_dict(treatment_data.get("frequency", {}), language),
            "cost_estimate": treatment_data.get("cost_estimate"),
        }

    @staticmethod
    async def get_remediation_full(
        db: AsyncIOMotorDatabase,
        disease_id: str,
        severity: str,
        language: str = "en"
    ) -> Dict[str, Any]:
        """Get full remediation content with localization."""
        try:
            knowledge = await db.knowledge_base.find_one({"disease_id": disease_id})
            if not knowledge:
                knowledge = RemediationService._get_json_knowledge(disease_id)

            if not knowledge:
                raise ValueError(f"No knowledge base found for disease: {disease_id}")

            organic_treatment = RemediationService._localize_treatment(
                knowledge.get("organic_treatment") or {},
                language
            )
            chemical_treatment = RemediationService._localize_treatment(
                knowledge.get("chemical_treatment") or {},
                language
            )

            severity_guidance = knowledge.get("severity_guidance", {}).get(severity, {})
            guidance_text = Localizer.get_localized_dict(severity_guidance, language) if severity_guidance else None

            prevention_tips = knowledge.get("prevention_steps", {}).get(language, [])
            community_tips = knowledge.get("community_tips", {}).get(language, [])

            return {
                "disease_id": disease_id,
                "disease_name": Localizer.get_localized_dict(knowledge.get("name", {}), language),
                "description": Localizer.get_localized_dict(knowledge.get("description", {}), language),
                "severity": severity,
                "organic_treatment": organic_treatment,
                "chemical_treatment": chemical_treatment,
                "prevention_tips": prevention_tips,
                "severity_guidance": guidance_text,
                "community_tips": community_tips,
                "community_tips_verified": knowledge.get("community_tips", {}).get("verified"),
            }
        except Exception as e:
            logger.error(f"Error getting remediation: {e}")
            raise
    
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

            # Fall back to remediation.json
            if not knowledge:
                knowledge = RemediationService._get_json_knowledge(disease_id)
            
            if not knowledge:
                raise ValueError(f"No knowledge base found for disease: {disease_id}")
            
            # Get localized disease name
            disease_name = Localizer.get_localized_dict(knowledge.get("name", {}), language)
            
            # Get treatment based on type
            if treatment_type == "chemical":
                treatment_data = knowledge.get("chemical_treatment", {})
            else:
                treatment_data = knowledge.get("organic_treatment", {})

            localized_treatment = RemediationService._localize_treatment(treatment_data, language)
            
            # Get prevention tips
            prevention_tips = knowledge.get("prevention_steps", {}).get(language, [])
            
            # Get severity-specific guidance
            severity_guidance = knowledge.get("severity_guidance", {}).get(severity, {})
            guidance_text = Localizer.get_localized_dict(severity_guidance, language) if severity_guidance else None
            
            # Safety warnings
            safety_warnings = []
            for step in localized_treatment.get("steps", []):
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
                "treatment": localized_treatment,
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
        disease_id: str,
        language: str = "en"
    ) -> Dict[str, Any]:
        """Get guidance for healthy plants"""
        knowledge = RemediationService._get_json_knowledge(disease_id)
        if not knowledge:
            raise ValueError("No knowledge base found for healthy plant guidance")
        
        return {
            "disease_id": "healthy",
            "disease_name": Localizer.get_localized_dict(knowledge.get("name", {}), language),
            "message": Localizer.get_localized_dict(knowledge.get("description", {}), language),
            "prevention_tips": knowledge.get("prevention_steps", {}).get(language, []),
            "no_treatment_needed": True
        }


# Global service instance
remediation_service = RemediationService()
