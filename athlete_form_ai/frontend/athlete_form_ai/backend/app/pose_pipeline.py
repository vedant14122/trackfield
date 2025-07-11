import os
from app.pose.mediapipe_runner import extract_2d_keypoints
from app.pose.videopose_runner import convert_to_3d
from app.pose.kalman_filter import smooth_keypoints_3d
from app.gemini.model_builder import get_personalized_model
from app.gemini.feedback_generator import compare_to_model, detect_keyframes, generate_gemini_feedback

def process_video(video_path, user_profile, motion_type):
    keypoints_2d = extract_2d_keypoints(video_path)
    if keypoints_2d.size == 0:
        raise ValueError("No pose keypoints detected in video.")
    keypoints_3d = convert_to_3d(keypoints_2d)
    smoothed_3d = smooth_keypoints_3d(keypoints_3d)
    model = get_personalized_model(user_profile, motion_type)
    feedback = compare_to_model(smoothed_3d, model)

    # Day 3: Keyframe detection and Gemini feedback
    keyframes = detect_keyframes(smoothed_3d)
    keyframe_feedback = []
    for frame_idx in keyframes:
        keyframe_data = {
            "frame": frame_idx,
            "pose": smoothed_3d[frame_idx].tolist(),
        }
        gemini_fb = generate_gemini_feedback(keyframe_data, user_profile, motion_type)
        keyframe_feedback.append({
            "frame": frame_idx,
            "feedback": gemini_fb
        })

    return {
        "classic_feedback": feedback,
        "keyframes": keyframe_feedback
    }