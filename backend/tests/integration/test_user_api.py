"""
Integration Tests for User API
"""
import pytest
from datetime import datetime


@pytest.mark.integration
class TestUserProfile:
    """Test user profile endpoints"""
    
    @pytest.mark.asyncio
    async def test_get_current_user(self, authenticated_client, test_db):
        """Test get current user profile"""
        client, user_id = authenticated_client
        
        response = await client.get("/api/v1/user/profile")
        
        assert response.status_code == 200
        data = response.json()
        assert data["email"] == "test@example.com"
        assert "hashed_password" not in data
    
    @pytest.mark.asyncio
    async def test_update_profile(self, authenticated_client, test_db):
        """Test update user profile"""
        client, user_id = authenticated_client
        
        update_data = {
            "name": "Updated Name",
            "phone": "9876543210",
            "location": "New Delhi"
        }
        
        response = await client.patch("/api/v1/user/profile", json=update_data)
        
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "Updated Name"
        assert data["phone"] == "9876543210"
    
    @pytest.mark.asyncio
    async def test_change_language_preference(self, authenticated_client, test_db):
        """Test change language preference"""
        client, user_id = authenticated_client
        
        response = await client.patch("/api/v1/user/profile", json={
            "preferred_language": "hi"
        })
        
        assert response.status_code == 200
        data = response.json()
        assert data["preferred_language"] == "hi"
    
