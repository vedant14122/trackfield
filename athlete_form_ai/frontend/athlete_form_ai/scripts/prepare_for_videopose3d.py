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

# Add dummy 3D data
keypoints_3d_dummy = np.zeros((keypoints_17.shape[0], keypoints_17.shape[1], 3), dtype=np.float32)

# Structure: 2D data as a list of camera views (we only have one camera)
positions_2d = {
    "S1": {
        "custom": [keypoints_17]  # List with one camera view
    }
}

print("Check type of positions_2d['S1']['custom']:", type(positions_2d['S1']['custom']))
print("Length of custom action (should be 1 camera):", len(positions_2d['S1']['custom']))

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
    "layout_name": "custom",
    "num_joints": 16,
    "keypoints_symmetry": [[0, 3, 6, 9, 12, 15], [1, 4, 7, 10, 13, 14]],
    "video_metadata": {
        "S1": {
            "w": 1920,
            "h": 1080
        }
    }
}

np.savez(
    "data_2d_custom_custom.npz",
    positions_2d=positions_2d,
    metadata=metadata
)
print("✅ Saved data_2d_custom_custom.npz")

# Now we need to create a separate 3D data file for the custom dataset
# The 3D data should be structured the same way as the 2D data
positions_3d = {
    "S1": {
        "custom": [keypoints_3d_dummy]  # List with one camera view
    }
}

np.savez(
    "data_3d_custom.npz",
    positions_3d=positions_3d
)
print("✅ Saved data_3d_custom.npz")