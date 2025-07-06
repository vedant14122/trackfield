import cv2
import mediapipe as mp
import numpy as np

def extract_2d_keypoints(video_path, save_path="pose_2d.npy"):
    mp_pose = mp.solutions.pose
    pose = mp_pose.Pose(static_image_mode=False)
    cap = cv2.VideoCapture(video_path)

    keypoints = []

    frame_width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    frame_height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))

    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break

        frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        result = pose.process(frame_rgb)

        if result.pose_landmarks:
            coords = []
            for lm in result.pose_landmarks.landmark:
                x_px = lm.x * frame_width
                y_px = lm.y * frame_height
                z_rel = lm.z * frame_width  # z is normalized like x
                coords.append([x_px, y_px, z_rel])
        else:
            coords = [[np.nan, np.nan, np.nan]] * 33  # all joints missing

        keypoints.append(coords)

    cap.release()
    keypoints_array = np.array(keypoints)  # shape: (frames, 33, 3)
    np.save(save_path, keypoints_array)
    print(f"✅ Saved keypoints with z-depth to {save_path}")
    return keypoints_array
