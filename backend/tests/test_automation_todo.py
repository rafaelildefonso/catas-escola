import asyncio
import base64
from datetime import datetime, timedelta, timezone
from email import message_from_bytes
from types import SimpleNamespace

import pytest
from jose import jwt

from core.config import settings
from core.crypto import encrypt_value
from models.automation import Automation
from models.automation_run import AutomationRun
from models.integration import Integration
from models.notification import Notification
from models.profile import Profile
from services.automation.schedule import next_run_at
from services.automation.scheduler import tick
from services.integration.google_auth_service import _build_state, decode_state
from worker.modules.gmail_modules import _build_rfc2822_message
from worker.runner import AutomationRunner


def _headers(user_id):
    token = jwt.encode(
        {
            "user_id": user_id,
            "email": "test@example.com",
            "exp": datetime.now(timezone.utc) + timedelta(minutes=10),
        },
        settings.JWT_SECRET_KEY,
        algorithm="HS256",
    )
    return {"Authorization": f"Bearer {token}"}


def _payload():
    return {
        "name": "Avisar por email",
        "status": "active",
        "trigger": {"type": "schedule", "interval_minutes": 60},
        "steps": [
            {
                "step_id": "email_1",
                "module_id": "gmail.send_email",
                "params": {"to": "a@example.com", "subject": "Aviso", "body": "Olá"},
            }
        ],
    }


def test_automation_endpoints_require_auth_and_scope(client):
    owner = Profile()
    owner.salvar()
    other = Profile()
    other.salvar()
    assert client.get("/api/v1/automations").status_code == 401
    response = client.post(
        "/api/v1/automations",
        json={**_payload(), "user_id": other.id},
        headers=_headers(owner.id),
    )
    assert response.status_code == 201
    automation_id = response.json["id"]
    assert response.json["user_id"] == owner.id
    assert response.json["next_run_at"] is not None
    assert (
        client.get(
            f"/api/v1/automations/{automation_id}", headers=_headers(other.id)
        ).status_code
        == 404
    )
    assert (
        client.put(
            f"/api/v1/automations/{automation_id}",
            json={"status": "paused"},
            headers=_headers(other.id),
        ).status_code
        == 404
    )
    assert (
        client.delete(
            f"/api/v1/automations/{automation_id}", headers=_headers(other.id)
        ).status_code
        == 404
    )
    assert (
        client.get(
            "/api/v1/automations?status=active", headers=_headers(owner.id)
        ).json[0]["id"]
        == automation_id
    )
    assert (
        client.get("/api/v1/automations?status=active", headers=_headers(other.id)).json
        == []
    )
    assert (
        client.put(
            f"/api/v1/automations/{automation_id}",
            json={"user_id": other.id},
            headers=_headers(owner.id),
        ).status_code
        == 400
    )


def test_cron_and_interval_next_run():
    now = datetime(2026, 10, 23, 8, 45, tzinfo=timezone.utc)
    assert next_run_at(
        {"type": "cron", "cron_expression": "0 9 * * 1-5"}, now
    ) == datetime(2026, 10, 23, 9, tzinfo=timezone.utc)
    assert next_run_at(
        {"type": "schedule", "interval_minutes": 30}, now
    ) == now + timedelta(minutes=30)


def test_scheduler_claims_once(monkeypatch):
    profile = Profile()
    profile.salvar()
    automation = Automation(
        user_id=profile.id,
        name="A",
        status="active",
        trigger={"type": "schedule", "interval_minutes": 10},
        steps=[],
        next_run_at=datetime.now(timezone.utc).replace(tzinfo=None)
        - timedelta(minutes=1),
    )
    automation.salvar()
    calls = []
    monkeypatch.setattr(
        "services.automation.scheduler.dispatch_automation",
        lambda *args: calls.append(args),
    )
    tick()
    tick()
    assert len(calls) == 1
    assert automation.next_run_at > datetime.now(timezone.utc).replace(tzinfo=None)


def test_manual_run_creates_owned_run(client, monkeypatch):
    profile = Profile()
    profile.salvar()
    automation = Automation(
        user_id=profile.id,
        name="Email",
        status="active",
        trigger={"type": "manual"},
        steps=[],
    )
    automation.salvar()
    response = SimpleNamespace(status_code=202, raise_for_status=lambda: None)

    class FakeClient:
        def __init__(self, **kwargs):
            pass

        def __enter__(self):
            return self

        def __exit__(self, *args):
            pass

        def post(self, *args, **kwargs):
            return response

    monkeypatch.setattr("services.automation.dispatch.httpx.Client", FakeClient)
    result = client.post(
        f"/api/v1/automations/{automation.id}/run", headers=_headers(profile.id)
    )
    assert result.status_code == 202
    run = AutomationRun.query.filter_by(id=result.json["id"]).one()
    assert run.automation_id == automation.id
    assert run.user_id == profile.id


