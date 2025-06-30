import os
from dotenv import load_dotenv
import google.generativeai as genai

load_dotenv()
genai.configure(api_key=os.getenv("GEMINI_API_KEY"))
model = genai.GenerativeModel("gemini-pro")

# Replace this with actual summary from 3D keypoints
summary = "Knee angle at push-off: 70°. Hip lean: 15°. Slight asymmetry in left foot landing."

response = model.generate_content(
    f"Analyze this athletic motion and give feedback: {summary}"
)

print("Gemini feedback:\n", response.text)
