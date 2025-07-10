#!/usr/bin/env python3
"""
Run the TrackField FastAPI server
"""

import uvicorn
import os

if __name__ == "__main__":
    # Create storage directory if it doesn't exist
    os.makedirs("storage", exist_ok=True)
    os.makedirs("temp", exist_ok=True)
    
    # Run the server
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,  # Auto-reload on code changes
        log_level="info"
    ) 