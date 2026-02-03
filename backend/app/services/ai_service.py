"""
AI Model Service
Handles AI model inference for disease detection
"""
import numpy as np
from typing import Dict, Any, List, Tuple, Optional
from app.core.config import settings
from app.utils.image_processing import ImageProcessor
import logging

logger = logging.getLogger(__name__)


class AIModelService:
    """
    AI Model service for crop disease detection
    In production, this would load actual TensorFlow/PyTorch models
    """
    
    # Mock disease database
    DISEASE_DATABASE = {
        "tomato": {
            "tomato_early_blight": {
                "name": "Early Blight",
                "disease_id": "tomato_early_blight",
                "confidence_range": (0.75, 0.95)
            },
            "tomato_late_blight": {
                "name": "Late Blight",
                "disease_id": "tomato_late_blight",
                "confidence_range": (0.70, 0.92)
            },
            "tomato_leaf_mold": {
                "name": "Leaf Mold",
                "disease_id": "tomato_leaf_mold",
                "confidence_range": (0.65, 0.88)
            },
            "tomato_healthy": {
                "name": "Healthy",
                "disease_id": "tomato_healthy",
                "confidence_range": (0.80, 0.98)
            }
        },
        "rice": {
            "rice_blast": {
                "name": "Rice Blast",
                "disease_id": "rice_blast",
                "confidence_range": (0.72, 0.94)
            },
            "rice_brown_spot": {
                "name": "Brown Spot",
                "disease_id": "rice_brown_spot",
                "confidence_range": (0.68, 0.90)
            },
            "rice_healthy": {
                "name": "Healthy",
                "disease_id": "rice_healthy",
                "confidence_range": (0.82, 0.96)
            }
        }
    }
    
    def __init__(self):
        """Initialize AI model service"""
        self.models = {}
        # In production: self.load_models()
    
    def load_models(self):
        """Load TensorFlow Lite models for each crop"""
        # In production, load actual models:
        # self.models['tomato'] = tf.lite.Interpreter(model_path=f"{settings.MODEL_PATH}/tomato_model.tflite")
        # self.models['tomato'].allocate_tensors()
        pass
    
    async def predict_disease(
        self,
        image: np.ndarray,
        crop_type: str
    ) -> Dict[str, Any]:
        """
        Predict disease from image
        
        Args:
            image: Input image as numpy array
            crop_type: Type of crop
        
        Returns:
            Prediction results
        """
        try:
            # Preprocess image
            processed_image = ImageProcessor.preprocess_image_for_model(image)
            
            # Mock prediction (in production, use actual model)
            predictions = await self._mock_predict(crop_type)
            
            # Get top prediction
            disease_id = predictions['primary_disease']
            confidence = predictions['confidence']
            
            # Check if multiple diseases detected
            secondary_diseases = predictions.get('secondary_diseases', [])
            
            # Determine if healthy
            is_healthy = 'healthy' in disease_id.lower()
            
            # Generate bounding boxes
            if not is_healthy:
                annotated_image, bounding_boxes = ImageProcessor.detect_bounding_boxes(image)
                severity = ImageProcessor.calculate_severity(image, bounding_boxes)
            else:
                bounding_boxes = []
                severity = "healthy"
                annotated_image = image
            
            # Generate heatmap
            heatmap_image = ImageProcessor.generate_heatmap(image)
            
            return {
                "disease_id": disease_id,
                "disease_name": self._get_disease_name(crop_type, disease_id),
                "confidence": confidence,
                "severity": severity,
                "is_healthy": is_healthy,
                "bounding_boxes": bounding_boxes,
                "secondary_diagnoses": secondary_diseases,
                "annotated_image": annotated_image,
                "heatmap_image": heatmap_image,
                "all_predictions": predictions.get('all_predictions', {})
            }
            
        except Exception as e:
            logger.error(f"Error in disease prediction: {e}")
            raise
    
    async def _mock_predict(self, crop_type: str) -> Dict[str, Any]:
        """
        Mock prediction for demonstration
        Replace with actual model inference in production
        """
        import random
        
        crop_diseases = self.DISEASE_DATABASE.get(crop_type, self.DISEASE_DATABASE['tomato'])
        
        # Randomly select a disease
        disease_key = random.choice(list(crop_diseases.keys()))
        disease_info = crop_diseases[disease_key]
        
        # Generate confidence score
        min_conf, max_conf = disease_info['confidence_range']
        confidence = random.uniform(min_conf, max_conf)
        
        # Generate secondary diseases if confidence is high enough
        secondary_diseases = []
        if confidence > 0.70 and not disease_info['disease_id'].endswith('healthy'):
            other_diseases = [d for d in crop_diseases.keys() if d != disease_key]
            if other_diseases and random.random() > 0.7:
                secondary_key = random.choice(other_diseases)
                secondary_diseases.append({
                    "disease_id": crop_diseases[secondary_key]['disease_id'],
                    "disease_name": crop_diseases[secondary_key]['name'],
                    "confidence": random.uniform(0.40, 0.65)
                })
        
        # All predictions
        all_predictions = {
            disease_info['disease_id']: confidence
        }
        
        return {
            "primary_disease": disease_info['disease_id'],
            "confidence": confidence,
            "secondary_diseases": secondary_diseases,
            "all_predictions": all_predictions
        }
    
    def _get_disease_name(self, crop_type: str, disease_id: str) -> str:
        """Get disease name from ID"""
        crop_diseases = self.DISEASE_DATABASE.get(crop_type, {})
        
        for disease_key, disease_info in crop_diseases.items():
            if disease_info['disease_id'] == disease_id:
                return disease_info['name']
        
        return disease_id
    
    async def predict_from_video_frames(
        self,
        frames: List[np.ndarray],
        crop_type: str
    ) -> Dict[str, Any]:
        """
        Predict disease from multiple video frames using majority voting
        
        Args:
            frames: List of frames from video
            crop_type: Type of crop
        
        Returns:
            Aggregated prediction results
        """
        try:
            predictions = []
            
            # Predict for each frame
            for frame in frames:
                result = await self.predict_disease(frame, crop_type)
                predictions.append(result)
            
            # Majority voting
            disease_counts = {}
            for pred in predictions:
                disease_id = pred['disease_id']
                disease_counts[disease_id] = disease_counts.get(disease_id, 0) + 1
            
            # Get most common disease
            majority_disease = max(disease_counts, key=disease_counts.get)
            
            # Find prediction with highest confidence for that disease
            best_prediction = max(
                [p for p in predictions if p['disease_id'] == majority_disease],
                key=lambda x: x['confidence']
            )
            
            return best_prediction
            
        except Exception as e:
            logger.error(f"Error in video frame prediction: {e}")
            raise
    
    def check_confidence_threshold(self, confidence: float) -> bool:
        """Check if confidence meets threshold"""
        return confidence >= settings.CONFIDENCE_THRESHOLD


# Global service instance
ai_service = AIModelService()
