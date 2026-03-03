import pytest
import os
from pathlib import Path
from unittest.mock import Mock, patch
from app.utils.file_handler import FileHandler

@pytest.mark.unit
class TestFileOperations:
    """Test file operations"""
    
    def test_ensure_upload_dir(self, tmp_path):
        """Test ensuring upload directories exist"""
        with patch('app.utils.file_handler.settings.UPLOAD_DIR', str(tmp_path / "uploads")):
            path = FileHandler.ensure_upload_dir()
            assert os.path.exists(path)
            assert os.path.exists(os.path.join(path, "images"))
            assert os.path.exists(os.path.join(path, "reports"))
            
    def test_generate_filename(self):
        """Test unique filename generation"""
        name1 = FileHandler.generate_filename("test.jpg", prefix="img_")
        name2 = FileHandler.generate_filename("test.jpg", prefix="img_")
        assert name1 != name2
        assert name1.startswith("img_")
        assert name1.endswith(".jpg")

    def test_get_file_url(self):
        """Test fetching file URL"""
        url = FileHandler.get_file_url("images/test.jpg")
        assert url == "/uploads/images/test.jpg"

    @pytest.mark.asyncio
    async def test_save_upload_file(self, tmp_path):
        """Test saving uploaded file"""
        mock_file = Mock()
        mock_file.filename = "test.jpg"
        mock_file.read = Mock(return_value=b"fake image data")

        # Mock aiofiles simply by patching its return, but since we are writing to disk
        # it's usually easier to mock write or just mock open. For simplicity, we just mock 
        # ensure_upload_dir and aiofiles methods
        from unittest.mock import mock_open
        with patch('app.utils.file_handler.settings.UPLOAD_DIR', str(tmp_path / "uploads")):
             with patch("aiofiles.threadpool.sync_open", mock_open()) as m_open:
                result = await FileHandler.save_upload_file(mock_file, "images")
                assert result.startswith("images/")
                assert result.endswith(".jpg")
                m_open.assert_called_once()
    
    @pytest.mark.asyncio
    async def test_save_image_from_base64(self, tmp_path):
         """Test saving from base64 string"""
         import base64
         mock_data = base64.b64encode(b"fake image data").decode('utf-8')
         data_url = f"data:image/jpeg;base64,{mock_data}"
         
         from unittest.mock import mock_open
         with patch('app.utils.file_handler.settings.UPLOAD_DIR', str(tmp_path / "uploads")):
             with patch("aiofiles.threadpool.sync_open", mock_open()) as m_open:
                result = await FileHandler.save_image_from_base64(data_url, "images", "img_")
                assert result.startswith("images/img_")
                assert result.endswith(".jpg")
                m_open.assert_called_once()
                
    @pytest.mark.asyncio
    async def test_delete_file(self, tmp_path):
        """Test file deletion"""
        test_dir = tmp_path / "uploads"
        test_dir.mkdir()
        test_file = test_dir / "test.jpg"
        test_file.write_text("test")

        with patch('app.utils.file_handler.settings.UPLOAD_DIR', str(test_dir)):
             assert test_file.exists()
             await FileHandler.delete_file("test.jpg")
             assert not test_file.exists()
