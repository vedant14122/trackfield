import sys
import os
import importlib.util
import json
import numpy as np

# Dynamically import analyze.py
analyze_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "../app/routes/analyze.py"))
spec = importlib.util.spec_from_file_location("analyze", analyze_path)
analyze = importlib.util.module_from_spec(spec)
spec.loader.exec_module(analyze)

def test_calculate_angles_from_pose_shape():
    dummy_pose = np.zeros((5, 17, 3))  # 5 frames, 17 joints, 3D coords
    angles = analyze.calculate_angles_from_pose(dummy_pose)
    
    assert isinstance(angles, list)
    assert len(angles) == 5
    assert all(isinstance(f, dict) for f in angles)

def test_save_feedback_file_creates_json():
    dummy_feedback = {"test": "value"}
    filename = "test_feedback.json"

    path = analyze.save_feedback_file(dummy_feedback, filename)
    
    assert os.path.exists(path)

    with open(path, "r") as f:
        data = json.load(f)
        assert data == dummy_feedback

    os.remove(path)
