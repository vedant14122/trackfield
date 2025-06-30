import numpy as np
import openai
import os

def calculate_angle(a, b, c):
    a = np.array(a)
    b = np.array(b)
    c = np.array(c)
    ba = a - b
    bc = c - b
    cosine_angle = np.dot(ba, bc) / (np.linalg.norm(ba) * np.linalg.norm(bc) + 1e-8)
    angle = np.arccos(np.clip(cosine_angle, -1.0, 1.0))
    return np.degrees(angle)

def compare_to_model(smoothed_3d, model):
    feedback = []

    for frame_idx, frame in enumerate(smoothed_3d):
        shoulder = frame[11]  # right shoulder
        hip = frame[23]       # right hip
        knee = frame[25]      # right knee
        ankle = frame[27]     # right ankle

        hip_angle = calculate_angle(shoulder, hip, knee)
        knee_angle = calculate_angle(hip, knee, ankle)

        hip_diff = abs(hip_angle - model["hip_angle"]["ideal"])
        knee_diff = abs(knee_angle - model["knee_angle"]["ideal"])

        frame_feedback = []

        if hip_diff > model["hip_angle"]["tolerance"]:
            frame_feedback.append(
                f"Hip angle off by {int(hip_diff)}° (ideal: {model['hip_angle']['ideal']}°)"
            )
        if knee_diff > model["knee_angle"]["tolerance"]:
            frame_feedback.append(
                f"Knee angle off by {int(knee_diff)}° (ideal: {model['knee_angle']['ideal']}°)"
            )

        if frame_feedback:
            feedback.append(f"Frame {frame_idx}: " + " | ".join(frame_feedback))

    if not feedback:
        feedback.append("Form looks good!")

    return feedback

openai.api_key = os.getenv("OPENROUTER_API_KEY")
openai.api_base = "https://openrouter.ai/api/v1"

def generate_llm_feedback(framewise_feedback: list, motion_type: str) -> str:
    prompt = f"""
You're a professional {motion_type} coach. Analyze this feedback and give 2–3 clear, practical suggestions:

{chr(10).join(framewise_feedback)}
"""
    try:
        response = openai.ChatCompletion.create(
            model="mistralai/mistral-7b-instruct",  
            messages=[{"role": "user", "content": prompt}]
        )
        return response['choices'][0]['message']['content']
    except Exception as e:
        return f"[LLM Error] {e}"