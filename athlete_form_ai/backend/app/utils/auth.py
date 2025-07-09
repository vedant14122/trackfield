import httpx
from fastapi import HTTPException, Request, Depends
from jose import jwt
from jose.exceptions import JWTError

SUPABASE_PROJECT_ID = "qbrznwagzojfrazmwkjf"  # your actual project ID
JWKS_URL = f"https://{SUPABASE_PROJECT_ID}.supabase.co/auth/v1/keys"

_cached_jwks = None

async def get_jwks():
    global _cached_jwks
    if _cached_jwks is None:
        async with httpx.AsyncClient() as client:
            res = await client.get(JWKS_URL)
            res.raise_for_status()
            _cached_jwks = res.json()
    return _cached_jwks

async def verify_token(request: Request):
    auth_header = request.headers.get("Authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing or invalid token")

    token = auth_header.split(" ")[1]

    jwks = await get_jwks()
    for key in jwks["keys"]:
        try:
            payload = jwt.decode(token, key, algorithms=["RS256"], options={"verify_aud": False})
            return payload
        except JWTError:
            continue

    raise HTTPException(status_code=401, detail="Invalid or expired token")
