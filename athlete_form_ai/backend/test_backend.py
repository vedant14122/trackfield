#!/usr/bin/env python3
"""
Test script for backend components
"""

import sys
import os
sys.path.append(os.path.dirname(__file__))

from app.pose.mediapipe_runner import extract_2d_keypoints
from app.pose.videopose_runner import convert_to_3d
from app.pose.kalman_filter import smooth_keypoints_3d
from app.gemini.model_builder import get_personalized_model
from app.gemini.feedback_generator import compare_to_model

def test_pipeline():
    """Test the complete pose processing pipeline"""
    
    # Mock user profile
    user_profile = {
        "height": 175,
        "gender": "male",
        "sport": "sprint",
        "experience_level": "intermediate"
    }
    
    # Mock motion type
    motion_type = "sprint"
    
    print("Testing pose processing pipeline...")
    
    try:
        # Test model builder
        print("1. Testing model builder...")
        model = get_personalized_model(user_profile, motion_type)
        print(f"   ✓ Model created: {model}")
        
        # Test with mock 2D keypoints (since we don't have a video file)
        print("2. Testing keypoint conversion...")
        mock_2d = np.random.rand(30, 33, 2)  # 30 frames, 33 keypoints, 2D
        keypoints_3d = convert_to_3d(mock_2d)
        print(f"   ✓ 2D to 3D conversion: {keypoints_3d.shape}")
        
        # Test Kalman filtering
        print("3. Testing Kalman filtering...")
        smoothed_3d = smooth_keypoints_3d(keypoints_3d)
        print(f"   ✓ Smoothing applied: {smoothed_3d.shape}")
        
        # Test feedback generation
        print("4. Testing feedback generation...")
        feedback = compare_to_model(smoothed_3d, model)
        print(f"   ✓ Feedback generated: {len(feedback)} items")
        for item in feedback[:3]:  # Show first 3 feedback items
            print(f"     - {item}")
        
        print("\n✅ All tests passed!")
        return True
        
    except Exception as e:
        print(f"\n❌ Test failed: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    import numpy as np
    test_pipeline() 