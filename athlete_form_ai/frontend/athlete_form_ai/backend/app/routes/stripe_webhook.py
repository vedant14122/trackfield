from fastapi import APIRouter, Request
import stripe
import os
from app.utils.supabase_client import supabase

router = APIRouter()

stripe.api_key = os.getenv("STRIPE_SECRET_KEY")
endpoint_secret = os.getenv("STRIPE_WEBHOOK_SECRET")

@router.post("/stripe-webhook")
async def stripe_webhook(request: Request):
    payload = await request.body()
    sig_header = request.headers.get("stripe-signature")

    try:
        event = stripe.Webhook.construct_event(
            payload, sig_header, endpoint_secret
        )
    except stripe.error.SignatureVerificationError:
        return {"status": "invalid signature"}

    if event["type"] == "checkout.session.completed":
        session = event["data"]["object"]
        customer_email = session["customer_details"]["email"]

        # Update user in Supabase
        user = supabase.table("users").select("id").eq("email", customer_email).execute()
        if user.data:
            user_id = user.data[0]["id"]
            supabase.table("users").update({"is_subscribed": True}).eq("id", user_id).execute()

    return {"status": "success"}
