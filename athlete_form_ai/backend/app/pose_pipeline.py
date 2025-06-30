import os
from mediapipe_runner import extract_2d_keypoints
from videopose_runner import convert_to_3d
from kalman_filter import smooth_keypoints_3d
from model_builder import get_personalized_model
from feedback_generator import compare_to_model

def process_video(video_path, user_profile, motion_type):

    keypoints_2d = extract_2d_keypoints(video_path)
    if keypoints_2d.size == 0:
        raise ValueError("No pose keypoints detected in video.")
    keypoints_3d = convert_to_3d(keypoints_2d)
    smoothed_3d = smooth_keypoints_3d(keypoints_3d)
    model = get_personalized_model(user_profile, motion_type)
    feedback = compare_to_model(smoothed_3d, model)

    return feedback