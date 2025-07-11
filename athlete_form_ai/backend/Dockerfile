FROM python:3.10-slim

# Install system dependencies for mediapipe
RUN apt-get update && apt-get install -y \
    ffmpeg \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN python --version
RUN pip install --upgrade pip
RUN pip install -r requirements.txt

COPY . .

CMD ["python", "run_server.py"] 