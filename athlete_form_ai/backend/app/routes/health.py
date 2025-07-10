from fastapi import APIRouter

router = APIRouter()

@router.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "message": "TrackField API is running",
        "version": "1.0.0"
    }

@router.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "TrackField API",
        "endpoints": {
            "health": "/health",
            "analyze": "/analyze",
        }
    } 