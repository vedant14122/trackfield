def get_personalized_model(user_profile: dict, motion_type: str) -> dict:
    # Base models for each motion type, with more joint angles
    base_models = {
        "sprint": {
            "hip_angle": {"ideal": 90, "tolerance": 15},
            "knee_angle": {"ideal": 120, "tolerance": 20},
            "ankle_angle": {"ideal": 90, "tolerance": 15},
            "elbow_angle": {"ideal": 160, "tolerance": 15},
            "shoulder_angle": {"ideal": 100, "tolerance": 15},
            "torso_angle": {"ideal": 180, "tolerance": 10},
        },
        "jump": {
            "hip_angle": {"ideal": 100, "tolerance": 10},
            "knee_angle": {"ideal": 90, "tolerance": 15},
            "ankle_angle": {"ideal": 95, "tolerance": 10},
            "elbow_angle": {"ideal": 150, "tolerance": 20},
            "shoulder_angle": {"ideal": 110, "tolerance": 15},
            "torso_angle": {"ideal": 170, "tolerance": 10},
        },
        # Add more sports/motions as needed
    }
    model = base_models.get(motion_type, {}).copy()
    if not model:
        raise ValueError(f"Unknown motion_type: {motion_type}")

    height = user_profile.get("height", 170)  # cm
    gender = user_profile.get("gender", "male").lower()
    experience = user_profile.get("experience_level", "beginner").lower()
    sport = user_profile.get("sport", motion_type)

    # Adjust angles based on height
    if height > 180:
        model["hip_angle"]["ideal"] += 5
        model["knee_angle"]["ideal"] += 5
    elif height < 160:
        model["hip_angle"]["ideal"] -= 5
        model["knee_angle"]["ideal"] -= 5

    # Adjust tolerances based on gender
    if gender == "female":
        model["knee_angle"]["tolerance"] += 5
        model["ankle_angle"]["tolerance"] += 5
        model["elbow_angle"]["tolerance"] += 5

    # Adjust based on experience level
    if experience in ["beginner", "intermediate"]:
        for k in model:
            model[k]["tolerance"] += 5  # More tolerance for less experienced athletes
    elif experience == "professional":
        for k in model:
            model[k]["tolerance"] -= 2  # Stricter for pros

    # Adjust for specific sports if needed
    # (Example: relay runners may have different ideal angles)
    if sport == "relay":
        model["elbow_angle"]["ideal"] = 140
        model["shoulder_angle"]["ideal"] = 120

    # You can add more personalized logic here based on other questionnaire data

    return model

