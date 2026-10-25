"""Revise uma automação existente a partir de uma instrução em linguagem natural."""

import asyncio
import json
import os
import re
from datetime import datetime, timedelta, timezone as datetime_timezone
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from models.integration import Integration
from services.automacao.module_registry import get_module_spec
from services.automacao.pipeline_service import AutomationPipelineService
from services.automation.atualizar_automation_service import AtualizarAutomationService
from services.automation.buscar_automation_service import BuscarAutomationService


class RevisarAutomationService:
    @staticmethod
    def _novo_agendamento(instruction: str):
        interval = AutomationPipelineService._extrair_intervalo(instruction)
        if interval:
            return interval

        daily = re.search(
            r"\b(?:todos os dias|todo dia|diariamente)\b.*?"
            r"\b(?:às|as)\s*(\d{1,2})(?:\s*(?:h|:)\s*(\d{1,2}))?\s*h?\b",
            instruction.casefold(),
        )
        if not daily:
            return None
        hour = int(daily.group(1))
        minute = int(daily.group(2) or 0)
        if not 0 <= hour <= 23 or not 0 <= minute <= 59:
            raise ValueError("Informe um horário válido, como ‘todos os dias às 9h’.")

        timezone_name = os.getenv("AUTOMATION_TIMEZONE", "America/Sao_Paulo")
        try:
            timezone = ZoneInfo(timezone_name)
        except ZoneInfoNotFoundError as exc:
            if timezone_name != "America/Sao_Paulo":
                raise ValueError(
                    "O fuso horário das automações não está disponível."
                ) from exc
            # O Brasil não adota horário de verão desde 2019. Este fallback
            # mantém o ambiente Windows funcional mesmo sem o pacote tzdata.
            timezone = datetime_timezone(timedelta(hours=-3))
        today = datetime.now(timezone)
        local_time = datetime(
            today.year,
            today.month,
            today.day,
            hour,
            minute,
            tzinfo=timezone,
        )
        utc_time = local_time.astimezone(datetime_timezone.utc)
        return {
            "type": "cron",
            "cron_expression": f"{utc_time.minute} {utc_time.hour} * * *",
        }

    @staticmethod
    def _altera_somente_agendamento(instruction: str) -> bool:
        main_request = re.split(
            r"\b(?:e\s+)?mantenha\b|\bsem alterar\b",
            instruction.casefold(),
            maxsplit=1,
        )[0]
        content_changes = (
            "destinatário",
            "destinatario",
            "assunto",
            "mensagem",
            "corpo",
            "adicione",
            "remova",
            "exclua",
            "troque",
        )
        return not any(term in main_request for term in content_changes)

    @staticmethod
    def executar(automation_id: str, user_id: str, instruction: str):
        if (
            not isinstance(instruction, str)
            or not instruction.strip()
            or len(instruction) > 2000
        ):
            raise ValueError("Descreva a alteração em até 2000 caracteres")
        current = BuscarAutomationService.executar(automation_id, user_id)
        instruction = instruction.strip()
        new_trigger = RevisarAutomationService._novo_agendamento(instruction)
        if new_trigger and RevisarAutomationService._altera_somente_agendamento(
            instruction
        ):
            return AtualizarAutomationService.executar(
                automation_id,
                {"trigger": new_trigger},
                user_id,
            )

        prompt = (
            "Atualize esta automação conforme o pedido do usuário. Preserve os dados e passos "
            "que ele não pediu para alterar. Retorne o plano completo atualizado.\n"
            f"Automação atual: {json.dumps({'name': current.name, 'description': current.description, 'trigger': current.trigger, 'steps': current.steps}, ensure_ascii=False)}\n"
            f"Pedido: {instruction}"
        )
        current_modules = [
            step.get("module_id")
            for step in current.steps
            if isinstance(step, dict) and step.get("module_id")
        ]
        result = asyncio.run(
            AutomationPipelineService().process(
                prompt,
                user_id=user_id,
                preferred_modules=current_modules,
            )
        )
        if result.get("pipeline_status") != "completed":
            raise ValueError(
                result.get("message") or "Não consegui revisar a automação"
            )
        plan = result["workflow_json"]
        required = {
            spec.provider
            for step in plan["steps"]
            if (spec := get_module_spec(step.get("module_id"))) and spec.provider
        }
        connected = {
            item.provider
            for item in Integration.query.filter_by(
                user_id=user_id, is_connected=True
            ).all()
        }
        if required - connected:
            raise ValueError(
                "Conecte as integrações necessárias antes de ativar esta alteração: "
                + ", ".join(sorted(required - connected))
            )
        return AtualizarAutomationService.executar(
            automation_id,
            {
                "name": plan["name"],
                "description": plan.get("description") or current.description,
                "trigger": plan.get("trigger") or current.trigger,
                "steps": plan["steps"],
            },
            user_id,
        )
