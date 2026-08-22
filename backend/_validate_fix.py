import json

from repositories import profiles as profiles_repo

UID = "336bd022-2a11-4af1-adba-78df31ec679f"

profile = profiles_repo.get_user_profile(UID)
print("get_user_profile:", json.dumps(profile, indent=1, default=str))

allowed, msg, prof = profiles_repo.check_and_increment_quota(UID, model_requested="CATAS Basic")
print(f"\ncheck_and_increment_quota: allowed={allowed} msg={msg!r} tier={prof.get('subscription_tier')}")

after = profiles_repo.get_user_profile(UID)
print("perfil persistido apos checagem:", after.get("subscription_tier"), "| quota_used:", after.get("quota_used"))
