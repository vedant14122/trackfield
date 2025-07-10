from pykalman import KalmanFilter
import numpy as np

def smooth_keypoints_3d(keypoints_3d):
    """
    Smooth 3D keypoints using Kalman filtering
    
    Args:
        keypoints_3d: numpy array of shape (frames, joints, 3)
    
    Returns:
        smoothed_keypoints: numpy array of shape (frames, joints, 3)
    """
    frames, joints, dims = keypoints_3d.shape
    smoothed = np.zeros_like(keypoints_3d)
    
    for j in range(joints):
        # Initialize Kalman filter for each joint
        # initial_state_mean should be a 1D array of length 3 (x, y, z)
        initial_state = keypoints_3d[0, j].flatten()
        
        # Create transition matrix for 3D position (assuming constant velocity model)
        transition_matrices = np.eye(3)
        observation_matrices = np.eye(3)
        
        # Initialize Kalman filter
        kf = KalmanFilter(
            transition_matrices=transition_matrices,
            observation_matrices=observation_matrices,
            initial_state_mean=initial_state,
            initial_state_covariance=np.eye(3) * 0.1,
            transition_covariance=np.eye(3) * 0.01,
            observation_covariance=np.eye(3) * 0.1
        )
        
        # Apply smoothing to the joint trajectory
        observations = keypoints_3d[:, j]  # shape: (frames, 3)
        filtered, _ = kf.smooth(observations)
        smoothed[:, j] = filtered
    
    return smoothed

