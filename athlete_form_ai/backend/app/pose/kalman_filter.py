from pykalman import KalmanFilter
import numpy as np

def smooth_keypoints_3d(keypoints_3d):
    smoothed = []
    for j in range(keypoints_3d.shape[1]):
        kf = KalmanFilter(initial_state_mean=keypoints_3d[0, j])
        filtered, _ = kf.smooth(keypoints_3d[:, j])
        smoothed.append(filtered)
    return np.transpose(np.array(smoothed), (1, 0, 2))  # shape: (frames, joints, 3)

