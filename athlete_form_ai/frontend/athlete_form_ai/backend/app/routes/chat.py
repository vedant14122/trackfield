from fastapi import APIRouter, Body, HTTPException
from app.utils.supabase_client import supabase
from app.gemini.feedback_generator import generate_gemini_chat_response

router = APIRouter()

@router.post("/chat")
async def chat(
    user_id: str = Body(...),
    question: str = Body(...),
    context: dict = Body(default={})
):
    # Fetch user profile from Supabase
    if supabase is not None:
        response = supabase.table("user_profiles").select("*").eq("id", user_id).single().execute()
        if response.error or not response.data:
            raise HTTPException(status_code=400, detail="User profile not found")
        user_profile = response.data
    else:
        user_profile = {}
    # Generate Gemini chat response
    answer = generate_gemini_chat_response(user_profile, question, context)
    return {"response": answer} 