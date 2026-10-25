"""Validate client-editable fields without allowing ownership or run state changes."""

from pydantic import ValidationError

from models.automation_plan_schema import AutomationPlan
from services.automation.schedule import next_run_at

EDITABLE = {"name", "description", "trigger", "steps", "status"}
STATUSES = {"draft", "active", "paused"}


def validate_automation_data(data, *, creating=False, existing=None):
    if not isinstance(data, dict) or not data:
        raise ValueError("Dados são obrigatórios")
    unknown = set(data) - EDITABLE - ({"user_id"} if creating else set())
    if unknown:
        raise ValueError("Campos não permitidos: " + ", ".join(sorted(unknown)))
    name = data.get("name", existing.name if existing else None)
    steps = data.get("steps", existing.steps if existing else None)
    trigger = data.get("trigger", existing.trigger if existing else {"type": "manual"})
    if not isinstance(name, str) or not 1 <= len(name.strip()) <= 255:
        raise ValueError("Nome deve ter entre 1 e 255 caracteres")
    if not isinstance(steps, list) or len(steps) > 50:
        raise ValueError("Steps devem ser uma lista de até 50 itens")
    if not isinstance(trigger, dict):
        raise ValueError("Trigger deve ser um objeto")
    try:
        plan = AutomationPlan(name=name, steps=steps, trigger=trigger)
    except ValidationError as exc:
        raise ValueError("Plano de automação inválido: " + str(exc)) from exc
    status = data.get("status", existing.status if existing else "draft")
    if status not in STATUSES:
        raise ValueError("Status inválido")
    due = next_run_at(plan.trigger.model_dump()) if status == "active" else None
    fields = {key: data[key] for key in EDITABLE if key in data}
    fields["name"] = name.strip()
    fields["steps"] = [step.model_dump() for step in plan.steps]
    fields["trigger"] = plan.trigger.model_dump()
    fields["next_run_at"] = due
    return fields
