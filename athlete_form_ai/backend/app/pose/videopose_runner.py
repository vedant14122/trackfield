import numpy as np

def convert_to_3d(keypoints_2d):
    # Mock depth: replace with actual VideoPose3D model later
    z = np.ones(keypoints_2d.shape[:2]) * 0.5
    keypoints_3d = np.dstack((keypoints_2d, z))
    return keypoints_3d

