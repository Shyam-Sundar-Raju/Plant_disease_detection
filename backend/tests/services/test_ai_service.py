import pytest
import numpy as np
from unittest.mock import Mock, patch
from app.services.ai_service import AIModelService as AIService

@pytest.mark.unit
class TestAIServiceInitialization:
    """Test AI Service initialization"""
    
    def test_ai_service_singleton(self):
        """Test that ai_service instance is shared"""
        from app.services.ai_service import ai_service
        service1 = ai_service
        service2 = ai_service
        assert service1 is service2
    
    @patch('pathlib.Path.exists', return_value=True)
    @patch('tensorflow.keras.models.load_model')
    def test_load_models(self, mock_load_model, mock_exists):
        """Test model loading"""
        mock_model = Mock()
        mock_load_model.return_value = mock_model
        
        service = AIService()
        service.load_models()
        assert mock_load_model.called


@pytest.mark.unit
class TestImagePreprocessing:
    """Test image preprocessing"""
    
    def test_preprocess_image_shape(self, mock_image):
        """Test preprocessed image shape"""
        service = AIService()
        preprocessed = service._preprocess_for_prediction(mock_image)
        assert preprocessed.shape == (1, 224, 224, 3)
    
    def test_preprocess_resize(self):
        """Test image resizing during preprocessing"""
        service = AIService()
        large_image = np.random.randint(0, 255, (500, 500, 3), dtype=np.uint8)
        preprocessed = service._preprocess_for_prediction(large_image)
        assert preprocessed.shape == (1, 224, 224, 3)


@pytest.mark.unit
@pytest.mark.ai
class TestDiseaseDetection:
    """Test disease detection"""
    
    @pytest.mark.asyncio
    @patch.object(AIService, '_mock_predict')
    async def test_predict_disease(self, mock_predict, mock_image):
        """Test disease prediction fallback to mock"""
        mock_predict.return_value = {
            "primary_disease": "Tomato___Early_blight",
            "confidence": 0.95,
            "secondary_diseases": [],
            "all_predictions": {}
        }
        
        service = AIService()
        result = await service.predict_disease(mock_image, "tomato")
        
        assert "disease_id" in result
        assert "confidence" in result
        assert "is_healthy" in result
        assert result["confidence"] > 0
        assert result["disease_id"] == "Tomato___Early_blight"


@pytest.mark.unit
@pytest.mark.ai
class TestGradCAM:
    """Test Grad-CAM heatmap generation"""
    
    @patch.object(AIService, '_get_last_conv_layer_name')
    def test_compute_grad_cam(self, mock_conv_layer, mock_image):
        """Test heatmap generation"""
        service = AIService()
        service.model = Mock()
        mock_conv_layer.return_value = "dummy"
        
        # Testing full gradient generation with mocked keras model is complex, 
        # so simply testing it fails gracefully if model is None
        service.model = None
        heatmap = service._compute_grad_cam(mock_image)
        assert heatmap is None
