import os
import shutil
import uuid
from fastapi import UploadFile

TEMP_DIR = "temp"
os.makedirs(TEMP_DIR, exist_ok=True)

async def save_to_temp(upload_file: UploadFile) -> str:
    file_id = str(uuid.uuid4())
    temp_path = os.path.join(TEMP_DIR, f"{file_id}_{upload_file.filename}")
    
    with open(temp_path, "wb") as f:
        content = await upload_file.read()
        f.write(content)
    
    return temp_path
