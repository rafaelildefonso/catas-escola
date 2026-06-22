from flask import Blueprint, request, jsonify
from core.config import settings
import stripe

webhooks_bp = Blueprint("webhooks", __name__)


@webhooks_bp.route("/api/webhooks/stripe", methods=["POST"])
def stripe_webhook():
    payload = request.get_data()
    sig_header = request.headers.get("stripe-signature")
    webhook_secret = settings.STRIPE_WEBHOOK_SECRET

    try:
        event = stripe.Webhook.construct_event(
            payload, sig_header, webhook_secret
        )
    except ValueError:
        return jsonify({"detail": "Invalid payload"}), 400
    except stripe.error.SignatureVerificationError:
        return jsonify({"detail": "Invalid signature"}), 400

    if event["type"] == "checkout.session.completed":
        session = event["data"]["object"]
        user_id = session.get("metadata", {}).get("user_id")
        plan = session.get("metadata", {}).get("plan", "basic").lower()

        valid_plans = ["basic", "pro", "max"]
        if plan not in valid_plans:
            plan = "basic"

        if user_id:
            from repositories import profiles
            profiles.update_subscription_tier(user_id, plan)

    return jsonify({"status": "success"})
