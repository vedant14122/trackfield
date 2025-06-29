import os
import shutil
from fastapi import UploadFile

async def save_to_temp(file: UploadFile, temp_dir="temp_videos"):
    os.makedirs(temp_dir, exist_ok=True)
    file_path = os.path.join(temp_dir, file.filename)
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    return file_path

