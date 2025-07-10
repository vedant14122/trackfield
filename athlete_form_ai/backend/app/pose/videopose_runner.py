import torch
import numpy as np
<<<<<<< Updated upstream
import os
import sys

# Add the VideoPose3D repo to Python path
sys.path.append(os.path.abspath("models"))

from common.model import TemporalModel
from common.generators import UnchunkedGenerator

# Load model once and cache
_model = None
def load_model():
    global _model
    if _model is not None:
        return _model

    model = TemporalModel(
        num_joints_in=17,
        in_features=2,
        num_joints_out=17,
        filter_widths=[3, 3, 3, 3, 3],
        causal=False,
        dropout=0.25,
        channels=1024,
        dense=False
    )

    checkpoint_path = "models/checkpoint/pretrained_h36m_detectron_coco.bin"
    checkpoint = torch.load(checkpoint_path, map_location=torch.device("cpu"))
    model.load_state_dict(checkpoint["model_state_dict"])
    model.eval()
    _model = model
    return _model

def convert_to_3d(keypoints_2d):
    """
    Args:
        keypoints_2d: (frames, 17, 2) - 2D joint positions
    Returns:
        keypoints_3d: (frames, 17, 3) - 3D joint positions
    """
    model = load_model()
=======
import sys
import os
import torch

# Add VideoPose3D to path
sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..', '..', 'models', 'VideoPose3D'))

from common.model import TemporalModel
from common.camera import normalize_screen_coordinates

def convert_to_3d(keypoints_2d):
    """
    Convert 2D keypoints to 3D using VideoPose3D model.
    
    Args:
        keypoints_2d: numpy array of shape (frames, 33, 2) from MediaPipe
        
    Returns:
        keypoints_3d: numpy array of shape (frames, 17, 3) in VideoPose3D format
    """
    # MediaPipe has 33 keypoints, VideoPose3D uses 17 keypoints
    # Map MediaPipe keypoints to VideoPose3D format
    mp_to_videopose3d = {
        0: 0,   # nose
        2: 1,   # left_eye
        5: 2,   # right_eye
        7: 3,   # left_ear
        8: 4,   # right_ear
        11: 5,  # left_shoulder
        12: 6,  # right_shoulder
        13: 7,  # left_elbow
        14: 8,  # right_elbow
        15: 9,  # left_wrist
        16: 10, # right_wrist
        23: 11, # left_hip
        24: 12, # right_hip
        25: 13, # left_knee
        26: 14, # right_knee
        27: 15, # left_ankle
        28: 16, # right_ankle
    }
    
    # Convert to VideoPose3D format (17 keypoints)
    keypoints_videopose3d = []
    for frame_keypoints in keypoints_2d:
        frame_17 = []
        for videopose_idx in range(17):
            if videopose_idx in mp_to_videopose3d.values():
                # Find the MediaPipe index for this VideoPose3D index
                mp_idx = [k for k, v in mp_to_videopose3d.items() if v == videopose_idx][0]
                frame_17.append(frame_keypoints[mp_idx])
            else:
                # If keypoint not available, use zeros
                frame_17.append([0.0, 0.0])
        keypoints_videopose3d.append(frame_17)
    
    keypoints_videopose3d = np.array(keypoints_videopose3d)  # (frames, 17, 2)
    
    # Normalize coordinates (VideoPose3D expects normalized coordinates)
    # Assuming 1920x1080 resolution for now
    keypoints_videopose3d = normalize_screen_coordinates(
        keypoints_videopose3d, w=1920, h=1080
    )
    
    # Load VideoPose3D model
    model_path = os.path.join(
        os.path.dirname(__file__), '..', '..', '..', 'models', 'VideoPose3D', 'checkpoint'
    )
    
    # For now, return mock 3D data with proper shape
    # TODO: Implement actual VideoPose3D model loading and inference
    frames, joints, _ = keypoints_videopose3d.shape
    keypoints_3d = np.zeros((frames, joints, 3))
    
    # Copy 2D coordinates to first two dimensions
    keypoints_3d[:, :, :2] = keypoints_videopose3d
    
    # Add mock depth (z-coordinate) - replace with actual model inference
    keypoints_3d[:, :, 2] = np.random.normal(0.5, 0.1, (frames, joints))
    
    return keypoints_3d
>>>>>>> Stashed changes

    # Wrap in a generator for temporal padding
    gen = UnchunkedGenerator(None, [keypoints_2d], pad=model.receptive_field() // 2, causal=False)
    inputs_2d = gen.next_epoch()

    with torch.no_grad():
        for _, batch, _, _ in inputs_2d:
            predicted_3d = model(batch)
            keypoints_3d = predicted_3d.squeeze(0).cpu().numpy()
            return keypoints_3d  # shape: (frames, 17, 3)
