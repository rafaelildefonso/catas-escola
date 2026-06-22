from flask import Blueprint, request, jsonify
from core.config import settings
from core.security import get_current_user
from core.errors import sanitize_error
import stripe

payments_bp = Blueprint("payments", __name__, url_prefix="/api/v1/payments")

stripe.api_key = settings.STRIPE_SECRET_KEY

PLAN_PRICE_IDS = {
    "basic": settings.BASIC_PLAN_ID,
    "pro": settings.PRO_PLAN_ID,
    "max": settings.MAX_PLAN_ID,
}


@payments_bp.route("/create-checkout-session", methods=["POST"])
def create_checkout_session():
    current_user = get_current_user()
    if not current_user:
        return jsonify({"detail": "Não autorizado"}), 401

    data = request.get_json(silent=True) or {}
    price_id = data.get("price_id")
    if not price_id:
        return jsonify({"detail": "Price ID required"}), 400

    try:
        checkout_session = stripe.checkout.Session.create(
            customer_email=current_user["email"],
            client_reference_id=current_user["id"],
            line_items=[{'price': price_id, 'quantity': 1}],
            mode='subscription',
            success_url=f"{settings.APP_DEEP_LINK_SCHEME}://payment-success?success=true",
            cancel_url=f"{settings.APP_DEEP_LINK_SCHEME}://payment-cancel?canceled=true",
            metadata={"user_id": current_user["id"], "plan": "pro"}
        )
        return jsonify({"url": checkout_session.url})
    except Exception as e:
        return jsonify({"detail": sanitize_error(e, "Erro ao processar pagamento")}), 500


@payments_bp.route("/create-subscription", methods=["POST"])
def create_subscription():
    current_user = get_current_user()
    if not current_user:
        return jsonify({"detail": "Não autorizado"}), 401

    data = request.get_json(silent=True) or {}
    price_id = data.get("price_id")
    if not price_id:
        return jsonify({"detail": "Price ID required"}), 400

    user_id = current_user["id"]
    email = current_user["email"]

    try:
        customers = stripe.Customer.list(email=email, limit=1)
        if customers.data:
            customer_id = customers.data[0].id
        else:
            customer = stripe.Customer.create(email=email, metadata={"user_id": user_id})
            customer_id = customer.id

        subscription = stripe.Subscription.create(
            customer=customer_id,
            items=[{'price': price_id}],
            payment_behavior='default_incomplete',
            payment_settings={'save_default_payment_method': 'on_subscription'},
            expand=['latest_invoice.payment_intent'],
            metadata={"user_id": user_id}
        )

        invoice = subscription.latest_invoice
        payment_intent = invoice.payment_intent

        return jsonify({
            "subscriptionId": subscription.id,
            "clientSecret": payment_intent.client_secret
        })
    except Exception as e:
        return jsonify({"detail": sanitize_error(e, "Erro ao criar assinatura")}), 500


@payments_bp.route("/create-plan-checkout", methods=["POST"])
def create_plan_checkout():
    current_user = get_current_user()
    if not current_user:
        return jsonify({"detail": "Não autorizado"}), 401

    data = request.get_json(silent=True) or {}
    plan = data.get("plan", "").lower()
    valid_plans = ["basic", "pro", "max"]

    if plan not in valid_plans:
        return jsonify({"detail": f"Plano inválido. Use: {', '.join(valid_plans)}"}), 400

    price_id = PLAN_PRICE_IDS.get(plan)
    if not price_id:
        return jsonify({"detail": f"Price ID não configurado para o plano {plan}"}), 400

    try:
        checkout_session = stripe.checkout.Session.create(
            customer_email=current_user["email"],
            client_reference_id=current_user["id"],
            line_items=[{'price': price_id, 'quantity': 1}],
            mode='subscription',
            success_url=f"{settings.APP_DEEP_LINK_SCHEME}://payment-success?plan={plan}",
            cancel_url=f"{settings.APP_DEEP_LINK_SCHEME}://payment-cancel?plan={plan}",
            metadata={"user_id": current_user["id"], "plan": plan}
        )
        return jsonify({"url": checkout_session.url})
    except Exception as e:
        return jsonify({"detail": sanitize_error(e, "Erro ao criar checkout")}), 500


@payments_bp.route("/create-portal-session", methods=["POST"])
def create_portal_session():
    current_user = get_current_user()
    if not current_user:
        return jsonify({"detail": "Não autorizado"}), 401

    email = current_user["email"]

    try:
        customers = stripe.Customer.list(email=email, limit=1)
        if not customers.data:
            customer = stripe.Customer.create(email=email, metadata={"user_id": current_user["id"]})
            customer_id = customer.id
        else:
            customer_id = customers.data[0].id

        portal_session = stripe.billing_portal.Session.create(
            customer=customer_id,
            return_url=f"{settings.APP_DEEP_LINK_SCHEME}://settings",
        )

        return jsonify({"url": portal_session.url})
    except Exception as e:
        return jsonify({"detail": sanitize_error(e, "Erro ao criar portal")}), 500
