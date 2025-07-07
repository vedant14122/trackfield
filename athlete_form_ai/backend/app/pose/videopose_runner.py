import torch
import numpy as np
import os
from pose.models import TemporalModel  # You need to place VideoPose3D code in your repo

# Load model only once
_model = None
def load_model():
    global _model
    if _model is not None:
        return _model

    model = TemporalModel(
        17, 2, 17, filter_widths=[3, 3, 3, 3, 3],
        causal=False, dropout=0.25, channels=1024, dense=False
    )
    checkpoint = torch.load("weights/pretrained.bin", map_location="cpu")
    model.load_state_dict(checkpoint["model_state_dict"])
    model.eval()
    _model = model
    return _model

def convert_to_3d(keypoints_2d):
    """
    keypoints_2d: (frames, 17, 2) numpy array
    returns: (frames, 17, 3) numpy array
    """
    model = load_model()

    # Normalize keypoints (standard VideoPose3D preprocessing)
    # Convert to tensor with shape (1, frames, 17, 2)
    inputs = torch.from_numpy(keypoints_2d).float().unsqueeze(0)

    # Padding for temporal convolution
    receptive_field = model.receptive_field()
    pad = (receptive_field - 1) // 2
    inputs_padded = torch.nn.functional.pad(inputs, (0, 0, 0, 0, pad, pad), mode='replicate')

    with torch.no_grad():
        predicted_3d = model(inputs_padded)
    
    return predicted_3d.squeeze(0).cpu().numpy()
