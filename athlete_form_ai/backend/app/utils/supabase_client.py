from supabase import create_client
import os
from dotenv import load_dotenv

load_dotenv(dotenv_path="/workspaces/trackfield/athlete_form_ai/backend/.env")

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

if not SUPABASE_URL or not SUPABASE_KEY:
    raise Exception("SUPABASE_URL and SUPABASE_KEY must be set!")

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

