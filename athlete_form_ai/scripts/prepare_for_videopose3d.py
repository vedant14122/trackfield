import numpy as np

# Mapping MediaPipe 33 keypoints to 17 joints for VideoPose3D (adjust as needed)
mp_to_h36m = [0, 11, 12, 23, 24, 25, 26, 27, 28, 29, 30, 13, 14, 15, 16, 17, 18]

keypoints = np.load("pose_2d.npy")  # (frames, 33, 2)
keypoints_17 = keypoints[:, mp_to_h36m, :]

np.savez_compressed("data_2d_custom.npz", positions_2d=[keypoints_17])
print("✅ Saved 17-joint keypoints in data_2d_custom.npz")
