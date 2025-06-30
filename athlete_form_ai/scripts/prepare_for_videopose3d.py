import numpy as np

mp_to_h36m = [
    11, 13, 15,
    12, 14, 16,
    23, 25, 27,
    24, 26, 28,
    0, 5, 2, 7
]

keypoints = np.load("pose_2d.npy", allow_pickle=True)
print("Loaded:", keypoints.shape)

keypoints_17 = keypoints[:, mp_to_h36m, :]
print("Mapped:", keypoints_17.shape)

# 🔒 Strict dictionary assignment
positions_2d = {
    "S1": {
        "custom": {
            "camera0": keypoints_17
        }
    }
}

print("Check type of positions_2d['S1']:", type(positions_2d['S1']))  # <class 'dict'> expected

metadata = {
    "layout": "custom",
    "num_joints": 17,
    "keypoints_symmetry": [[1, 4, 7, 10, 13, 16], [2, 5, 8, 11, 14, 17]],
    "video_metadata": {
        "S1": {
            "custom": {
                "res_w": 1920,
                "res_h": 1080,
                "camera": "camera0"
            }
        }
    }
}

np.savez("data_2d_custom.npz", positions_2d=positions_2d, metadata=metadata)
print("✅ Saved data_2d_custom.npz")

np.savez("data_2d_custom.npz", positions_2d=positions_2d, metadata=metadata)
print("✅ Saved data_2d_custom.npz")
