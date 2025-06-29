from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from app.utils.file_handler import save_to_temp
from app.pose.mediapipe_runner import extract_2d_keypoints
from app.pose.videopose_runner import convert_to_3d
from app.pose.kalman_filter import smooth_keypoints_3d
from app.gemini.feedback_generator import compare_to_model
from app.gemini.model_builder import get_personalized_model
from app.utils.supabase_client import supabase

import os
import json
from datetime import datetime

router = APIRouter()
STORAGE_DIR = "storage"
os.makedirs(STORAGE_DIR, exist_ok=True)

def save_feedback_file(feedback: list, filename: str):
    path = os.path.join(STORAGE_DIR, filename)
    with open(path, "w") as f:
        json.dump(feedback, f, indent=2)
    return path

@router.post("/analyze")
async def analyze(
    file: UploadFile = File(...),
    motion_type: str = Form(...),
    user_id: str = Form(...)
):
    if motion_type not in ("sprint", "jump"):
        raise HTTPException(status_code=400, detail="Invalid motion_type")

    # Get user profile from Supabase
    response = supabase.table("user_profiles").select("*").eq("id", user_id).single().execute()
    if response.error or not response.data:
        raise HTTPException(status_code=400, detail="User profile not found")
    user_profile = response.data

    # Save to temp path for initial processing
    temp_path = await save_to_temp(file)

    # Rename and move permanently
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    base_name = f"{user_id}_{motion_type}_{timestamp}"
    video_filename = f"{base_name}.mp4"
    video_path = os.path.join(STORAGE_DIR, video_filename)
    os.rename(temp_path, video_path)

    # Run pose pipeline
    keypoints_2d = extract_2d_keypoints(video_path)
    keypoints_3d = convert_to_3d(keypoints_2d)
    smoothed_3d = smooth_keypoints_3d(keypoints_3d)

    # Build model + generate feedback
    model = get_personalized_model(user_profile, motion_type)
    feedback = compare_to_model(smoothed_3d, model)

    # Save feedback to file
    feedback_filename = f"{base_name}_feedback.json"
    feedback_path = save_feedback_file(feedback, feedback_filename)

    return {
        "message": "Analysis complete.",
        "video_url": f"/static/{video_filename}",
        "feedback_url": f"/static/{feedback_filename}",
        "feedback": feedback
    }
