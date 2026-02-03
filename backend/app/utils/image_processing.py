"""
Image Processing Utilities
Handles blur detection, heatmap generation, and image quality checks
"""
import cv2
import numpy as np
from typing import Tuple, Dict, Any, List, Optional
from app.core.config import settings
import base64
import logging

logger = logging.getLogger(__name__)


class ImageProcessor:
    """Image processing utilities for crop disease detection"""
    
    @staticmethod
    def decode_base64_image(base64_string: str) -> np.ndarray:
        """Decode base64 image string to numpy array"""
        try:
            # Remove data URL prefix if present
            if ',' in base64_string:
                base64_string = base64_string.split(',')[1]
            
            img_bytes = base64.b64decode(base64_string)
            nparr = np.frombuffer(img_bytes, np.uint8)
            img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            
            if img is None:
                raise ValueError("Failed to decode image")
            
            return img
        except Exception as e:
            logger.error(f"Error decoding base64 image: {e}")
            raise ValueError("Invalid image data")
    
    @staticmethod
    def encode_image_to_base64(image: np.ndarray, format: str = '.jpg') -> str:
        """Encode numpy array image to base64 string"""
        try:
            _, buffer = cv2.imencode(format, image)
            img_base64 = base64.b64encode(buffer).decode('utf-8')
            return f"data:image/jpeg;base64,{img_base64}"
        except Exception as e:
            logger.error(f"Error encoding image to base64: {e}")
            raise
    
    @staticmethod
    def check_blur(image: np.ndarray, threshold: int = None) -> Dict[str, Any]:
        """
        Check if image is blurry using Laplacian variance method
        
        Args:
            image: Input image as numpy array
            threshold: Blur detection threshold (default from settings)
        
        Returns:
            Dictionary with blur check results
        """
        if threshold is None:
            threshold = settings.BLUR_THRESHOLD
        
        try:
            # Convert to grayscale if needed
            if len(image.shape) == 3:
                gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
            else:
                gray = image
            
            # Calculate Laplacian variance
            laplacian = cv2.Laplacian(gray, cv2.CV_64F)
            variance = laplacian.var()
            
            is_acceptable = variance >= threshold
            
            return {
                "is_acceptable": is_acceptable,
                "blur_score": float(variance),
                "blur_threshold": threshold,
                "message": "Image quality is good" if is_acceptable else "Image is too blurry. Please retake with a stable camera."
            }
        except Exception as e:
            logger.error(f"Error in blur detection: {e}")
            raise
    
    @staticmethod
    def generate_heatmap(
        image: np.ndarray,
        gradients: Optional[np.ndarray] = None
    ) -> np.ndarray:
        """
        Generate Grad-CAM style heatmap overlay
        
        Args:
            image: Original image
            gradients: Gradient activations from model (if None, generates mock heatmap)
        
        Returns:
            Image with heatmap overlay
        """
        try:
            if gradients is None:
                # Mock heatmap generation for demonstration
                # In production, this should use actual model gradients
                height, width = image.shape[:2]
                
                # Create a simple heatmap focusing on center (mock)
                y, x = np.ogrid[:height, :width]
                center_y, center_x = height // 2, width // 2
                
                # Gaussian-like distribution
                heatmap = np.exp(-((x - center_x)**2 + (y - center_y)**2) / (2 * (min(height, width) / 4)**2))
                heatmap = (heatmap * 255).astype(np.uint8)
            else:
                # Use actual gradients
                heatmap = cv2.resize(gradients, (image.shape[1], image.shape[0]))
                heatmap = (heatmap * 255).astype(np.uint8)
            
            # Apply colormap
            heatmap_colored = cv2.applyColorMap(heatmap, cv2.COLORMAP_JET)
            
            # Overlay on original image
            overlay = cv2.addWeighted(image, 0.6, heatmap_colored, 0.4, 0)
            
            return overlay
        except Exception as e:
            logger.error(f"Error generating heatmap: {e}")
            return image
    
    @staticmethod
    def detect_bounding_boxes(
        image: np.ndarray,
        detection_results: Optional[List[Dict]] = None
    ) -> Tuple[np.ndarray, List[Dict[str, Any]]]:
        """
        Draw bounding boxes on infected areas
        
        Args:
            image: Input image
            detection_results: Detection results with coordinates
        
        Returns:
            Tuple of (annotated image, bounding box list)
        """
        try:
            annotated_image = image.copy()
            bounding_boxes = []
            
            if detection_results is None:
                # Mock detection for demonstration
                height, width = image.shape[:2]
                
                # Create a sample bounding box (in production, use actual model output)
                box = {
                    "x": int(width * 0.3),
                    "y": int(height * 0.3),
                    "width": int(width * 0.4),
                    "height": int(height * 0.4),
                    "confidence": 0.92
                }
                detection_results = [box]
            
            for detection in detection_results:
                x = detection["x"]
                y = detection["y"]
                w = detection["width"]
                h = detection["height"]
                confidence = detection.get("confidence", 0.0)
                
                # Draw rectangle
                cv2.rectangle(
                    annotated_image,
                    (x, y),
                    (x + w, y + h),
                    (0, 255, 0) if confidence > 0.8 else (0, 255, 255),
                    2
                )
                
                # Draw confidence score
                label = f"{confidence:.2%}"
                cv2.putText(
                    annotated_image,
                    label,
                    (x, y - 10),
                    cv2.FONT_HERSHEY_SIMPLEX,
                    0.5,
                    (0, 255, 0),
                    2
                )
                
                bounding_boxes.append({
                    "x": x,
                    "y": y,
                    "width": w,
                    "height": h,
                    "confidence": confidence
                })
            
            return annotated_image, bounding_boxes
        except Exception as e:
            logger.error(f"Error detecting bounding boxes: {e}")
            return image, []
    
    @staticmethod
    def calculate_severity(
        image: np.ndarray,
        bounding_boxes: List[Dict[str, Any]]
    ) -> str:
        """
        Calculate disease severity based on affected area
        
        Args:
            image: Input image
            bounding_boxes: List of detected bounding boxes
        
        Returns:
            Severity level string
        """
        try:
            if not bounding_boxes:
                return "healthy"
            
            height, width = image.shape[:2]
            total_area = height * width
            
            # Calculate total affected area
            affected_area = sum(box["width"] * box["height"] for box in bounding_boxes)
            
            # Calculate percentage
            affected_percentage = affected_area / total_area
            
            # Determine severity
            if affected_percentage < settings.SEVERITY_LOW_THRESHOLD:
                return "low"
            elif affected_percentage < settings.SEVERITY_MEDIUM_THRESHOLD:
                return "medium"
            else:
                return "high"
        except Exception as e:
            logger.error(f"Error calculating severity: {e}")
            return "medium"
    
    @staticmethod
    def preprocess_image_for_model(image: np.ndarray, target_size: Tuple[int, int] = (224, 224)) -> np.ndarray:
        """
        Preprocess image for model inference
        
        Args:
            image: Input image
            target_size: Target size for model input
        
        Returns:
            Preprocessed image
        """
        try:
            # Resize
            resized = cv2.resize(image, target_size)
            
            # Convert BGR to RGB
            rgb = cv2.cvtColor(resized, cv2.COLOR_BGR2RGB)
            
            # Normalize to [0, 1]
            normalized = rgb.astype(np.float32) / 255.0
            
            # Add batch dimension
            batched = np.expand_dims(normalized, axis=0)
            
            return batched
        except Exception as e:
            logger.error(f"Error preprocessing image: {e}")
            raise
    
    @staticmethod
    def extract_frames_from_video(video_path: str, num_frames: int = 3) -> List[np.ndarray]:
        """
        Extract key frames from video for multi-angle analysis
        
        Args:
            video_path: Path to video file
            num_frames: Number of frames to extract
        
        Returns:
            List of extracted frames
        """
        try:
            cap = cv2.VideoCapture(video_path)
            total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
            
            # Calculate frame indices to extract
            indices = np.linspace(0, total_frames - 1, num_frames, dtype=int)
            
            frames = []
            for idx in indices:
                cap.set(cv2.CAP_PROP_POS_FRAMES, idx)
                ret, frame = cap.read()
                if ret:
                    frames.append(frame)
            
            cap.release()
            return frames
        except Exception as e:
            logger.error(f"Error extracting frames from video: {e}")
            return []
