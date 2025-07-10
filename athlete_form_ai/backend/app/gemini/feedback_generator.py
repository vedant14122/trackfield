import os
from dotenv import load_dotenv
import google.generativeai as genai
import numpy as np

load_dotenv()

api_key = os.getenv("GEMINI_API_KEY")
if not api_key:
    raise ValueError("❌ GEMINI_API_KEY not found in .env file.")

genai.configure(api_key=api_key)
model = genai.GenerativeModel("gemini-pro")


def calculate_angle(a, b, c):
    """Calculate angle between three points a, b, c where b is the vertex."""
    a = np.array(a)
    b = np.array(b)
    c = np.array(c)
    ba = a - b
    bc = c - b
    cosine_angle = np.dot(ba, bc) / (np.linalg.norm(ba) * np.linalg.norm(bc) + 1e-8)
    angle = np.arccos(np.clip(cosine_angle, -1.0, 1.0))
    return np.degrees(angle)


def summarize_angles(angle_data):
    """
    Convert the list of per-frame joint angles into a readable summary string.
    You could enhance this with per-joint averages, variances, etc.
    """
    summary_lines = []
    num_frames = len(angle_data)

    # Collect per-joint stats
    joint_summaries = {}
    for frame in angle_data:
        for joint, angle in frame.items():
            if angle is None: continue
            joint_summaries.setdefault(joint, []).append(angle)

    for joint, values in joint_summaries.items():
        avg = sum(values) / len(values)
        min_v = min(values)
        max_v = max(values)
        summary_lines.append(
            f"{joint.replace('_', ' ').title()}: avg {avg:.1f}°, min {min_v:.1f}°, max {max_v:.1f}°"
        )

    return "\n".join(summary_lines)


def get_gemini_feedback(angle_data):
    summary = summarize_angles(angle_data)

    prompt = (
        "You're a professional track & field form coach. Analyze this joint angle data "
        "from a video of an athlete's motion. Point out any issues with form, asymmetry, or inefficiency.\n\n"
        f"{summary}"
    )

    response = model.generate_content(prompt)
    return response.text


def compare_to_model(smoothed_3d, model):
    feedback = []
    for frame_idx, frame in enumerate(smoothed_3d):
        # Joint indices (VideoPose3D 17-joint format):
        # 0: nose, 1: l_eye, 2: r_eye, 3: l_ear, 4: r_ear, 5: l_shoulder, 6: r_shoulder, 7: l_elbow, 8: r_elbow,
        # 9: l_wrist, 10: r_wrist, 11: l_hip, 12: r_hip, 13: l_knee, 14: r_knee, 15: l_ankle, 16: r_ankle
        joints = frame
        # Hip angle (right side)
        hip = joints[12]
        knee = joints[14]
        ankle = joints[16]
        shoulder = joints[6]
        elbow = joints[8]
        wrist = joints[10]
        torso_top = (joints[5] + joints[6]) / 2  # midpoint of shoulders
        torso_base = (joints[11] + joints[12]) / 2  # midpoint of hips
        # Angles
        hip_angle = calculate_angle(shoulder, hip, knee)
        knee_angle = calculate_angle(hip, knee, ankle)
        ankle_angle = calculate_angle(knee, ankle, [ankle[0], ankle[1], ankle[2] - 1])  # vertical reference
        elbow_angle = calculate_angle(shoulder, elbow, wrist)
        shoulder_angle = calculate_angle(torso_top, shoulder, elbow)
        torso_angle = calculate_angle(torso_top, torso_base, [torso_base[0], torso_base[1], torso_base[2] - 1])
        # Compare to model
        angle_results = {
            "hip_angle": hip_angle,
            "knee_angle": knee_angle,
            "ankle_angle": ankle_angle,
            "elbow_angle": elbow_angle,
            "shoulder_angle": shoulder_angle,
            "torso_angle": torso_angle,
        }
        for angle_name, angle_value in angle_results.items():
            if angle_name in model:
                diff = abs(angle_value - model[angle_name]["ideal"])
                if diff > model[angle_name]["tolerance"]:
                    feedback.append(
                        f"Frame {frame_idx}: {angle_name.replace('_', ' ').title()} off by {int(diff)}° (ideal {model[angle_name]['ideal']}°)"
                    )
    if not feedback:
        feedback.append("Form looks good!")
    return feedback


def detect_keyframes(smoothed_3d, threshold=10):
    """
    Detect keyframes based on changes in joint angles or positions.
    Returns a list of frame indices considered as keyframes.
    """
    # Simple heuristic: keyframe if hip or knee angle changes by more than threshold degrees
    keyframes = [0]
    prev_hip = None
    prev_knee = None
    for frame_idx, frame in enumerate(smoothed_3d):
        hip = frame[23]
        knee = frame[25]
        ankle = frame[27]
        shoulder = frame[11]
        hip_angle = calculate_angle(shoulder, hip, knee)
        knee_angle = calculate_angle(hip, knee, ankle)
        if prev_hip is not None and prev_knee is not None:
            if abs(hip_angle - prev_hip) > threshold or abs(knee_angle - prev_knee) > threshold:
                keyframes.append(frame_idx)
        prev_hip = hip_angle
        prev_knee = knee_angle
    return keyframes


def generate_gemini_feedback(keyframe_data, user_profile, motion_type):
    """
    Call Gemini 2.0 Flash API to generate coaching feedback for a keyframe.
    """
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        return f"[Gemini not configured] Feedback for frame {keyframe_data['frame']} (mock)"
    genai.configure(api_key=api_key)
    try:
        model = genai.GenerativeModel("gemini-2.0-flash")
        prompt = f"""
You are a track and field coach. Analyze the following athlete's pose for the motion type '{motion_type}'.
User profile: {user_profile}
Keyframe (3D joint positions): {keyframe_data['pose']}
Give concise, actionable feedback for this frame, focusing on joint angles and form improvement. Use simple language.
"""
        response = model.generate_content(prompt)
        return response.text.strip() if hasattr(response, 'text') else str(response)
    except Exception as e:
        return f"[Gemini error: {e}] Feedback for frame {keyframe_data['frame']} (mock)"


def generate_gemini_chat_response(user_profile, question, context):
    """
    Use Gemini 2.0 Flash to answer a user's question about their feedback, form, or performance.
    """
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        return "[Gemini not configured]"
    genai.configure(api_key=api_key)
    try:
        model = genai.GenerativeModel("gemini-2.0-flash")
        prompt = f"""
You are a track and field AI coach. The user has the following profile: {user_profile}
Here is some context about their recent performance or feedback: {context}
The user asks: '{question}'
Please provide a helpful, concise, and actionable answer.
"""
        response = model.generate_content(prompt)
        return response.text.strip() if hasattr(response, 'text') else str(response)
    except Exception as e:
        return f"[Gemini error: {e}]"
