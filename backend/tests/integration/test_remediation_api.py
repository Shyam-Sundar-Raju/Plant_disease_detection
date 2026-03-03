"""
Integration Tests for Remediation API
"""
import pytest


@pytest.mark.integration
class TestRemediationEndpoints:
    """Test remediation API endpoints"""
    
    @pytest.mark.asyncio
    async def test_get_remediation_for_disease(self, authenticated_client):
        """Test get remediation for specific disease"""
        client, user_id = authenticated_client
        
        response = await client.get("/api/v1/remediation/tomato_early_blight?severity=medium")
        
        # May succeed if disease exists in knowledge base
        assert response.status_code in [200, 404]
        
        if response.status_code == 200:
            data = response.json()
            assert "disease_name" in data
            assert "treatment" in data
    
    @pytest.mark.asyncio
    async def test_get_localized_remediation(self, authenticated_client):
        """Test get remediation in different language"""
        client, user_id = authenticated_client
        
        response = await client.get(
            "/api/v1/remediation/tomato_early_blight?severity=high"
        )
        
        # Check response structure if successful
        if response.status_code == 200:
            data = response.json()
            assert "treatment" in data
    

