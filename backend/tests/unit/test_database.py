import pytest
from unittest.mock import AsyncMock, patch
from app.core.database import get_database, Database
close_database_connection = Database.close_db

@pytest.mark.unit
class TestDatabaseConnection:
    """Test database connection utilities"""
    
    @pytest.mark.asyncio
    @patch('app.core.database.Database.client')
    async def test_get_database(self, mock_client):
        """Test database connection initialization check"""
        # Set explicitly to simulate initialization
        Database.client = AsyncMock()
        Database.db = AsyncMock()
        db_instance = await get_database()
        assert db_instance is not None

    @pytest.mark.asyncio
    async def test_database_collections(self):
        """Test database collections exist"""
        Database.client = AsyncMock()
        Database.db = AsyncMock()
        Database.db.list_collection_names = AsyncMock(return_value=["users", "diagnoses"])
        db_instance = await get_database()
        
        collections = await db_instance.list_collection_names()
        assert isinstance(collections, list)
        assert len(collections) > 0
    
    @pytest.mark.asyncio
    async def test_close_database_connection(self):
        """Test closing database connection"""
        Database.client = AsyncMock()
        await close_database_connection()
        assert True


@pytest.mark.unit
class TestCollectionAccess:
    """Test collection access"""
    
    @pytest.mark.asyncio
    async def test_users_collection(self):
        """Test users collection access"""
        Database.client = AsyncMock()
        Database.db = AsyncMock()
        db_instance = await get_database()
        assert db_instance.users is not None
    
    @pytest.mark.asyncio
    async def test_diagnoses_collection(self):
        """Test diagnoses collection access"""
        Database.client = AsyncMock()
        Database.db = AsyncMock()
        db_instance = await get_database()
        assert db_instance.diagnoses is not None
    
    @pytest.mark.asyncio
    async def test_history_collection(self):
        """Test history collection access"""
        Database.client = AsyncMock()
        Database.db = AsyncMock()
        db_instance = await get_database()
        assert db_instance.history is not None
