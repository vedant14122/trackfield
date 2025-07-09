import numpy as np

def calculate_angle(a, b, c):
    a = np.array(a)
    b = np.array(b)
    c = np.array(c)
    ba = a - b
    bc = c - b
    cosine_angle = np.dot(ba, bc) / (np.linalg.norm(ba) * np.linalg.norm(bc) + 1e-8)
    angle = np.arccos(np.clip(cosine_angle, -1.0, 1.0))
    return np.degrees(angle)

def calculate_core_twist(left_hip, right_hip, left_shoulder, right_shoulder):
    hip_vector = np.array(right_hip) - np.array(left_hip)
    shoulder_vector = np.array(right_shoulder) - np.array(left_shoulder)

    hip_proj = np.array([hip_vector[0], hip_vector[2]])
    shoulder_proj = np.array([shoulder_vector[0], shoulder_vector[2]])

    hip_proj /= np.linalg.norm(hip_proj) + 1e-8
    shoulder_proj /= np.linalg.norm(shoulder_proj) + 1e-8

    cosine_angle = np.dot(hip_proj, shoulder_proj)
    angle = np.arccos(np.clip(cosine_angle, -1.0, 1.0))
    return np.degrees(angle)

# Joint index map — you can adjust based on your actual 3D joint layout
JOINTS = {
    "right_hip": 0,
    "right_knee": 1,
    "right_ankle": 2,
    "left_hip": 3,
    "left_knee": 4,
    "left_ankle": 5,
    "spine": 6,
    "neck": 7,
    "nose": 8,
    "head": 9,
    "left_shoulder": 10,
    "left_elbow": 11,
    "left_wrist": 12,
    "right_shoulder": 13,
    "right_elbow": 14,
    "right_wrist": 15,
    "pelvis_center": 16,
}

# Define all angle joints (joint: (parent, child))
ANGLE_JOINTS = {
    "right_knee": ("right_hip", "right_ankle"),
    "left_knee": ("left_hip", "left_ankle"),
    "right_elbow": ("right_shoulder", "right_wrist"),
    "left_elbow": ("left_shoulder", "left_wrist"),
    "right_hip": ("right_shoulder", "right_knee"),
    "left_hip": ("left_shoulder", "left_knee"),
    "left_shoulder": ("spine", "left_elbow"),
    "right_shoulder": ("spine", "right_elbow"),
    "spine": ("pelvis_center", "neck"),
    "neck": ("spine", "head")
}

def calculate_angles_from_pose(smoothed_3d):
    all_angles = []

    for frame_idx, frame in enumerate(smoothed_3d):
        frame_angles = {}

        # Compute joint angles
        for joint_name, (parent_name, child_name) in ANGLE_JOINTS.items():
            try:
                a = frame[JOINTS[parent_name]]
                b = frame[JOINTS[joint_name]]
                c = frame[JOINTS[child_name]]
                angle = calculate_angle(a, b, c)
                frame_angles[joint_name] = angle
            except:
                frame_angles[joint_name] = None

        # Core twist angle (torso rotation)
        try:
            twist_angle = calculate_core_twist(
                frame[JOINTS["left_hip"]],
                frame[JOINTS["right_hip"]],
                frame[JOINTS["left_shoulder"]],
                frame[JOINTS["right_shoulder"]]
            )
            frame_angles["core_twist"] = twist_angle
        except:
            frame_angles["core_twist"] = None

        all_angles.append(frame_angles)

    return all_angles  # list of dicts: [ {joint: angle}, {joint: angle}, ... ]
