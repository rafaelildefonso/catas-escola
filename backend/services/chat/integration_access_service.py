"""Guards chat actions behind the integrations they require.

The model can suggest a plan, but it must never be the authority for whether an
external account is connected.  This helper is used immediately before a plan
is displayed/executed and again when the user confirms it.
"""

from services.automacao.module_registry import get_module_spec


class IntegrationAccessService:
    """Derive integration requirements and build a safe blocked response."""

    _PROVIDER_BY_INTENT = {
        "email_draft": "google_gmail",
        "calendar_create_event": "google_calendar",
        "task_create": "google_sheets",
        "spreadsheet_create": "google_sheets",
    }

    _DISPLAY_NAMES = {
        "google_gmail": "Gmail",
        "google_calendar": "Google Calendar",
        "google_sheets": "Google Sheets",
        "google_drive": "Google Drive",
        "google_docs": "Google Docs",
        "google_meet": "Google Meet",
        "whatsapp": "WhatsApp",
        "notion": "Notion",
        "slack": "Slack",
    }

    @classmethod
    def required_providers(cls, action_details: dict | None, intent: str | None = None) -> list[str]:
        providers = set()
        for step in (action_details or {}).get("steps", []):
            spec = get_module_spec(step.get("module_id"))
            if spec and spec.provider:
                providers.add(spec.provider)

        if not providers and intent in cls._PROVIDER_BY_INTENT:
            providers.add(cls._PROVIDER_BY_INTENT[intent])
        return sorted(providers)

    @classmethod
    def blocked_response(
        cls,
        action_details: dict | None,
        intent: str | None,
        connected_providers: list[str] | set[str],
        active_providers: list[str] | set[str],
    ) -> dict | None:
        """Return a blocking integration request, or ``None`` when allowed."""
        required = cls.required_providers(action_details, intent)
        if not required:
            return None

        connected = set(connected_providers or [])
        active = set(active_providers or [])
        missing = [provider for provider in required if provider not in connected]
        inactive = [provider for provider in required if provider in connected and provider not in active]

        if not missing and not inactive:
            return None

        components = []
        for provider in missing:
            name = cls._DISPLAY_NAMES.get(provider, provider.replace("_", " ").title())
            components.append({
                "type": "integration_connect",
                "provider": provider,
                "provider_name": name,
                "action": "connect",
                "message": f"Conecte o {name} para continuar com esta ação.",
                "readonly": False,
            })
        for provider in inactive:
            name = cls._DISPLAY_NAMES.get(provider, provider.replace("_", " ").title())
            components.append({
                "type": "integration_connect",
                "provider": provider,
                "provider_name": name,
                "action": "activate_in_chat",
                "message": f"Ative o {name} neste chat para continuar com esta ação.",
                "readonly": False,
            })

        if missing:
            text = "Antes de continuar, conecte a integração necessária abaixo. Nenhuma ação foi executada."
        else:
            text = "Antes de continuar, ative a integração abaixo neste chat. Nenhuma ação foi executada."

        return {
            "response_text": text,
            "action_triggered": False,
            "action_details": {},
            "components": components,
            "status": "requires_action",
        }
