from fastapi import APIRouter, UploadFile, File, Form
from app.utils.file_handler import save_to_temp
from app.pose.mediapipe_runner import extract_2d_keypoints
from app.pose.videopose_runner import convert_to_3d
from app.pose.kalman_filter import smooth_keypoints_3d
from app.gemini.feedback_generator import compare_to_model

import os

router = APIRouter()

@router.post("/analyze")
async def analyze(file: UploadFile = File(...), motion_type: str = Form(...)):
    file_path = await save_to_temp(file)
    
    keypoints_2d = extract_2d_keypoints(file_path)
    keypoints_3d = convert_to_3d(keypoints_2d)
    smoothed_3d = smooth_keypoints_3d(keypoints_3d)

    model_path = f"models/{motion_type}_model.json"
    feedback = compare_to_model(smoothed_3d, model_path)

    os.remove(file_path)
    return {
        "motion": motion_type,
        "feedback": feedback
    }

