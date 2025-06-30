import numpy as np

mp_to_h36m = [
    11, 13, 15,
    12, 14, 16,
    23, 25, 27,
    24, 26, 28,
    0, 5, 2, 7
]

keypoints_2d_raw = np.load("pose_2d.npy", allow_pickle=True)
print("Loaded:", keypoints_2d_raw.shape)

keypoints_17 = keypoints_2d_raw[:, mp_to_h36m, :]
print("Mapped:", keypoints_17.shape)

# positions_2d must be a list of keypoint arrays for enumerate to work correctly
positions_2d = {
    "S1": {
        "custom": [ # This is a LIST of keypoint arrays
            keypoints_17 # This is for cam_idx = 0
        ]
    }
}

print("Check type of positions_2d['S1']['custom']:", type(positions_2d['S1']['custom']))

# Define the actual camera parameters
camera_params = {
    "camera0": {
        "res_w": 1920,
        "res_h": 1080,
        "focal_length": [1000, 1000],
        "principal_point": [960, 540],
        "radial_distortion": [0,0,0],
        "tangential_distortion": [0,0],
        "rotation": np.identity(3).tolist(),
        "translation": [0,0,0]
    }
}

metadata = {
    "layout": "custom",
    "num_joints": 17,
    "keypoints_symmetry": [[1, 4, 7, 10, 13, 16], [2, 5, 8, 11, 14, 17]],
    "cameras": camera_params, # Link to the defined camera parameters
    "video_metadata": {
        "S1": {
            "custom": {
                "camera0": {
                    "res_w": 1920,
                    "res_h": 1080
                }
            }
        }
    }
}

np.savez("data_2d_custom.npz", positions_2d=positions_2d, metadata=metadata)
print("✅ Saved data_2d_custom.npz")