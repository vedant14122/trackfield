from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.routes import analyze

app = FastAPI()

# CORS (adjust for your Flutter dev URL if needed)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Change this for production!
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# API routes
app.include_router(analyze.router)

# Serve local storage files (videos + feedback)
app.mount("/static", StaticFiles(directory="storage"), name="static")
