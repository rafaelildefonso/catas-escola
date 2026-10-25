from datetime import datetime, timezone
import logging

import stripe

from core.config import settings
from extensions import db
from models.profile import Profile

logger = logging.getLogger(__name__)

PLAN_LIMITS = {"basic": 500, "pro": 7500, "max": 25000}


def _plan_price_ids():
    return {
        "basic": settings.BASIC_PLAN_ID,
        "pro": settings.PRO_PLAN_ID,
        "max": settings.MAX_PLAN_ID,
    }


class BillingError(Exception):
    def __init__(self, message: str, status_code: int = 400):
        super().__init__(message)
        self.status_code = status_code


class BillingService:
    @staticmethod
    def criar_checkout(profile_id: str, email: str, tier: str) -> str:
        BillingService._exigir_chave()
        price_id = _plan_price_ids().get(tier)
        if not price_id:
            raise BillingError(f"O preço do plano {tier} não está configurado.", 503)

        profile = BillingService._obter_profile(profile_id)
        if profile.stripe_subscription_id and profile.subscription_status in {
            "active",
            "trialing",
            "past_due",
            "incomplete",
        }:
            raise BillingError(
                "Já existe uma assinatura. Use o portal para gerenciá-la.",
                409,
            )

        stripe.api_key = settings.STRIPE_SECRET_KEY
        if not profile.stripe_customer_id:
            customer = stripe.Customer.create(
                email=email,
                metadata={"profile_id": profile.id},
                idempotency_key=f"catas-customer-{profile.id}",
            )
            profile.stripe_customer_id = customer.id
            db.session.commit()

        session = stripe.checkout.Session.create(
            mode="subscription",
            customer=profile.stripe_customer_id,
            line_items=[{"price": price_id, "quantity": 1}],
            success_url=settings.STRIPE_SUCCESS_URL,
            cancel_url=settings.STRIPE_CANCEL_URL,
            client_reference_id=profile.id,
            metadata={"profile_id": profile.id, "plan_tier": tier},
            subscription_data={
                "metadata": {"profile_id": profile.id, "plan_tier": tier}
            },
        )
        if not session.url:
            raise BillingError("O Stripe não retornou a URL do checkout.", 502)
        return session.url

    @staticmethod
    def criar_portal(profile_id: str) -> str:
        BillingService._exigir_chave()
        profile = BillingService._obter_profile(profile_id)
        if not profile.stripe_customer_id:
            raise BillingError("Nenhuma conta de cobrança está vinculada.", 404)

        stripe.api_key = settings.STRIPE_SECRET_KEY
        session = stripe.billing_portal.Session.create(
            customer=profile.stripe_customer_id,
            return_url=settings.FRONTEND_URL,
        )
        if not session.url:
            raise BillingError("O Stripe não retornou a URL do portal.", 502)
        return session.url

    @staticmethod
    def processar_webhook(payload: bytes, assinatura: str | None):
        if not settings.STRIPE_WEBHOOK_SECRET:
            raise BillingError("Webhook do Stripe não configurado.", 503)
        if not assinatura:
            raise BillingError("Assinatura do webhook ausente.", 400)
        try:
            evento = stripe.Webhook.construct_event(
                payload,
                assinatura,
                settings.STRIPE_WEBHOOK_SECRET,
            )
        except (ValueError, stripe.error.SignatureVerificationError) as erro:
            raise BillingError("Webhook inválido.", 400) from erro

        tipo = evento["type"]
        objeto = evento["data"]["object"]
        if tipo == "checkout.session.completed":
            BillingService._processar_checkout(objeto)
        elif tipo in {
            "customer.subscription.created",
            "customer.subscription.updated",
            "customer.subscription.deleted",
        }:
            BillingService._processar_assinatura(tipo, objeto)
        elif tipo in {"invoice.paid", "invoice.payment_failed"}:
            BillingService._processar_fatura(tipo, objeto)

    @staticmethod
    def _processar_checkout(objeto):
        profile = BillingService._obter_por_metadata_ou_cliente(
            objeto.get("metadata") or {},
            objeto.get("customer"),
            objeto.get("client_reference_id"),
        )
        if not profile:
            logger.warning("Checkout Stripe sem profile correspondente.")
            return
        profile.stripe_customer_id = objeto.get("customer") or profile.stripe_customer_id
        subscription_id = objeto.get("subscription")
        if subscription_id:
            profile.stripe_subscription_id = subscription_id
        if profile.subscription_status not in {"active", "trialing", "past_due"}:
            profile.subscription_status = "incomplete"
        db.session.commit()

    @staticmethod
    def _processar_assinatura(tipo: str, assinatura):
        profile = BillingService._obter_por_metadata_ou_cliente(
            assinatura.get("metadata") or {},
            assinatura.get("customer"),
        )
        if not profile:
            logger.warning("Assinatura Stripe sem profile correspondente.")
            return

        status = assinatura.get("status") or "inactive"
        profile.subscription_status = status
        profile.stripe_customer_id = assinatura.get("customer") or profile.stripe_customer_id
        profile.stripe_subscription_id = assinatura.get("id")
        periodo = assinatura.get("current_period_end")
        profile.stripe_current_period_end = (
            datetime.fromtimestamp(periodo, timezone.utc) if periodo else None
        )

        if tipo == "customer.subscription.deleted" or status in {"canceled", "unpaid"}:
            BillingService._aplicar_plano(profile, "basic")
            profile.stripe_subscription_id = None
        elif status in {"active", "trialing", "past_due"}:
            tier = BillingService._tier_da_assinatura(assinatura)
            BillingService._aplicar_plano(profile, tier or "basic")
        db.session.commit()

    @staticmethod
    def _processar_fatura(tipo: str, fatura):
        customer_id = fatura.get("customer")
        profile = Profile.query.filter_by(stripe_customer_id=customer_id).first()
        if not profile:
            return
        subscription_id = fatura.get("subscription")
        if subscription_id and profile.stripe_subscription_id != subscription_id:
            return
        if tipo == "invoice.paid":
            profile.quota_used = 0
            profile.last_quota_reset = datetime.now(timezone.utc)
            profile.subscription_status = "active"
        else:
            profile.subscription_status = "past_due"
        db.session.commit()

    @staticmethod
    def _tier_da_assinatura(assinatura):
        items = (assinatura.get("items") or {}).get("data") or []
        price_id = items[0].get("price", {}).get("id") if items else None
        if price_id:
            return next(
                (tier for tier, configured_id in _plan_price_ids().items() if configured_id == price_id),
                None,
            )
        metadata_tier = (assinatura.get("metadata") or {}).get("plan_tier")
        return metadata_tier if metadata_tier in PLAN_LIMITS else None

    @staticmethod
    def _aplicar_plano(profile: Profile, tier: str):
        profile.subscription_tier = tier
        profile.monthly_quota_limit = PLAN_LIMITS[tier]

    @staticmethod
    def _obter_por_metadata_ou_cliente(metadata, customer_id, profile_id=None):
        profile_id = metadata.get("profile_id") or profile_id
        if profile_id:
            profile = Profile.buscar_por_id(profile_id)
            if profile:
                return profile
        if customer_id:
            return Profile.query.filter_by(stripe_customer_id=customer_id).first()
        return None

    @staticmethod
    def _obter_profile(profile_id: str) -> Profile:
        profile = Profile.buscar_por_id(profile_id)
        if not profile:
            raise BillingError("Perfil não encontrado.", 404)
        return profile

    @staticmethod
    def _exigir_chave():
        if not settings.STRIPE_SECRET_KEY:
            raise BillingError("Stripe não está configurado no servidor.", 503)
