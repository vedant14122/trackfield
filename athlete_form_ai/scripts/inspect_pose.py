import numpy as np

keypoints = np.load("pose_2d.npy", allow_pickle=True)

print("Loaded object type:", type(keypoints))
print("Shape:", getattr(keypoints, 'shape', 'N/A'))
print("First element type:", type(keypoints[0]) if keypoints.ndim == 1 else 'N/A')
print("First element shape:", keypoints[0].shape if keypoints.ndim == 1 else 'N/A')
