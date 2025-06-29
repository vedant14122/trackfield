import numpy as np

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
        hip = frame[23]      # right hip
        knee = frame[25]     # right knee
        ankle = frame[27]    # right ankle
        shoulder = frame[11] # right shoulder

        hip_angle = calculate_angle(shoulder, hip, knee)
        knee_angle = calculate_angle(hip, knee, ankle)

        hip_diff = abs(hip_angle - model["hip_angle"]["ideal"])
        knee_diff = abs(knee_angle - model["knee_angle"]["ideal"])

        if hip_diff > model["hip_angle"]["tolerance"]:
            feedback.append(
                f"Frame {frame_idx}: Hip angle off by {int(hip_diff)}° (ideal {model['hip_angle']['ideal']}°)"
            )
        if knee_diff > model["knee_angle"]["tolerance"]:
            feedback.append(
                f"Frame {frame_idx}: Knee angle off by {int(knee_diff)}° (ideal {model['knee_angle']['ideal']}°)"
            )

    if not feedback:
        feedback.append("Form looks good!")

    return feedback
