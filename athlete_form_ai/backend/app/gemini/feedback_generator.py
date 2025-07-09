import os
from dotenv import load_dotenv
import google.generativeai as genai

load_dotenv()

api_key = os.getenv("GEMINI_API_KEY")
if not api_key:
    raise ValueError("❌ GEMINI_API_KEY not found in .env file.")

genai.configure(api_key=api_key)
model = genai.GenerativeModel("gemini-pro")


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
