"""
Test script to verify Grad-CAM heatmap generation
"""
import sys
sys.path.insert(0, 'app')

import cv2
import numpy as np
from pathlib import Path
from app.utils.image_processing import ImageProcessor
from app.services.ai_service import ai_service

def test_gradcam():
    print("=" * 60)
    print("Testing Real Grad-CAM Heatmap Generation")
    print("=" * 60)
    
    # Load the model
    print("\n1. Loading AI model...")
    ai_service.load_models()
    
    if not ai_service.model_loaded:
        print("❌ Model not loaded. Cannot test Grad-CAM.")
        return False
    
    print("✓ Model loaded successfully")
    
    # Find a test image
    test_image_path = Path("../Model/test_samples/0a8a68ee-f587-4dea-beec-79d02e7d3fa4___RS_Early.B 8461.JPG")
    
    if not test_image_path.exists():
        print(f"❌ Test image not found at: {test_image_path}")
        return False
    
    print(f"\n2. Loading test image: {test_image_path.name}")
    image = cv2.imread(str(test_image_path))
    
    if image is None:
        print("❌ Failed to load image")
        return False
    
    print(f"✓ Image loaded: {image.shape}")
    
    # Test Grad-CAM generation
    print("\n3. Generating Grad-CAM heatmap...")
    try:
        heatmap_overlay, severity_info = ImageProcessor.generate_gradcam(
            ai_service.model,
            image
        )
        
        print("✓ Grad-CAM generated successfully!")
        print(f"   - Severity: {severity_info['severity']}")
        print(f"   - Infected Ratio: {severity_info['infected_ratio']}%")
        print(f"   - Heatmap shape: {heatmap_overlay.shape}")
        
        # Save the heatmap for visual inspection
        output_path = "test_gradcam_output.jpg"
        cv2.imwrite(output_path, heatmap_overlay)
        print(f"\n✓ Heatmap saved to: {output_path}")
        
        return True
        
    except Exception as e:
        print(f"❌ Grad-CAM generation failed: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = test_gradcam()
    
    print("\n" + "=" * 60)
    if success:
        print("✅ TEST PASSED: Real Grad-CAM is working!")
    else:
        print("❌ TEST FAILED: Check errors above")
    print("=" * 60)
