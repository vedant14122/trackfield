import cv2
import mediapipe as mp
import numpy as np

mp_pose = mp.solutions.pose
pose = mp_pose.Pose(static_image_mode=False)

cap = cv2.VideoCapture("input.mp4")  # Change to your video file
keypoints_all = []

while cap.isOpened():
    ret, frame = cap.read()
    if not ret:
        break

    image_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    results = pose.process(image_rgb)

    if results.pose_landmarks:
        keypoints = []
        for lm in results.pose_landmarks.landmark:
            keypoints.append([lm.x, lm.y])
        keypoints_all.append(keypoints)
    else:
        keypoints_all.append(np.zeros((33, 2)))

cap.release()
keypoints_all = np.array(keypoints_all)
np.save("pose_2d.npy", keypoints_all)
print("2D keypoints saved to pose_2d.npy")