def test_manual_run_reports_worker_failure(client, monkeypatch):
    profile = Profile()
    profile.salvar()
    automation = Automation(
        user_id=profile.id,
        name="Email",
        status="active",
        trigger={"type": "manual"},
        steps=[],
    )
    automation.salvar()

    class FailingClient:
        def __init__(self, **kwargs):
            pass

        def __enter__(self):
            return self

        def __exit__(self, *args):
            pass

        def post(self, *args, **kwargs):
            raise ValueError("worker down")

    notifications = []
    monkeypatch.setattr("services.automation.dispatch.httpx.Client", FailingClient)
    monkeypatch.setattr(
        "services.notification.notification_service.NotificationService.notify_run",
        lambda run_id, status: notifications.append((run_id, status)),
    )
    response = client.post(
        f"/api/v1/automations/{automation.id}/run", headers=_headers(profile.id)
    )
    assert response.status_code == 503
    assert response.json["status"] == "failed"
    assert notifications == [(response.json["id"], "failed")]


def test_gmail_message_contains_attachment():
    encoded = _build_rfc2822_message(
        "a@example.com",
        "Relatório",
        "Segue",
        attachments=[("relatorio.pdf", "application/pdf", b"%PDF-test")],
    )
    message = message_from_bytes(base64.urlsafe_b64decode(encoded))
    parts = list(message.walk())
    assert any(
        part.get_filename() == "relatorio.pdf"
        and part.get_payload(decode=True) == b"%PDF-test"
        for part in parts
    )


def test_gmail_rejects_header_injection():
    with pytest.raises(ValueError, match="Cabeçalho"):
        _build_rfc2822_message("a@example.com\nBcc: hidden@example.com", "Aviso", "Olá")


def test_schedule_trigger_to_gmail_execution(monkeypatch):
    sent = []

    class FakeClient:
        def __init__(self, **kwargs):
            pass

        async def __aenter__(self):
            return self

        async def __aexit__(self, *args):
            pass

        async def post(self, *args, **kwargs):
            sent.append(kwargs["json"]["raw"])
            return SimpleNamespace(
                status_code=200,
                raise_for_status=lambda: None,
                json=lambda: {"id": "msg-1", "threadId": "thread-1"},
            )

    monkeypatch.setattr(
        "worker.modules.gmail_modules.get_google_access_token", lambda *args: "token"
    )
    monkeypatch.setattr("worker.modules.gmail_modules.httpx.AsyncClient", FakeClient)
    plan = {
        "name": "Avisar",
        "steps": [
            {
                "step_id": "send",
                "module_id": "gmail.send_email",
                "params": {
                    "to": "{{trigger.email}}",
                    "subject": "Aviso",
                    "body": "Olá",
                },
            }
        ],
    }
    context = asyncio.run(
        AutomationRunner().run_plan(
            plan,
            trigger_payload={"email": "user@example.com"},
            user_id="owner",
        )
    )
    assert context["send"]["message_id"] == "msg-1"
    assert (
        message_from_bytes(base64.urlsafe_b64decode(sent[0]))["To"]
        == "user@example.com"
    )


def test_notification_is_scoped(client):
    owner = Profile()
    owner.salvar()
    other = Profile()
    other.salvar()
    notification = Notification(
        user_id=owner.id, title="Feita", body="Automação concluída"
    )
    from extensions import db

    db.session.add(notification)
    db.session.commit()
    assert (
        len(client.get("/api/v1/notifications", headers=_headers(owner.id)).json) == 1
    )
    assert client.get("/api/v1/notifications", headers=_headers(other.id)).json == []
    assert (
        client.patch(
            f"/api/v1/notifications/{notification.id}/read", headers=_headers(other.id)
        ).status_code
        == 404
    )
    assert (
        client.patch(
            f"/api/v1/notifications/{notification.id}/read", headers=_headers(owner.id)
        ).json["is_read"]
        is True
    )


