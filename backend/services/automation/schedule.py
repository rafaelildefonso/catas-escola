"""UTC schedule validation and next-fire calculation for saved automations."""

from datetime import datetime, timedelta, timezone


def _cron_values(field: str, minimum: int, maximum: int) -> set[int]:
    values = set()
    for part in field.split(","):
        base, separator, step_text = part.partition("/")
        try:
            step = int(step_text) if separator else 1
            if step < 1:
                raise ValueError
            if base == "*":
                start, end = minimum, maximum
            elif "-" in base:
                left, right = base.split("-", 1)
                start, end = int(left), int(right)
            else:
                start = int(base)
                end = maximum if separator else start
            if not minimum <= start <= end <= maximum:
                raise ValueError
        except (ValueError, TypeError) as exc:
            raise ValueError("Expressão cron inválida") from exc
        values.update(range(start, end + 1, step))
    return values


def next_run_at(trigger: dict, after: datetime | None = None) -> datetime | None:
    kind = trigger.get("type", "manual")
    if kind in {"manual", "webhook"}:
        return None
    now = after or datetime.now(timezone.utc)
    if now.tzinfo is None:
        now = now.replace(tzinfo=timezone.utc)
    now = now.astimezone(timezone.utc)
    if kind == "schedule":
        minutes = trigger.get("interval_minutes")
        if isinstance(minutes, bool) or not isinstance(minutes, int) or not 1 <= minutes <= 10080:
            raise ValueError("interval_minutes deve ser entre 1 e 10080")
        return now + timedelta(minutes=minutes)
    if kind != "cron":
        raise ValueError("Tipo de gatilho inválido")
    fields = (trigger.get("cron_expression") or "").split()
    if len(fields) != 5:
        raise ValueError("Cron deve ter cinco campos em UTC")
    minute, hour, day, month, weekday = (
        _cron_values(fields[0], 0, 59),
        _cron_values(fields[1], 0, 23),
        _cron_values(fields[2], 1, 31),
        _cron_values(fields[3], 1, 12),
        _cron_values(fields[4], 0, 7),
    )
    first_day = now.replace(hour=0, minute=0, second=0, microsecond=0)
    for day_offset in range(366 * 4):
        current_day = first_day + timedelta(days=day_offset)
        dom_match = current_day.day in day
        dow_match = ((current_day.weekday() + 1) % 7) in weekday or (
            current_day.weekday() == 6 and 7 in weekday
        )
        if fields[2] == "*":
            date_match = dow_match
        elif fields[4] == "*":
            date_match = dom_match
        else:
            date_match = dom_match or dow_match
        if current_day.month not in month or not date_match:
            continue
        for hour_value in sorted(hour):
            for minute_value in sorted(minute):
                candidate = current_day.replace(hour=hour_value, minute=minute_value)
                if candidate > now:
                    return candidate
    raise ValueError("Cron não gera execução nos próximos quatro anos")
