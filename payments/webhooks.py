from fastapi import APIRouter, Request, HTTPException
import stripe, os

router = APIRouter()
stripe.api_key = os.getenv("STRIPE_SECRET_KEY")
endpoint_secret = os.getenv("STRIPE_WEBHOOK_SECRET")

@router.post("/stripe/webhook")
async def stripe_webhook(req: Request):
    payload = await req.body()
    sig_header = req.headers.get("Stripe-Signature")
    try:
        event = stripe.Webhook.construct_event(
            payload, sig_header, endpoint_secret
        )
    except Exception:
        raise HTTPException(status_code=400)
    return {"received": True}