def test_integration_api_scopes_records_and_hides_tokens(client):
    owner = Profile()
    owner.salvar()
    other = Profile()
    other.salvar()
    integration = Integration(
        user_id=owner.id,
        provider="google_gmail",
        is_connected=True,
        access_token="encrypted-access",
        refresh_token="encrypted-refresh",
    )
    integration.salvar()
    url = f"/api/v1/integrations/{integration.id}"

    assert client.get("/api/v1/integrations").status_code == 401
    assert client.get(url).status_code == 401
    assert client.get(url, headers=_headers(other.id)).status_code == 404
    assert (
        client.put(url, json={"settings": {}}, headers=_headers(other.id)).status_code
        == 404
    )
    assert client.delete(url, headers=_headers(other.id)).status_code == 404
    assert client.get("/api/v1/integrations", headers=_headers(other.id)).json == []

    record = client.get(url, headers=_headers(owner.id)).json
    assert record["provider"] == "google_gmail"
    assert "access_token" not in record and "refresh_token" not in record
    assert (
        "access_token"
        not in client.get("/api/v1/integrations", headers=_headers(owner.id)).json[0]
    )
    assert (
        client.put(
            url, json={"access_token": "forged"}, headers=_headers(owner.id)
        ).status_code
        == 400
    )
    assert Integration.buscar_por_id(integration.id).access_token == "encrypted-access"
    assert (
        client.post(
            "/api/v1/integrations",
            json={"provider": "google_drive", "user_id": other.id},
            headers=_headers(owner.id),
        ).status_code
        == 400
    )


def test_google_oauth_state_rejects_tampering():
    state = _build_state("owner", "google_gmail")
    assert decode_state(state) == ("owner", "google_gmail")
    with pytest.raises(ValueError, match="OAuth"):
        decode_state(state + "tampered")


def test_google_refresh_persists_new_expiry(app, monkeypatch):
    from worker.repositorio_dados import obter_integracao

    owner = Profile()
    owner.salvar()
    integration = Integration(
        user_id=owner.id,
        provider="google_gmail",
        is_connected=True,
        access_token=encrypt_value("old-access"),
        refresh_token=encrypt_value("old-refresh"),
        token_expires_at=datetime.now(timezone.utc) - timedelta(minutes=1),
    )
    integration.salvar()
    monkeypatch.setattr("worker.repositorio_dados.obter_app", lambda: app)
    monkeypatch.setattr(
        "core.oauth_token_service.refresh_google_tokens",
        lambda token: {"access_token": "new-access", "expires_in": 3600},
    )
    result = obter_integracao(owner.id, "google_gmail")
    assert result["access_token"] == "new-access"
    assert Integration.buscar_por_id(integration.id).token_expires_at > datetime.now(
        timezone.utc
    ).replace(tzinfo=None)


def test_chat_saves_recurring_ai_plan_without_running_immediately(monkeypatch):
    from services.chat.enviar_mensagem_chat_service import EnviarMensagemChatService

    owner = Profile()
    owner.salvar()
    plan = {
        "name": "Resumo periódico",
        "description": "Repetir tarefa",
        "trigger": {"type": "schedule", "interval_minutes": 30},
        "steps": [
            {"step_id": "wait_1", "module_id": "flow.wait", "params": {"duration": 1}}
        ],
    }

    async def fake_pipeline(**kwargs):
        return {"pipeline_status": "completed", "workflow_json": plan}

    def unexpected_dispatch(*args):
        raise AssertionError("Agendamento não deve executar imediatamente")

    monkeypatch.setattr(
        "services.chat.enviar_mensagem_chat_service.pipeline_service.process",
        fake_pipeline,
    )
    monkeypatch.setattr(
        "services.automation.dispatch.dispatch_automation", unexpected_dispatch
    )
    response = EnviarMensagemChatService._fluxo_meta_automacao(
        user_id=owner.id,
        message="Crie uma automação a cada 30 minutos",
        session_id="unused",
        is_new_session=False,
        new_title="",
        is_onboarding_session=False,
        attachment_urls=[],
        model="CATAS Basic",
        ai_result={},
    )
    saved = Automation.query.filter_by(id=response["saved_automation_id"]).one()
    assert saved.status == "active"
    assert saved.trigger["interval_minutes"] == 30
    assert saved.next_run_at is not None
    assert response["actionTriggered"] is False


