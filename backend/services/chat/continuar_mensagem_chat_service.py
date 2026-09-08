import asyncio
import copy
import logging

from services.ia.ai_service import AIService

from repositories.integracoes_repository import listar_integracoes_do_usuario
from services.chat.excecoes_chat import (
    ErroNaoEncontrado,
    LIMITE_CHUNKS_CONTINUACAO,
    montar_mensagem_interna,
)
from services.chat.obter_sessao_chat_service import ObterSessaoChatService
from services.chat.obter_historico_chat_service import ObterHistoricoChatService
from services.chat.salvar_mensagem_chat_service import SalvarMensagemChatService
from services.chat.atualizar_mensagem_chat_service import AtualizarMensagemChatService
from services.automacao.iniciar_automacao_assincrona_service import IniciarAutomacaoAssincronaService
from services.automacao.registrar_automation_run_service import RegistrarAutomationRunService

logger = logging.getLogger(__name__)

ai_service = AIService()


class ContinuarMensagemChatService:
    """Caso de uso: continuar uma conversa a partir da resposta de um componente interativo.

    Registra a resposta do componente como mensagem oculta, consulta a IA (ou reaproveita
    o plano aprovado) e anexa a nova resposta à mensagem original por chunks.
    """

    @staticmethod
    def executar(user_id: str, dados: dict) -> dict:
        dados = dados or {}

        session_id = dados.get("session_id")
        continuation_id = dados.get("continuation_id")
        component_type = dados.get("component_type")
        response_data = dados.get("response_data", {})
        model = dados.get("model", "CATAS Basic")

        if not all([session_id, continuation_id, component_type]):
            raise ValueError("Dados incompletos")

        try:
            ObterSessaoChatService.executar(session_id, user_id)
        except ValueError:
            raise ErroNaoEncontrado("Sessão não encontrada")

        internal_msg = montar_mensagem_interna(component_type, response_data)

        SalvarMensagemChatService.executar(
            session_id=session_id,
            role="user",
            content=internal_msg,
            metadata={"is_hidden": True, "component_origin": component_type},
        )

        history = ObterHistoricoChatService.executar(session_id, user_id, limite=500)

        user_integrations = ContinuarMensagemChatService._integracoes_do_usuario(user_id)
        if not user_integrations and response_data.get("active_integrations"):
            user_integrations = response_data["active_integrations"]

        ai_response = ContinuarMensagemChatService._resolver_resposta(
            user_id=user_id,
            component_type=component_type,
            response_data=response_data,
            internal_msg=internal_msg,
            history=history,
            continuation_id=continuation_id,
            model=model,
            user_integrations=user_integrations,
        )

        original_msg = next((m for m in reversed(history) if m.get("id") == continuation_id), None)
        if not original_msg:
            logger.error("Mensagem original não encontrada. continuation_id=%s, history_ids=%s", continuation_id, [m.get("id") for m in history])
            raise ErroNaoEncontrado("Mensagem original não encontrada")

        logger.debug("original_msg keys: %s, content present: %s", list(original_msg.keys()), "content" in original_msg)
        current_chunks = original_msg.get("metadata", {}).get("chunks_count", 1)
        if current_chunks >= LIMITE_CHUNKS_CONTINUACAO:
            ai_response["response_text"] = "\n\n(Limite de interação atingido para esta automação.)"
            ai_response["status"] = "completed"
            ai_response["components"] = []

        separator = "\n\n---\n\n"
        if "content" not in original_msg:
            logger.error("original_msg sem 'content' key. Keys: %s", list(original_msg.keys()))
            original_msg["content"] = ""
        updated_content = original_msg["content"] + separator + ai_response["response_text"]

        new_metadata = {
            "chunks_count": current_chunks + 1,
            "last_status": ai_response.get("status", "idle"),
            "components": ai_response.get("components", []),
            "action_triggered": ai_response.get("action_triggered", False),
            "action_details": ai_response.get("action_details"),
        }

        logger.debug("Atualizando mensagem continuation_id=%s, ai_response keys=%s", continuation_id, list(ai_response.keys()))
        AtualizarMensagemChatService.executar(continuation_id, content=updated_content, metadata=new_metadata)

        automation_id = ContinuarMensagemChatService._disparar_aprovacao(
            user_id=user_id,
            session_id=session_id,
            continuation_id=continuation_id,
            ai_response=ai_response,
        )

        perfil_atualizado = _perfil_dict(user_id)

        return {
            "text": ai_response["response_text"],
            "components": ai_response.get("components", []),
            "status": ai_response.get("status", "idle"),
            "actionTriggered": ai_response.get("action_triggered", False),
            "actionDetails": ai_response.get("action_details"),
            "automation_id": automation_id,
            "continuation_id": continuation_id,
            "quota_used": perfil_atualizado.get("quota_used"),
            "monthly_quota_limit": perfil_atualizado.get("monthly_quota_limit"),
            "credits_consumed": ai_response.get("credits_consumed", 0),
        }

    # ------------------------------------------------------------------

    @staticmethod
    def _integracoes_do_usuario(user_id: str) -> list:
        try:
            integracoes = listar_integracoes_do_usuario(user_id)
            return [i["provider"] for i in integracoes if i.get("is_connected")]
        except Exception:
            return []

    @staticmethod
    def _analisar(user_id, text, history, model, user_integrations):
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        return loop.run_until_complete(
            ai_service.analyze_message(
                text=text,
                user_id=user_id,
                history=history,
                model_requested=model,
                user_integrations=user_integrations,
                active_integrations=user_integrations,
            )
        )

    @staticmethod
    def _resolver_resposta(user_id, component_type, response_data, internal_msg, history,
                           continuation_id, model, user_integrations):
        if component_type == "action_approval" and response_data.get("approved"):
            original_msg_for_plan = next(
                (m for m in reversed(history) if m.get("id") == continuation_id), None
            )
            plan_from_history = None
            if original_msg_for_plan:
                plan_from_history = original_msg_for_plan.get("metadata", {}).get("action_details")

            logger.debug("plan_from_history: %s (type=%s)", plan_from_history, type(plan_from_history).__name__)
            if plan_from_history is not None:
                return {
                    "response_text": "Ação confirmada! Executando agora...",
                    "action_triggered": True,
                    "action_details": plan_from_history,
                    "components": [],
                    "status": "completed",
                    "credits_consumed": 0,
                    "intent": original_msg_for_plan.get("metadata", {}).get("intent", "action"),
                    "entities": original_msg_for_plan.get("metadata", {}).get("entities", {}),
                }

        return ContinuarMensagemChatService._analisar(
            user_id=user_id,
            text=internal_msg,
            history=history,
            model=model,
            user_integrations=user_integrations,
        )

    @staticmethod
    def _disparar_aprovacao(user_id, session_id, continuation_id, ai_response):
        """Se a IA disparou ação, registra log/run e inicia execução assíncrona."""
        if not (ai_response.get("action_triggered") and ai_response.get("action_details")):
            return None

        try:
            from models.execution_log import ExecutionLog

            log = ExecutionLog(
                user_id=user_id,
                workflow_name="gemini_action_approved",
                status="running",
                input_data={"source": "continue_approval", "original_continuation": continuation_id},
                result_data=ai_response.get("action_details"),
                session_id=session_id,
            )
            log.salvar()
            real_automation_id = str(log.id)

            plan = copy.deepcopy(ai_response.get("action_details") or {})
            plan["automation_id"] = real_automation_id
            plan["user_id"] = user_id
            plan["input_payload"] = {
                "source": "chatbot_gemini_continue",
                "session_id": session_id,
            }

            RegistrarAutomationRunService.executar(
                real_automation_id, user_id,
                status="running", run_type="direct",
                input_summary=ai_response.get("response_text", "Approval processed")[:500],
                input_payload={
                    "source": "chatbot_gemini_continue",
                    "session_id": session_id,
                    "original_continuation": continuation_id,
                },
                result_metadata={"action_details": plan},
            )

            IniciarAutomacaoAssincronaService.executar(
                real_automation_id, ai_response["action_details"], user_id
            )
            return real_automation_id
        except Exception:
            import traceback
            traceback.print_exc()
            return None


def _perfil_dict(user_id: str) -> dict:
    try:
        from models.profile import Profile
        model = Profile.buscar_por_id(user_id)
        return model.to_dict() if model else {}
    except Exception:
        return {}
