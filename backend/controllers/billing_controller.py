import logging

import stripe
from flask import g, jsonify, request

from core.security import login_required
from services.billing.billing_service import BillingError, BillingService

logger = logging.getLogger(__name__)


class BillingController:
    @staticmethod
    @login_required
    def checkout():
        dados = request.get_json(silent=True) or {}
        tier = dados.get("plan_tier")
        if tier not in {"basic", "pro", "max"}:
            return jsonify({"detail": "Plano inválido."}), 400
        try:
            url = BillingService.criar_checkout(
                g.current_user["id"],
                g.current_user.get("email", ""),
                tier,
                request.headers.get("Origin"),
            )
            return jsonify({"url": url}), 200
        except BillingError as erro:
            return jsonify({"detail": str(erro)}), erro.status_code
        except stripe.StripeError:
            logger.exception("Falha ao criar sessão de checkout Stripe.")
            return jsonify({"detail": "Não foi possível iniciar o checkout."}), 502

    @staticmethod
    @login_required
    def portal():
        try:
            url = BillingService.criar_portal(g.current_user["id"])
            return jsonify({"url": url}), 200
        except BillingError as erro:
            return jsonify({"detail": str(erro)}), erro.status_code
        except stripe.StripeError:
            logger.exception("Falha ao criar sessão do portal Stripe.")
            return jsonify({"detail": "Não foi possível abrir o portal de cobrança."}), 502

    @staticmethod
    @login_required
    def status():
        from models.profile import Profile

        profile = Profile.buscar_por_id(g.current_user["id"])
        if not profile:
            return jsonify({"detail": "Perfil não encontrado."}), 404
        return jsonify({
            "subscription_tier": profile.subscription_tier,
            "subscription_status": profile.subscription_status,
            "has_billing_subscription": bool(profile.stripe_subscription_id),
            "current_period_end": (
                profile.stripe_current_period_end.isoformat()
                if profile.stripe_current_period_end
                else None
            ),
        }), 200

    @staticmethod
    @login_required
    def confirmar_checkout(session_id):
        try:
            profile = BillingService.confirmar_checkout(
                g.current_user["id"], session_id
            )
            return jsonify({
                "subscription_tier": profile.subscription_tier,
                "subscription_status": profile.subscription_status,
            }), 200
        except BillingError as erro:
            return jsonify({"detail": str(erro)}), erro.status_code
        except stripe.StripeError:
            logger.exception("Falha ao confirmar sessão de checkout Stripe.")
            return jsonify({"detail": "Não foi possível confirmar o pagamento."}), 502

    @staticmethod
    def webhook():
        assinatura = request.headers.get("Stripe-Signature")
        try:
            BillingService.processar_webhook(request.get_data(), assinatura)
            return jsonify({"received": True}), 200
        except BillingError as erro:
            return jsonify({"detail": str(erro)}), erro.status_code
        except stripe.StripeError:
            logger.exception("Falha ao processar webhook Stripe.")
            return jsonify({"detail": "Falha ao processar o evento de cobrança."}), 502
