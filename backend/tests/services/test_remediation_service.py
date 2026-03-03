import pytest
from unittest.mock import AsyncMock
from app.services.remediation_service import RemediationService

@pytest.mark.unit
class TestRemediationService:
    """Test remediation service"""
    
    @pytest.mark.asyncio
    async def test_get_healthy_plant_guidance(self):
        """Test getting guidance for healthy plant"""
        result = await RemediationService.get_healthy_plant_guidance("tomato_healthy", "en")
        assert result is not None
        assert "no_treatment_needed" in result
        assert result["no_treatment_needed"] is True
        assert "prevent" in result.get("message", "").lower() or "health" in result.get("message", "").lower()

    @pytest.mark.asyncio
    async def test_get_remediation_fallback(self):
        """Test fallback to mock knowledge base"""
        mock_db = AsyncMock()
        mock_db.knowledge_base.find_one.return_value = None
        
        result = await RemediationService.get_remediation(
            mock_db, 
            "tomato_early_blight", 
            "medium", 
            "organic", 
            "en"
        )
        
        assert result is not None
        assert result["disease_id"] == "tomato_early_blight"
        assert result["severity"] == "medium"
        assert "treatment" in result
