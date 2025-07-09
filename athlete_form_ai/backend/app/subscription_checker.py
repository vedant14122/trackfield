from fastapi import Depends, HTTPException, status
from app.auth import verify_token
import httpx  # For calling Stripe API or your subscription backend

# Example: Fetch subscription status from Stripe (or your DB)

STRIPE_API_KEY = "sk_test_yourkey"  # ideally from env
STRIPE_CUSTOMER_ID_FIELD = "stripe_customer_id"  # field on your user data

async def get_subscription_status(user_id: str):
    # You would normally fetch from your DB user data to get Stripe customer id
    # Here, let's pretend we fetch user data with that id:
    # For example purposes, mock user info:
    user_data = {
        "id": user_id,
        "stripe_customer_id": "cus_abc123"
    }
    
    customer_id = user_data.get(STRIPE_CUSTOMER_ID_FIELD)
    if not customer_id:
        return False

    headers = {
        "Authorization": f"Bearer {STRIPE_API_KEY}"
    }

    async with httpx.AsyncClient() as client:
        resp = await client.get(f"https://api.stripe.com/v1/subscriptions?customer={customer_id}&status=active", headers=headers)
        if resp.status_code != 200:
            raise HTTPException(status_code=502, detail="Subscription service unavailable")
        data = resp.json()
        active_subs = data.get("data", [])
        return len(active_subs) > 0


async def verify_subscription(user_id: str = Depends(verify_token)):
    is_active = await get_subscription_status(user_id)
    if not is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Active subscription required to access this resource"
        )
    return user_id  # return user_id for downstream use
