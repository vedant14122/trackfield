from fastapi import Depends, HTTPException, status
from app.auth import verify_token
import httpx
from datetime import datetime, timedelta
import os
from app.utils.supabase_client import supabase  # You'll need to create this

# Configuration
STRIPE_API_KEY = os.getenv("STRIPE_SECRET_KEY", "sk_test_yourkey")
CACHE_TTL_HOURS = 24  # How long to trust the cached subscription status

async def get_subscription_status(user_id: str):
    """
    Check if a user has an active subscription by:
    1. First checking the Supabase database cache
    2. If cache is invalid or missing, checking directly with Stripe
    3. Updating the cache with the latest status
    """
    # First check if we have a cached subscription status in Supabase
    response = supabase.table("users").select("*").eq("id", user_id).execute()
    
    if not response.data:
        # User doesn't exist in our users table yet
        return False
    
    user_data = response.data[0]
    
    # Check if we have a valid cached subscription status
    if user_data.get("is_subscribed") and user_data.get("last_subscription_check"):
        last_check = datetime.fromisoformat(user_data["last_subscription_check"].replace("Z", "+00:00"))
        cache_valid = datetime.now(last_check.tzinfo) - last_check < timedelta(hours=CACHE_TTL_HOURS)
        
        if cache_valid:
            # Return the cached status if it's still valid
            return user_data["is_subscribed"]
    
    # If no valid cache, check with Stripe
    customer_id = user_data.get("stripe_customer_id")
    
    # If we don't have a customer ID, we can't check subscription status
    if not customer_id:
        return False

    headers = {
        "Authorization": f"Bearer {STRIPE_API_KEY}"
    }

    # Check with Stripe API
    async with httpx.AsyncClient() as client:
        resp = await client.get(f"https://api.stripe.com/v1/subscriptions?customer={customer_id}&status=active", headers=headers)
        if resp.status_code != 200:
            raise HTTPException(status_code=502, detail="Subscription service unavailable")
        
        data = resp.json()
        active_subs = data.get("data", [])
        is_subscribed = len(active_subs) > 0
        
        # Update the cache in the database
        supabase.table("users").update({
            "is_subscribed": is_subscribed,
            "last_subscription_check": datetime.now().isoformat()
        }).eq("id", user_id).execute()
        
        return is_subscribed


async def verify_subscription(user_id: str = Depends(verify_token)):
    """
    FastAPI dependency that verifies a user has an active subscription.
    Raises 403 Forbidden if no active subscription is found.
    """
    is_active = await get_subscription_status(user_id)
    if not is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Active subscription required to access this resource"
        )
    return user_id  # return user_id for downstream use
