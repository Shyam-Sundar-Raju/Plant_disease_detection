"""
Image Processing Utilities
Handles blur detection, heatmap generation, and image quality checks
"""
import cv2
import numpy as np
import tensorflow as tf
from typing import Tuple, Dict, Any, List, Optional
from app.core.config import settings
import base64
import logging
from pathlib import Path
import tempfile

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
            
            is_acceptable = bool(variance >= threshold)
            
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
    def generate_gradcam(
        model,
        image: np.ndarray,
        layer_name: Optional[str] = None
    ) -> Tuple[np.ndarray, Dict[str, Any]]:
        """
        Generate Grad-CAM heatmap overlay for the predicted class using TensorFlow GradientTape.
        
        Args:
            model: TensorFlow/Keras model
            image: Original image as numpy array (BGR format)
            layer_name: Name of convolutional layer to use (auto-detected if None)
        
        Returns:
            Tuple of (heatmap_overlay, severity_info)
        """
        try:
            # Get base model (MobileNetV2)
            base_model = model.layers[0]
            
            # Pick a sensible conv layer if not provided
            if layer_name is None:
                for layer in reversed(base_model.layers):
                    if isinstance(layer, tf.keras.layers.Conv2D):
                        layer_name = layer.name
                        break
                if layer_name is None:
                    # Fallback: any layer with 'conv' in its name
                    for layer in reversed(base_model.layers):
                        if "conv" in layer.name.lower():
                            layer_name = layer.name
                            break
            
            if layer_name is None:
                raise ValueError("No convolutional layer found in base model.")
            
            conv_layer = base_model.get_layer(layer_name)
            
            # Build a Grad-CAM graph rooted at base_model.input
            x = base_model.output
            for head_layer in model.layers[1:]:
                x = head_layer(x)
            preds = x
            
            grad_model = tf.keras.models.Model(
                inputs=base_model.input,
                outputs=[conv_layer.output, preds],
            )
            
            # Preprocess image for model
            img_resized = cv2.resize(image, (224, 224))
            img_rgb = cv2.cvtColor(img_resized, cv2.COLOR_BGR2RGB)
            img_array = img_rgb.astype(np.float32) / 255.0
            img_array = tf.keras.applications.mobilenet_v2.preprocess_input(img_array * 255.0)
            img_array = np.expand_dims(img_array, axis=0).astype(np.float32)
            
            # Compute gradients
            with tf.GradientTape() as tape:
                conv_outputs, predictions = grad_model(img_array)
                pred_index = tf.argmax(predictions[0])
                loss = predictions[:, pred_index]
            
            grads = tape.gradient(loss, conv_outputs)
            pooled_grads = tf.reduce_mean(grads, axis=(0, 1, 2))
            
            conv_outputs = conv_outputs[0]
            heatmap = tf.reduce_sum(pooled_grads * conv_outputs, axis=-1)
            
            # Convert to numpy and normalize
            heatmap = heatmap.numpy()
            heatmap = np.maximum(heatmap, 0)
            heatmap /= (np.max(heatmap) + 1e-8)
            
            # Resize to original image size
            heatmap = cv2.resize(heatmap, (image.shape[1], image.shape[0]))
            heatmap = np.uint8(255 * heatmap)
            
            # Apply colormap
            heatmap_colored = cv2.applyColorMap(heatmap, cv2.COLORMAP_JET)
            
            # Overlay on original image
            overlay = cv2.addWeighted(image, 0.6, heatmap_colored, 0.4, 0)
            
            # Estimate severity from heatmap
            severity_info = ImageProcessor.estimate_severity_from_heatmap(heatmap)
            
            return overlay, severity_info
            
        except Exception as e:
            logger.error(f"Error generating Grad-CAM heatmap: {e}")
            # Return original image with default severity on error
            return image, {"severity": "Unknown", "infected_ratio": 0.0}
    
    @staticmethod
    def estimate_severity_from_heatmap(heatmap: np.ndarray) -> Dict[str, Any]:
        """
        Estimate disease severity from heatmap intensity.
        
        Args:
            heatmap: Grayscale heatmap (0-255)
        
        Returns:
            Dictionary with severity level and infected ratio
        """
        try:
            # Threshold to isolate "hot" infected zones
            _, binary_map = cv2.threshold(heatmap, 200, 255, cv2.THRESH_BINARY)
            
            infected_area = np.sum(binary_map == 255)
            total_area = binary_map.shape[0] * binary_map.shape[1]
            
            ratio = infected_area / total_area
            
            if ratio < 0.10:
                severity = "Low"
            elif ratio < 0.40:
                severity = "Medium"
            else:
                severity = "High"
            
            return {
                "severity": severity,
                "infected_ratio": round(ratio * 100, 2)
            }
        except Exception as e:
            logger.error(f"Error estimating severity: {e}")
            return {"severity": "Unknown", "infected_ratio": 0.0}
    
    @staticmethod
    def generate_heatmap(
        image: np.ndarray,
        gradients: Optional[np.ndarray] = None
    ) -> np.ndarray:
        """
        DEPRECATED: Use generate_gradcam() instead.
        Legacy method kept for backward compatibility.
        """
        logger.warning("generate_heatmap() is deprecated. Use generate_gradcam() instead.")
        try:
            if gradients is None:
                # Return original image if no gradients provided
                return image
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
    def generate_heatmap_from_cam(image: np.ndarray, cam: np.ndarray) -> np.ndarray:
        """
        Overlay a Grad-CAM heatmap on the original image.

        Args:
            image: Original BGR image
            cam: 2D heatmap array normalized to [0, 1]

        Returns:
            Image with heatmap overlay
        """
        try:
            heatmap = cv2.resize(cam, (image.shape[1], image.shape[0]))
            heatmap = np.clip(heatmap, 0.0, 1.0)
            heatmap_uint8 = (heatmap * 255).astype(np.uint8)
            heatmap_colored = cv2.applyColorMap(heatmap_uint8, cv2.COLORMAP_JET)
            overlay = cv2.addWeighted(image, 0.6, heatmap_colored, 0.4, 0)
            return overlay
        except Exception as e:
            logger.error(f"Error generating heatmap from CAM: {e}")
            return image

    @staticmethod
    def boxes_from_heatmap(
        cam: np.ndarray,
        image_shape: Tuple[int, int, int],
        threshold: float = 0.4,
        min_area_ratio: float = 0.01
    ) -> List[Dict[str, Any]]:
        """
        Derive bounding boxes from a Grad-CAM heatmap.

        Args:
            cam: 2D heatmap array normalized to [0, 1]
            image_shape: Original image shape (H, W, C)
            threshold: Heatmap threshold for binarization
            min_area_ratio: Minimum box area ratio to keep

        Returns:
            List of bounding boxes with confidence
        """
        try:
            height, width = image_shape[:2]
            heatmap = cv2.resize(cam, (width, height))
            heatmap = np.clip(heatmap, 0.0, 1.0)
            _, binary = cv2.threshold(
                (heatmap * 255).astype(np.uint8),
                int(threshold * 255),
                255,
                cv2.THRESH_BINARY
            )

            contours, _ = cv2.findContours(binary, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
            min_area = (height * width) * min_area_ratio
            boxes = []

            for contour in contours:
                x, y, w, h = cv2.boundingRect(contour)
                area = w * h
                if area < min_area:
                    continue

                roi = heatmap[y:y + h, x:x + w]
                confidence = float(np.mean(roi)) if roi.size else 0.0

                boxes.append({
                    "x": int(x),
                    "y": int(y),
                    "width": int(w),
                    "height": int(h),
                    "confidence": confidence
                })

            return boxes
        except Exception as e:
            logger.error(f"Error deriving boxes from heatmap: {e}")
            return []
    
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
