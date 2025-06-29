import cv2
import mediapipe as mp
import numpy as np

def extract_2d_keypoints(video_path):
    mp_pose = mp.solutions.pose
    pose = mp_pose.Pose(static_image_mode=False)
    cap = cv2.VideoCapture(video_path)

    keypoints = []

    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break
        frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        result = pose.process(frame_rgb)
        if result.pose_landmarks:
            coords = [[lm.x, lm.y] for lm in result.pose_landmarks.landmark]
            keypoints.append(coords)

    cap.release()
    return np.array(keypoints)  # shape: (frames, 33, 2)

