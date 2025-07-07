import torch
import numpy as np
import os
import sys

# Add VideoPose3D repo to path
sys.path.append(os.path.abspath("models"))

from common.model import TemporalModel
from common.generators import UnchunkedGenerator

# Load VideoPose3D model once and reuse
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
        keypoints_2d: np.ndarray of shape (frames, 17, 2)
    Returns:
        keypoints_3d: np.ndarray of shape (frames, 17, 3)
    """
    model = load_model()

    # Wrap in a dummy generator
    gen = UnchunkedGenerator(None, [keypoints_2d], pad=model.receptive_field() // 2, causal=False)
    inputs_2d = gen.next_epoch()

    with torch.no_grad():
        for _, batch, _, _ in inputs_2d:
            predicted_3d_pos = model(batch)
            predicted_3d_pos = predicted_3d_pos.squeeze(0).cpu().numpy()  # (frames, 17, 3)
            return predicted_3d_pos
