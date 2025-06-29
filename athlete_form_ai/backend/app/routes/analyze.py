from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from app.utils.file_handler import save_to_temp
from app.pose.mediapipe_runner import extract_2d_keypoints
from app.pose.videopose_runner import convert_to_3d
from app.pose.kalman_filter import smooth_keypoints_3d
from app.gemini.feedback_generator import compare_to_model
from app.gemini.model_builder import get_personalized_model
from app.utils.supabase_client import supabase
import os

router = APIRouter()

@router.post("/analyze")
async def analyze(
    file: UploadFile = File(...),
    motion_type: str = Form(...),
    user_id: str = Form(...)
):
    if motion_type not in ("sprint", "jump"):
        raise HTTPException(status_code=400, detail="motion_type must be 'sprint' or 'jump'")

    # Fetch user profile from Supabase
    response = supabase.table("user_profiles").select("*").eq("id", user_id).single().execute()
    if response.error or not response.data:
        raise HTTPException(status_code=400, detail="User profile not found")

    user_profile = response.data

    file_path = await save_to_temp(file)

    try:
        keypoints_2d = extract_2d_keypoints(file_path)
        keypoints_3d = convert_to_3d(keypoints_2d)
        smoothed_3d = smooth_keypoints_3d(keypoints_3d)

        # Build personalized model
        model = get_personalized_model(user_profile, motion_type)
        feedback = compare_to_model(smoothed_3d, model)

    finally:
        os.remove(file_path)

    return {"motion": motion_type, "feedback": feedback}
