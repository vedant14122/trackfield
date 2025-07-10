from fastapi import APIRouter, Query, HTTPException
from app.utils.supabase_client import supabase

router = APIRouter()

@router.get("/keyframes")
async def get_keyframes(user_id: str = Query(...), video_filename: str = Query(None)):
    if supabase is None:
        raise HTTPException(status_code=500, detail="Supabase client not configured")
    query = supabase.table("keyframes").select("*").eq("user_id", user_id)
    if video_filename:
        query = query.eq("video_filename", video_filename)
    response = query.execute()
    if response.error:
        raise HTTPException(status_code=500, detail=response.error.message)
    return {"keyframes": response.data} 