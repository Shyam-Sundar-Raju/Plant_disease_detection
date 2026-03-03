import pytest
from unittest.mock import Mock, patch
from io import BytesIO
import datetime
from app.utils.pdf_generator import PDFReportGenerator as PDFGenerator

@pytest.mark.unit
class TestPDFGeneration:
    """Test PDF generation"""
    
    def test_create_diagnosis_report(self):
        """Test diagnosis report PDF generation"""
        diagnosis_data = {
            "id": "test_id_123",
            "crop_type": "Tomato",
            "disease_name": "Early Blight",
            "confidence": 0.92,
            "severity": "medium",
            "image_url": "/uploads/test/image.jpg",
            "heatmap_url": None,
            "created_at": datetime.datetime.utcnow()
        }
        
        remediation_data = {
             "description": "It's a disease",
             "severity_guidance": "Medium severity"
        }
        
        # Patch the local path resolver to prevent filesystem errors during tests
        with patch('app.utils.pdf_generator.PDFReportGenerator._resolve_local_path', return_value=None):
            pdf_buffer = PDFGenerator.generate_diagnosis_report(
                diagnosis_data=diagnosis_data,
                remediation_data=remediation_data
            )
            
            assert isinstance(pdf_buffer, BytesIO)
            assert len(pdf_buffer.getvalue()) > 0
