import os
from dotenv import load_dotenv
import google.generativeai as genai

load_dotenv()

api_key = os.getenv("GEMINI_API_KEY") # put api key here
if not api_key:
    raise ValueError("❌ GEMINI_API_KEY not found in .env file.")
genai.configure(api_key=api_key)

model = genai.GenerativeModel("gemini-pro")

# this is an example summary, later you will generate this from actual motion data
summary = "Knee angle at push-off: 70°. Hip lean: 15°. Slight asymmetry in left foot landing."

# send the summary to Gemini and then get feedback
response = model.generate_content(
    f"Analyze this athletic motion and give feedback: {summary}"
)

print("🤖 Gemini feedback:\n", response.text)