def test_chat_executes_manual_ai_plan_after_saving(monkeypatch):
    from services.chat.enviar_mensagem_chat_service import EnviarMensagemChatService

    owner = Profile()
    owner.salvar()
    plan = {
        "name": "Ação imediata",
        "trigger": {"type": "manual"},
        "steps": [
            {"step_id": "wait_1", "module_id": "flow.wait", "params": {"duration": 1}}
        ],
    }

    async def fake_pipeline(**kwargs):
        return {"pipeline_status": "completed", "workflow_json": plan}

    dispatched = []
    monkeypatch.setattr(
        "services.chat.enviar_mensagem_chat_service.pipeline_service.process",
        fake_pipeline,
    )
    monkeypatch.setattr(
        "services.automation.dispatch.dispatch_automation",
        lambda automation_id, user_id, run_type: (
            dispatched.append((automation_id, user_id, run_type))
            or SimpleNamespace(id="run-1", status="running")
        ),
    )
    response = EnviarMensagemChatService._fluxo_meta_automacao(
        user_id=owner.id,
        message="Crie uma automação agora",
        session_id="unused",
        is_new_session=False,
        new_title="",
        is_onboarding_session=False,
        attachment_urls=[],
        model="CATAS Basic",
        ai_result={},
    )
    assert Automation.query.filter_by(id=response["saved_automation_id"]).one()
    assert dispatched == [(response["saved_automation_id"], owner.id, "chat")]
    assert response["automation_id"] == "run-1"
    assert response["actionTriggered"] is True


def test_ai_pipeline_keeps_schedule_instead_of_manual(monkeypatch):
    from services.automacao.pipeline_service import AutomationPipelineService

    answers = iter(
        [
            '{"valido": true, "motivo": ""}',
            '{"objetivo": "Esperar", "trigger": {"type": "schedule", "interval_minutes": 30}}',
            '{"nodulos": ["flow.wait"]}',
            '{"ordem": [{"etapa": 1, "nodulos": ["flow.wait"], "paralelo": false}]}',
            '{"name": "Esperar", "trigger": {"type": "manual"}, "steps": [{"step_id": "wait_1", "module_id": "flow.wait", "params": {"duration": 1}}]}',
        ]
    )

    async def fake_ai(self, estado, system, user_msg, usar_historico=False):
        return next(answers)

    monkeypatch.setattr(AutomationPipelineService, "chamar_ia", fake_ai)
    result = asyncio.run(
        AutomationPipelineService().process("Crie uma automação a cada 30 minutos")
    )
    assert result["pipeline_status"] == "completed"
    assert result["workflow_json"]["trigger"]["type"] == "schedule"
    assert result["workflow_json"]["trigger"]["interval_minutes"] == 30


def test_ai_pipeline_accepts_complete_recurring_email_request(monkeypatch):
    from services.automacao.pipeline_service import AutomationPipelineService

    answers = iter(
        [
            '{"valido": true, "motivo": ""}',
            '{"objetivo": "Enviar e-mail", "trigger": {"type": "manual"}, "missing_information": ["destinatário", "agendamento"]}',
            '{"nodulos": ["gmail.send_email"]}',
            '{"ordem": [{"etapa": 1, "nodulos": ["gmail.send_email"], "paralelo": false}]}',
            '{"name": "Nome incorreto", "trigger": {"type": "manual"}, "steps": [{"step_id": "send", "module_id": "gmail.send_email", "params": {"to": "{{destinatario}}", "subject": "{{assunto}}", "body": "{{mensagem}}"}}]}',
        ]
    )

    async def fake_ai(self, estado, system, user_msg, usar_historico=False):
        return next(answers)

    monkeypatch.setattr(AutomationPipelineService, "chamar_ia", fake_ai)
    result = asyncio.run(
        AutomationPipelineService().process(
            "Crie uma automação chamada Demonstração CATAS que envie um e-mail para "
            'rafaelfurtado313@gmail.com com o assunto "Demonstração CATAS" e a mensagem '
            '"A automação do CATAS foi executada com sucesso" a cada 120 minutos.'
        )
    )

    assert result["pipeline_status"] == "completed"
    plan = result["workflow_json"]
    assert plan["name"] == "Demonstração CATAS"
    assert plan["trigger"]["type"] == "schedule"
    assert plan["trigger"]["interval_minutes"] == 120
    assert plan["steps"][0]["params"] == {
        "to": "rafaelfurtado313@gmail.com",
        "subject": "Demonstração CATAS",
        "body": "A automação do CATAS foi executada com sucesso",
    }


def test_ai_pipeline_describes_missing_email_data_without_internal_names(monkeypatch):
    from services.automacao.pipeline_service import AutomationPipelineService

    answers = iter(
        [
            '{"valido": true, "motivo": ""}',
            '{"objetivo": "Enviar e-mail", "trigger": {"type": "manual"}}',
            '{"nodulos": ["gmail.send_email"]}',
            '{"ordem": [{"etapa": 1, "nodulos": ["gmail.send_email"], "paralelo": false}]}',
            '{"name": "Enviar mensagem", "trigger": {"type": "manual"}, "steps": [{"step_id": "send", "module_id": "gmail.send_email", "params": {"recipient": "teste@example.com", "message": "Olá"}}]}',
        ]
    )

    async def fake_ai(self, estado, system, user_msg, usar_historico=False):
        return next(answers)

    monkeypatch.setattr(AutomationPipelineService, "chamar_ia", fake_ai)
    result = asyncio.run(
        AutomationPipelineService().process(
            'Crie uma automação para enviar a mensagem "Olá" para teste@example.com.'
        )
    )

    assert result["pipeline_status"] == "needs_clarification"
    assert result["message"] == (
        "Para criar a ação enviar e-mail, preciso que você informe o assunto."
    )
    assert "gmail.send_email" not in result["message"]
    assert "subject" not in result["message"]


