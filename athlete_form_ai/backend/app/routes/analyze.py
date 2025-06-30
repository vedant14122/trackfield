from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from app.utils.file_handler import save_to_temp
from app.utils.sn_client import supabase
from app.pose_pipeline import process_video
from app.gemini.feedback_generator import compare_to_model, generate_llm_feedback

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

    response = supabase.table("user_profiles").select("*").eq("id", user_id).single().execute()
    if response.error or not response.data:
        raise HTTPException(status_code=400, detail="User profile not found")
    user_profile = response.data

    temp_path = await save_to_temp(file)

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    base_name = f"{user_id}_{motion_type}_{timestamp}"
    video_filename = f"{base_name}.mp4"
    video_path = os.path.join(STORAGE_DIR, video_filename)
    os.rename(temp_path, video_path)

    try:
        feedback = process_video(video_path, user_profile, motion_type)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

    try:
        summary = generate_llm_feedback(feedback, motion_type)
    except Exception as e:
        summary = f"[LLM Summary Error] {e}"

    feedback_filename = f"{base_name}_feedback.json"
    feedback_path = save_feedback_file(feedback, feedback_filename)

    return {
        "message": "Analysis complete.",
        "video_url": f"/static/{video_filename}",
        "feedback_url": f"/static/{feedback_filename}",
        "feedback": feedback,
        "feedback_summary": summary
    }