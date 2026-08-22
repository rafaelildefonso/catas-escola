from datetime import datetime, date, timezone
from typing import Optional, Dict, Tuple
import uuid as uuid_lib

from services.database import get_sync_db
from models.db_models import Profile, Integration


def get_user_profile(user_id: str) -> Optional[Dict]:
    try:
        uid = uuid_lib.UUID(str(user_id))
    except (ValueError, TypeError):
        return None

    db = get_sync_db()
    try:
        profile = db.query(Profile).filter(Profile.id == uid).first()
        return profile.to_dict() if profile else None
    except Exception:
        return None
    finally:
        db.close()


def get_quota_config(tier: str) -> Dict:
    configs = {
        "basic": {"limit": 500, "models": ["CATAS Basic"], "attachment_limit": 5},
        "pro": {"limit": 7500, "models": ["CATAS Basic", "CATAS Pro"], "attachment_limit": 100},
        "max": {"limit": 25000, "models": ["CATAS Basic", "CATAS Pro", "CATAS MAX"], "attachment_limit": 1000}
    }
    return configs.get(tier.lower(), configs["basic"])


def check_and_increment_quota(user_id: str, model_requested: Optional[str] = None) -> Tuple[bool, str, Dict]:
    profile_dict = get_user_profile(user_id)

    if not profile_dict:
        try:
            uuid_lib.UUID(str(user_id))
            try:
                profile_dict = create_default_profile(user_id)
            except Exception:
                profile_dict = {
                    "id": user_id,
                    "subscription_tier": "pro",
                    "quota_used": 0,
                    "rollover_credits": 0,
                    "monthly_quota_limit": 7500,
                    "last_quota_reset": datetime.now(timezone.utc).isoformat(),
                }
        except (ValueError, TypeError):
            profile_dict = {
                "id": user_id,
                "subscription_tier": "pro",
                "quota_used": 0,
                "rollover_credits": 0,
                "monthly_quota_limit": 7500,
                "last_quota_reset": datetime.now(timezone.utc).isoformat(),
            }

    tier = profile_dict.get("subscription_tier", "basic")
    config = get_quota_config(tier)

    if model_requested and model_requested not in config["models"]:
        return False, f"O modelo {model_requested} não está disponível no seu plano {tier.capitalize()}.", profile_dict

    last_reset = profile_dict.get("last_quota_reset")
    today = date.today()

    should_reset = False
    if last_reset:
        last_reset_date = datetime.fromisoformat(last_reset.replace('Z', '+00:00')).date()
        if last_reset_date.month != today.month or last_reset_date.year != today.year:
            should_reset = True
    else:
        should_reset = True

    if should_reset:
        from services.credit_service import credit_service

        quota_used = profile_dict.get("quota_used", 0)
        quota_limit = profile_dict.get("monthly_quota_limit") or config["limit"]
        current_rollover = profile_dict.get("rollover_credits", 0)

        new_rollover = credit_service.calculate_rollover(quota_used, quota_limit, current_rollover)

        profile_dict["quota_used"] = 0
        profile_dict["rollover_credits"] = new_rollover
        profile_dict["last_quota_reset"] = datetime.now(timezone.utc).isoformat()

        db = get_sync_db()
        try:
            db.query(Profile).filter(Profile.id == uuid_lib.UUID(user_id)).update({
                "quota_used": 0,
                "rollover_credits": new_rollover,
                "last_quota_reset": profile_dict["last_quota_reset"],
            })
            db.commit()
        finally:
            db.close()

    quota_limit = profile_dict.get("monthly_quota_limit") or config["limit"]
    quota_used = profile_dict.get("quota_used", 0)
    rollover_credits = profile_dict.get("rollover_credits", 0)

    total_balance = (quota_limit - quota_used) + rollover_credits

    if total_balance <= 0:
        return False, f"Seu saldo de {quota_limit} créditos acabou. Faça upgrade ou aguarde o próximo ciclo.", profile_dict

    return True, "", profile_dict


def increment_quota_usage(user_id: str, credits_to_add: int = 1) -> Dict:
    from services.credit_service import credit_service
    result = credit_service.debit_credits(user_id, credits_to_add)
    return get_user_profile(user_id)


def create_default_profile(user_id: str) -> Dict:
    uid = uuid_lib.UUID(user_id)
    default_profile = {
        "id": uid,
        "subscription_tier": "basic",
        "quota_used": 0,
        "last_quota_reset": datetime.now(timezone.utc),
    }

    db = get_sync_db()
    try:
        profile = Profile(**default_profile)
        db.add(profile)
        db.commit()
        return profile.to_dict()
    finally:
        db.close()


def update_subscription_tier(user_id: str, tier: str) -> Optional[Dict]:
    valid_plans = ["basic", "pro", "max"]
    tier = tier.lower()
    if tier not in valid_plans:
        tier = "basic"

    config = get_quota_config(tier)

    db = get_sync_db()
    try:
        profile = db.query(Profile).filter(Profile.id == uuid_lib.UUID(user_id)).first()
        if not profile:
            print(f"[Stripe] WARNING: Could not find profile for user_id={user_id} to update tier.")
            return None

        profile.subscription_tier = tier
        profile.quota_used = 0
        profile.monthly_quota_limit = config["limit"]
        profile.updated_at = datetime.now(timezone.utc)
        db.commit()

        print(f"[Stripe] User {user_id} plan updated to {tier.upper()} (quota limit: {config['limit']})")
        return profile.to_dict()
    finally:
        db.close()


def update_profile_info(user_id: str, updates: Dict) -> Optional[Dict]:
    db = get_sync_db()
    try:
        profile = db.query(Profile).filter(Profile.id == uuid_lib.UUID(user_id)).first()
        if not profile:
            return None

        for key, value in updates.items():
            if hasattr(profile, key):
                setattr(profile, key, value)

        db.commit()
        return profile.to_dict()
    finally:
        db.close()


def delete_user_data(user_id: str):
    db = get_sync_db()
    try:
        uid = uuid_lib.UUID(user_id)
        db.query(Integration).filter(Integration.user_id == uid).delete()
        db.query(Profile).filter(Profile.id == uid).delete()
        db.commit()
    finally:
        db.close()
