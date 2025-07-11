from fastapi import APIRouter, UploadFile, Form, HTTPException
import shutil
import os
import numpy as np
import json
from datetime import datetime
import logging

from app.pose.mediapipe_runner import extract_2d_keypoints
from app.pose.videopose_runner import convert_to_3d
from app.pose.kalman_filter import smooth_pose

router = APIRouter()

# Constants
STORAGE_DIR = "storage"
os.makedirs(STORAGE_DIR, exist_ok=True)

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

        for joint_name, (parent_name, child_name) in ANGLE_JOINTS.items():
            try:
                a = frame[JOINTS[parent_name]]
                b = frame[JOINTS[joint_name]]
                c = frame[JOINTS[child_name]]
                angle = calculate_angle(a, b, c)
                frame_angles[joint_name] = angle
            except:
                frame_angles[joint_name] = None

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

    return all_angles


def save_feedback_file(feedback: dict, filename: str):
    path = os.path.join(STORAGE_DIR, filename)
    with open(path, "w") as f:
        json.dump(feedback, f, indent=2)
    return path


async def save_to_temp(file: UploadFile):
    """Save uploaded file to temporary location."""
    temp_path = os.path.join("temp", file.filename)
    os.makedirs("temp", exist_ok=True)
    with open(temp_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    return temp_path


def process_video(video_path: str, user_profile: str, motion_type: str):
    """Process video and generate feedback."""
    # Extract 2D keypoints
    keypoints_2d = extract_2d_keypoints(video_path)
    
    # Convert to 3D
    keypoints_3d = convert_to_3d(keypoints_2d)
    
    # Smooth the pose data
    smoothed_3d = smooth_pose(keypoints_3d)
    
    # Calculate angles
    angles_per_frame = calculate_angles_from_pose(smoothed_3d)
    
    # Generate feedback (placeholder for now)
    classic_feedback = {
        "frame_count": len(angles_per_frame),
        "angles_first_frame": angles_per_frame[0] if angles_per_frame else {},
        "summary": "Video analysis complete"
    }
    
    # Generate keyframes (placeholder)
    keyframes = [
        {
            "frame": 0,
            "feedback": "Starting position analyzed"
        }
    ]
    
    return {
        "classic_feedback": classic_feedback,
        "keyframes": keyframes
    }


@router.post("/analyze")
async def analyze_video(
    file: UploadFile,
    user_id: str = Form(...),
    motion_type: str = Form(...)
):
    # Save uploaded file
    temp_path = await save_to_temp(file)

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    base_name = f"{user_id}_{motion_type}_{timestamp}"
    video_filename = f"{base_name}.mp4"
    video_path = os.path.join(STORAGE_DIR, video_filename)
    os.rename(temp_path, video_path)

    # Process the video
    try:
        feedback_result = process_video(video_path, "user_profile", motion_type)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

    feedback = feedback_result["classic_feedback"]
    keyframes = feedback_result["keyframes"]

    feedback_filename = f"{base_name}_feedback.json"
    feedback_path = save_feedback_file(feedback_result, feedback_filename)

    # Store keyframes in Supabase (placeholder - supabase client not imported)
    # if supabase is not None:
    #     for kf in keyframes:
    #         supabase.table("keyframes").insert({
    #             "user_id": user_id,
    #             "video_filename": video_filename,
    #             "frame": kf["frame"],
    #             "feedback": kf["feedback"],
    #             "created_at": datetime.now().isoformat(),
    #         }).execute()
    # else:
    #     logging.warning("Supabase client is None, skipping keyframe storage.")

    return {
        "message": "Analysis complete.",
        "video_url": f"/static/{video_filename}",
        "feedback_url": f"/static/{feedback_filename}",
        "feedback": feedback_result
    }
