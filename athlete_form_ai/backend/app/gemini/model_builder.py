def get_personalized_model(user_profile: dict, motion_type: str) -> dict:
    # Base models (can be extended or moved to config)
    base_models = {
        "sprint": {
            "hip_angle": {"ideal": 90, "tolerance": 15},
            "knee_angle": {"ideal": 120, "tolerance": 20},
        },
        "jump": {
            "hip_angle": {"ideal": 100, "tolerance": 10},
            "knee_angle": {"ideal": 90, "tolerance": 15},
        },
    }
    model = base_models.get(motion_type, {}).copy()
    if not model:
        raise ValueError(f"Unknown motion_type: {motion_type}")

    height = user_profile.get("height", 170)  # cm
    gender = user_profile.get("gender", "male").lower()

    # Adjust hip angle based on height
    if height > 180:
        model["hip_angle"]["ideal"] += 5
    elif height < 160:
        model["hip_angle"]["ideal"] -= 5

    # Adjust tolerance based on gender
    if gender == "female":
        model["knee_angle"]["tolerance"] += 5

    # You can add more personalized logic here based on other questionnaire data

    return model