def test_natural_language_revision_preserves_owner_scope(client, monkeypatch):
    from services.automacao.pipeline_service import AutomationPipelineService

    owner = Profile()
    owner.salvar()
    other = Profile()
    other.salvar()
    automation = Automation(
        user_id=owner.id,
        name="Tarefa",
        status="active",
        trigger={"type": "manual"},
        steps=[
            {"step_id": "wait_1", "module_id": "flow.wait", "params": {"duration": 1}}
        ],
    )
    automation.salvar()

    async def fake_pipeline(
        self,
        user_message,
        user_id=None,
        attachment_urls=None,
        preferred_modules=None,
    ):
        assert user_id == owner.id
        assert preferred_modules == ["flow.wait"]
        return {
            "pipeline_status": "completed",
            "workflow_json": {
                "name": "Tarefa revisada",
                "trigger": {"type": "schedule", "interval_minutes": 60},
                "steps": automation.steps,
            },
        }

    monkeypatch.setattr(AutomationPipelineService, "process", fake_pipeline)
    url = f"/api/v1/automations/{automation.id}/revise"
    assert (
        client.post(
            url, json={"request": "a cada hora"}, headers=_headers(other.id)
        ).status_code
        == 404
    )
    response = client.post(
        url, json={"request": "a cada hora"}, headers=_headers(owner.id)
    )
    assert response.status_code == 200
    assert response.json["name"] == "Tarefa revisada"
    assert response.json["trigger"]["interval_minutes"] == 60
    assert response.json["next_run_at"] is not None


def test_schedule_only_revision_preserves_email_without_ai(client, monkeypatch):
    from services.automacao.pipeline_service import AutomationPipelineService
    from services.chat.enviar_mensagem_chat_service import EnviarMensagemChatService

    owner = Profile()
    owner.salvar()
    steps = [
        {
            "step_id": "send_email",
            "module_id": "gmail.send_email",
            "params": {
                "to": "test@example.com",
                "subject": "Demonstração",
                "body": "Automação concluída",
            },
        }
    ]
    automation = Automation(
        user_id=owner.id,
        name="Demonstração CATAS",
        status="active",
        trigger={"type": "schedule", "interval_minutes": 120},
        steps=steps,
    )
    automation.salvar()

    async def unexpected_pipeline(*args, **kwargs):
        raise AssertionError("Alterar somente o horário não deve chamar a IA")

    monkeypatch.setattr(AutomationPipelineService, "process", unexpected_pipeline)
    response = client.post(
        f"/api/v1/automations/{automation.id}/revise",
        json={
            "request": (
                "Altere a frequência para todos os dias às 9h e mantenha o "
                "destinatário, o assunto e a mensagem atuais."
            )
        },
        headers=_headers(owner.id),
    )

    assert response.status_code == 200
    assert response.json["steps"][0]["module_id"] == "gmail.send_email"
    assert response.json["steps"][0]["params"] == steps[0]["params"]
    assert response.json["trigger"]["type"] == "cron"
    assert (
        EnviarMensagemChatService._descrever_agendamento(response.json["trigger"])
        == "todos os dias às 09:00"
    )
    assert response.json["next_run_at"] is not None


def test_chat_recognizes_plain_recurring_request_and_hides_cron(monkeypatch):
    from services.chat.enviar_mensagem_chat_service import (
        EnviarMensagemChatService,
    )

    monkeypatch.setenv("AUTOMATION_TIMEZONE", "America/Sao_Paulo")

    assert EnviarMensagemChatService._eh_pedido_automacao(
        "Envie um e-mail todos os dias às 9h"
    )
    assert (
        EnviarMensagemChatService._descrever_agendamento(
            {"type": "cron", "cron_expression": "0 12 * * *"}
        )
        == "todos os dias às 09:00"
    )
    assert (
        EnviarMensagemChatService._descrever_agendamento(
            {"type": "schedule", "interval_minutes": 60}
        )
        == "a cada hora"
    )
