"""
Ponte de acesso a dados do Worker.

O worker roda como serviço FastAPI separado, mas usa os MESMOS Models
(Flask-SQLAlchemy) da API. Cada função abre um app context do Flask para
executar as operações de persistência, mantendo um único ORM no projeto.
"""
import logging
import threading
from datetime import datetime, timedelta, timezone
from typing import Dict, Optional

logger = logging.getLogger("worker.repositorio")

_flask_app = None
_lock = threading.Lock()


def obter_app():
    """Cria (uma única vez) a aplicação Flask para acesso aos Models."""
    global _flask_app
    if _flask_app is None:
        with _lock:
            if _flask_app is None:
                from app import create_app
                _flask_app = create_app()
    return _flask_app


def registrar_passo_execucao(
    automation_id: str,
    step_index: int,
    module_id: str,
    status: str,
    user_id: str = None,
    result: Optional[Dict] = None,
    intent: str = None,
) -> None:
    """Cria ou atualiza o log de um passo da automação (upsert por automation_id + step_index)."""
    with obter_app().app_context():
        from app.models.automation_step_log import AutomationStepLog

        registro = (
            AutomationStepLog.query
            .filter(
                AutomationStepLog.automation_id == automation_id,
                AutomationStepLog.step_index == step_index,
            )
            .first()
        )
        if registro:
            registro.atualizar(module_id=module_id, status=status)
            if user_id:
                registro.user_id = user_id
            if result is not None:
                registro.result = result
            if intent:
                registro.intent = intent
            from app.extensions import db
            db.session.commit()
        else:
            registro = AutomationStepLog(
                automation_id=automation_id,
                step_index=step_index,
                module_id=module_id,
                status=status,
                user_id=user_id,
                result=result,
                intent=intent,
            )
            registro.salvar()


def atualizar_status_run(
    run_id: str,
    status: str,
    *,
    result_metadata: Optional[Dict] = None,
    error_details: Optional[Dict] = None,
    steps_summary: Optional[Dict] = None,
) -> None:
    """Atualiza o status de uma execução; grava finished_at em status terminais."""
    with obter_app().app_context():
        from app.models.automation_run import AutomationRun

        run = AutomationRun.buscar_por_id(run_id)
        if not run:
            logger.warning("Run %s não encontrada ao atualizar status.", run_id)
            return

        campos = {"status": status}
        if status in ("completed", "failed", "canceled"):
            campos["finished_at"] = datetime.now(timezone.utc)
        if result_metadata is not None:
            campos["result_metadata"] = result_metadata
        if error_details is not None:
            campos["error_details"] = error_details
        if steps_summary is not None:
            campos["steps_summary"] = steps_summary

        run.atualizar(**campos)


def obter_integracao(user_id: str, provider: str) -> Optional[Dict]:
    """Busca a integração do usuário com tokens descriptografados, renovando se necessário."""
    with obter_app().app_context():
        from app.extensions import db
        from core.crypto import decrypt_value
        from core.oauth_token_service import is_google_provider, refresh_google_tokens, token_expires_soon
        from app.models.integration import Integration

        integration_model = (
            Integration.query
            .filter(Integration.user_id == user_id, Integration.provider == provider)
            .first()
        )
        if not integration_model:
            return None

        integration = integration_model.to_dict()
        if integration.get("access_token"):
            integration["access_token"] = decrypt_value(integration["access_token"])
        if integration.get("refresh_token"):
            integration["refresh_token"] = decrypt_value(integration["refresh_token"])

        # Refresh lazy de tokens Google próximos do vencimento
        if is_google_provider(provider) and token_expires_soon(integration.get("token_expires_at")):
            refresh_token = integration.get("refresh_token")
            if refresh_token:
                data = refresh_google_tokens(refresh_token)
                new_access = data.get("access_token") if data else None
                if new_access:
                    new_refresh = data.get("refresh_token") or refresh_token
                    expires_in = data.get("expires_in")
                    expires_at = None
                    if isinstance(expires_in, int):
                        expires_at = (
                            datetime.now(timezone.utc) + timedelta(seconds=expires_in)
                        ).isoformat()

                    from core.crypto import encrypt_value
                    integration_model.access_token = encrypt_value(new_access)
                    integration_model.refresh_token = encrypt_value(new_refresh)
                    db.session.commit()

                    integration["access_token"] = new_access
                    integration["refresh_token"] = new_refresh
                    integration["token_expires_at"] = expires_at

        return integration
