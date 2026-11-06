import asyncio
import copy
import os
import re
from datetime import datetime, timedelta, timezone
from zoneinfo import ZoneInfo

from core.security import is_prompt_injection_safe
from models.automation_generation_log import AutomationGenerationLog
from models.execution_log import ExecutionLog
from repositories.integracoes_repository import listar_integracoes_do_usuario
from repositories.sessoes_chat_repository import buscar_sessao_do_usuario
from services.automacao.iniciar_automacao_assincrona_service import (
    IniciarAutomacaoAssincronaService,
)
from services.automacao.pipeline_service import AutomationPipelineService
from services.automacao.registrar_automation_run_service import (
    RegistrarAutomationRunService,
)
from services.chat.criar_sessao_chat_service import CriarSessaoChatService
from services.chat.detectar_onboarding_demo_service import DetectarOnboardingDemoService
from services.chat.excecoes_chat import MENSAGENS_ONBOARDING, ErroPermissao
from services.chat.montar_plano_onboarding_service import MontarPlanoOnboardingService
from services.chat.obter_historico_chat_service import ObterHistoricoChatService
from services.chat.renomear_sessao_chat_service import RenomearSessaoChatService
from services.chat.salvar_mensagem_chat_service import SalvarMensagemChatService
from services.chat.integration_access_service import IntegrationAccessService
from services.ia.ai_service import AIService
from services.profile.verificar_quota_service import VerificarQuotaService

ai_service = AIService()
pipeline_service = AutomationPipelineService()


class EnviarMensagemChatService:
    """Caso de uso: enviar mensagem do usuário ao assistente de IA.

    Orquestra validação, quota, sessão, pipeline de IA e disparo de automações.
    Levanta ValueError para erros de validação e ErroPermissao para regras de plano/quota.
    """

    @staticmethod
    def executar(user_id: str, dados: dict) -> dict:
        dados = dados or {}

        mensagem_erro = EnviarMensagemChatService._validar(dados)
        if mensagem_erro:
            raise ValueError(mensagem_erro)

        message = dados.get("message", "")
        automation_request = EnviarMensagemChatService._eh_pedido_automacao(message)
        conversation_id = dados.get("conversation_id")
        current_page_url = dados.get("current_page_url")
        current_page_title = dados.get("current_page_title")
        model = dados.get("model", "CATAS Basic")
        attachment_urls = dados.get("attachment_urls", [])
        active_integrations = dados.get("active_integrations", [])
        user_tools = dados.get("user_tools", [])

        is_onboarding_message = message.strip() in MENSAGENS_ONBOARDING or message.strip().startswith(
            "CATAS: quero criar minha primeira automação de demonstração"
        )

        is_dev_user = user_id.startswith("dev-user-")

        if not is_dev_user:
            permitido, erro, profile = VerificarQuotaService.executar(user_id, model_requested=model)
            if not permitido:
                raise ErroPermissao(erro)
            if not EnviarMensagemChatService._pode_iniciar_conversa_livre(
                profile,
                conversation_id,
                is_onboarding_message,
                automation_request,
            ):
                raise ErroPermissao("Conversa livre disponível apenas para assinantes.")
        else:
            profile = {
                "subscription_tier": "pro",
                "quota_used": 0,
                "monthly_quota_limit": 7500,
                "rollover_credits": 0,
            }

        session_id = conversation_id
        is_new_session = False
        new_title = "Nova Conversa"

        is_onboarding_session = False
        if not session_id:
            if is_dev_user:
                session_id = f"dev-session-{user_id}"
                is_new_session = True
            else:
                sessao = CriarSessaoChatService.executar(
                    user_id, titulo="Nova Conversa", is_onboarding=is_onboarding_message
                )
                session_id = sessao["id"]
                is_new_session = True
                is_onboarding_session = is_onboarding_message
        else:
            if not is_dev_user:
                is_onboarding_session = EnviarMensagemChatService._eh_sessao_onboarding(session_id, user_id)
            try:
                loop = asyncio.new_event_loop()
                asyncio.set_event_loop(loop)
                new_title = loop.run_until_complete(ai_service.generate_chat_title(message))
                if not is_dev_user:
                    RenomearSessaoChatService.executar(session_id, user_id, new_title)
            except Exception:
                pass

        if not is_dev_user:
            try:
                SalvarMensagemChatService.executar(
                    session_id=session_id,
                    role="user",
                    content=message,
                    metadata={
                        "current_page_url": current_page_url,
                        "current_page_title": current_page_title,
                        "attachment_urls": attachment_urls,
                    },
                )
            except Exception:
                pass

        historico_recente = []
        user_integrations = []
        try:
            mensagens_db = ObterHistoricoChatService.executar(session_id, user_id, limite=10)
            for msg in mensagens_db:
                if msg.get("role") in ["user", "assistant"]:
                    if msg.get("role") == "user" and msg.get("content") == message:
                        continue
                    historico_recente.append({
                        "role": msg["role"],
                        "content": msg.get("content", ""),
                        "metadata": msg.get("metadata", {}),
                    })
        except Exception:
            pass

        try:
            integracoes = listar_integracoes_do_usuario(user_id)
            user_integrations = [i["provider"] for i in integracoes if i.get("is_connected")]
        except Exception:
            pass
        demo_ativado = os.getenv("DEMO_ONBOARDING_ENABLED", "true").lower() == "true"
        if demo_ativado:
            resposta_demo = EnviarMensagemChatService._tentar_fluxo_demo_onboarding(
                user_id=user_id,
                message=message,
                session_id=session_id,
                is_new_session=is_new_session,
                new_title=new_title,
            )
            if resposta_demo is not None:
                return resposta_demo

        if automation_request:
            return EnviarMensagemChatService._fluxo_meta_automacao(
                user_id=user_id, message=message, session_id=session_id,
                is_new_session=is_new_session, new_title=new_title,
                is_onboarding_session=is_onboarding_session,
                attachment_urls=attachment_urls, model=model, ai_result={},
            )

        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        ai_result = loop.run_until_complete(
            ai_service.analyze_message(
                text=message,
                user_id=user_id,
                history=historico_recente,
                attachment_urls=attachment_urls,
                model_requested=model,
                user_integrations=user_integrations,
                active_integrations=active_integrations or [],
                user_tools=user_tools or [],
            )
        )

        intent = ai_result.get("intent", "conversation")

        if intent == "meta_automation":
            return EnviarMensagemChatService._fluxo_meta_automacao(
                user_id=user_id,
                message=message,
                session_id=session_id,
                is_new_session=is_new_session,
                new_title=new_title,
                is_onboarding_session=is_onboarding_session,
                attachment_urls=attachment_urls,
                model=model,
                ai_result=ai_result,
            )

        return EnviarMensagemChatService._fluxo_padrao(
            user_id=user_id,
            message=message,
            session_id=session_id,
            is_new_session=is_new_session,
            new_title=new_title,
            is_onboarding_session=is_onboarding_session,
            ai_result=ai_result,
            user_integrations=user_integrations,
            active_integrations=active_integrations or [],
        )

    # ------------------------------------------------------------------
    # Validação e helpers privados
    # ------------------------------------------------------------------

    @staticmethod
    def _pode_iniciar_conversa_livre(
        profile: dict,
        conversation_id: str | None,
        is_onboarding_message: bool,
        automation_request: bool,
    ) -> bool:
        """O Basic é um plano assinado; somente o tier gratuito é bloqueado."""
        tier = (profile.get("subscription_tier") or "basic").lower()
        return (
            tier != "free"
            or bool(conversation_id)
            or is_onboarding_message
            or automation_request
        )

    @staticmethod
    def _validar(dados: dict):
        message = dados.get("message")
        if not message or not isinstance(message, str) or not message.strip():
            return "Mensagem é obrigatória"
        if not is_prompt_injection_safe(message):
            return "Mensagem contém padrões proibidos"
        return None

    @staticmethod
    def _eh_pedido_automacao(message: str) -> bool:
        text = message.casefold()
        creation = re.search(
            r"\b(crie|criar|quero|monte|montar|configure|configurar|"
            r"automatize|automatizar|agende|agendar|envie|enviar|adicione|"
            r"adicionar|avise|avisar)\b",
            text,
        )
        automation = "automa" in text or "fluxo" in text
        recurrence = any(term in text for term in ("a cada ", "todo dia", "todos os dias", "toda semana", "toda segunda", "diariamente", "semanalmente"))
        return bool((creation and automation) or (creation and recurrence))

    @staticmethod
    def _descrever_agendamento(trigger: dict) -> str:
        if trigger.get("type") == "schedule":
            minutes = trigger.get("interval_minutes")
            if minutes == 60:
                return "a cada hora"
            if minutes == 1440:
                return "todos os dias"
            if isinstance(minutes, int) and minutes % 60 == 0:
                hours = minutes // 60
                return f"a cada {hours} horas"
            return f"a cada {minutes} minutos"

        fields = str(trigger.get("cron_expression") or "").split()
        if len(fields) == 5 and fields[0].isdigit() and fields[1].isdigit():
            try:
                utc_time = datetime.now(timezone.utc).replace(
                    hour=int(fields[1]),
                    minute=int(fields[0]),
                    second=0,
                    microsecond=0,
                )
                timezone_name = os.getenv(
                    "AUTOMATION_TIMEZONE", "America/Sao_Paulo"
                )
                try:
                    local_timezone = ZoneInfo(timezone_name)
                except KeyError:
                    if timezone_name != "America/Sao_Paulo":
                        raise
                    local_timezone = timezone(timedelta(hours=-3))
                local_time = utc_time.astimezone(local_timezone)
                time_label = local_time.strftime("%H:%M")
                if fields[2:4] == ["*", "*"] and fields[4] == "*":
                    return f"todos os dias às {time_label}"
                if fields[2:4] == ["*", "*"] and fields[4] == "1-5":
                    return f"nos dias úteis às {time_label}"
                return f"no horário combinado, às {time_label}"
            except (ValueError, KeyError):
                pass
        return "nos horários combinados"

    @staticmethod
    def _eh_sessao_onboarding(session_id: str, user_id: str) -> bool:
        try:
            sessao = buscar_sessao_do_usuario(session_id, user_id)
            return bool(sessao and sessao.get("is_onboarding"))
        except Exception:
            return False

    @staticmethod
    def _registrar_log_execucao(user_id, workflow_name, input_data=None, result_data=None, session_id=None):
        log = ExecutionLog(
            user_id=user_id,
            workflow_name=workflow_name,
            status="running",
            input_data=input_data,
            result_data=result_data,
            session_id=session_id,
        )
        log.salvar()
        return log.id

    @staticmethod
    def _registrar_log_geracao(user_id, session_id, intent_raw, final_plan, model):
        registro = AutomationGenerationLog(
            user_id=user_id,
            session_id=session_id,
            intent_raw=intent_raw,
            attempts=[],
            errors=[],
            final_plan=final_plan,
            model=model,
        )
        registro.salvar()

    # ------------------------------------------------------------------
    # Fluxos
    # ------------------------------------------------------------------

    @staticmethod
    def _tentar_fluxo_demo_onboarding(user_id, message, session_id, is_new_session, new_title):
        demo = DetectarOnboardingDemoService.executar(message)
        if not demo:
            return None

        plan = MontarPlanoOnboardingService.executar(
            demo["client_name"], demo["meeting_date"], demo["meeting_time"], user_id
        )

        response_text = (
            f"Onboarding de {demo['client_name']} iniciado!\n\n"
            f"Acompanhe o progresso abaixo"
        )

        assistant_msg_id = None
        try:
            saved = SalvarMensagemChatService.executar(
                session_id=session_id,
                role="assistant",
                content=response_text,
                metadata={
                    "action_triggered": True,
                    "action_details": plan,
                    "components": [{
                        "type": "automation_progress",
                        "automation_id": "pending",
                        "title": f"Onboarding {demo['client_name']}",
                    }],
                    "source": "demo_onboarding",
                    "status": "running",
                },
            )
            assistant_msg_id = saved.get("id") if saved else None
        except Exception:
            assistant_msg_id = None

        demo_automation_id = None
        try:
            demo_automation_id = EnviarMensagemChatService._registrar_log_execucao(
                user_id=user_id,
                workflow_name="demo_onboarding",
                input_data={"message": message},
                result_data=plan,
                session_id=session_id,
            )
            plan["automation_id"] = demo_automation_id
            plan["user_id"] = user_id

            RegistrarAutomationRunService.executar(
                demo_automation_id, user_id,
                status="running", run_type="direct",
                input_summary=f"Onboarding {demo['client_name']}",
                input_payload={"source": "demo_onboarding", "session_id": session_id, "message": message},
                result_metadata={"plan": copy.deepcopy(plan)},
            )

            IniciarAutomacaoAssincronaService.executar(demo_automation_id, copy.deepcopy(plan), user_id)
        except Exception:
            import traceback
            traceback.print_exc()

        perfil_atualizado = _perfil_dict(user_id)

        return {
            "id": assistant_msg_id,
            "text": response_text,
            "actionTriggered": True,
            "actionDetails": plan,
            "automation_id": demo_automation_id,
            "components": [{
                "type": "automation_progress",
                "automation_id": demo_automation_id or "pending",
                "title": f"Onboarding {demo['client_name']}",
            }],
            "session_id": session_id,
            "session_title": new_title if is_new_session else None,
            "quota_used": perfil_atualizado.get("quota_used"),
            "monthly_quota_limit": perfil_atualizado.get("monthly_quota_limit"),
            "credits_consumed": 0,
        }

    @staticmethod
    def _fluxo_meta_automacao(user_id, message, session_id, is_new_session, new_title,
                              is_onboarding_session, attachment_urls, model, ai_result):
        loop2 = asyncio.new_event_loop()
        try:
            asyncio.set_event_loop(loop2)
            pipeline_result = loop2.run_until_complete(
                pipeline_service.process(
                    user_message=message,
                    user_id=user_id,
                    attachment_urls=attachment_urls,
                )
            )
        finally:
            loop2.close()
            asyncio.set_event_loop(None)

        pipeline_status = pipeline_result.get("pipeline_status", "completed")

        def salvar_msg(sid, text, meta):
            try:
                return SalvarMensagemChatService.executar(session_id=sid, role="assistant", content=text, metadata=meta)
            except Exception:
                return {"id": None}

        if pipeline_status == "needs_clarification":
            texto = pipeline_result.get("message", "Pode me dar mais detalhes?")
            assistant_message = salvar_msg(session_id, texto, {"source": "pipeline", "pipeline_status": "needs_clarification"})
            return {
                "id": assistant_message.get("id"), "text": texto,
                "session_id": session_id, "session_title": new_title if is_new_session else None,
            }

        if pipeline_status == "rejected":
            texto = pipeline_result.get("message", "Não entendi como criar essa automação. Pode reformular?")
            assistant_message = salvar_msg(session_id, texto, {"source": "pipeline", "pipeline_status": "rejected"})
            return {
                "id": assistant_message.get("id"), "text": texto,
                "session_id": session_id, "session_title": new_title if is_new_session else None,
            }

        if pipeline_status != "completed":
            texto = "Não consegui preparar a automação agora. Tente novamente em instantes."
            assistant_message = salvar_msg(session_id, texto, {"source": "pipeline", "pipeline_status": pipeline_status})
            return {
                "id": assistant_message.get("id"), "text": texto,
                "session_id": session_id, "session_title": new_title if is_new_session else None,
            }

        from models.integration import Integration
        from services.automacao.module_registry import get_module_spec
        from services.automation.criar_automation_service import CriarAutomationService
        from services.automation.dispatch import dispatch_automation

        plan_data = pipeline_result.get("workflow_json", {})
        trigger = plan_data.get("trigger") or {"type": "manual"}
        required_providers = {
            spec.provider for step in plan_data.get("steps", [])
            if (spec := get_module_spec(step.get("module_id"))) and spec.provider
        }
        connected_providers = {
            item.provider for item in Integration.query.filter_by(user_id=user_id, is_connected=True).all()
        }
        missing_providers = sorted(required_providers - connected_providers)
        if missing_providers:
            blocked = IntegrationAccessService.blocked_response(
                plan_data,
                None,
                connected_providers,
                connected_providers,
            )
            texto = blocked["response_text"]
            components = blocked["components"]
            assistant_message = salvar_msg(session_id, texto, {
                "source": "automation_pipeline",
                "pipeline_status": "needs_integration",
                "status": "requires_action",
                "components": components,
                "action_triggered": False,
            })
            return {
                "id": assistant_message.get("id"),
                "text": texto,
                "components": components,
                "status": "requires_action",
                "actionTriggered": False,
                "session_id": session_id,
                "session_title": new_title if is_new_session else None,
            }
        try:
            automation = CriarAutomationService.executar({
                "name": plan_data.get("name") or pipeline_result.get("objetivo") or "Nova automação",
                "description": plan_data.get("description") or message,
                "trigger": trigger,
                "steps": plan_data.get("steps", []),
                "status": "active",
            }, user_id)
        except ValueError as exc:
            texto = f"Preciso ajustar a automação antes de salvá-la: {exc}"
            assistant_message = salvar_msg(session_id, texto, {"source": "automation_pipeline", "pipeline_status": "needs_clarification"})
            return {"id": assistant_message.get("id"), "text": texto, "session_id": session_id,
                    "session_title": new_title if is_new_session else None}

        try:
            EnviarMensagemChatService._registrar_log_geracao(
                user_id, session_id=session_id, intent_raw=message,
                final_plan=plan_data, model=model,
            )
        except Exception:
            pass

        run = None
        if trigger.get("type") == "manual":
            run = dispatch_automation(automation.id, user_id, "chat")

        if run is None:
            when = EnviarMensagemChatService._descrever_agendamento(trigger)
            response_text = f"Criei e ativei **{automation.name}**. Ela vai executar {when}. Você pode acompanhá-la em Automações."
        elif run.status == "failed":
            response_text = f"Criei **{automation.name}**, mas não consegui iniciar agora. Tente executar novamente pela página Automações."
        else:
            response_text = f"Criei **{automation.name}** e iniciei a execução. Você pode acompanhar o resultado em Automações."

        details = {"automation_id": automation.id, "trigger": trigger,
                   "modules": [step.get("module_id") for step in plan_data.get("steps", [])]}
        triggered = run is not None and run.status != "failed"
        assistant_message = salvar_msg(session_id, response_text, {
            "action_triggered": triggered, "action_details": details,
            "source": "automation_pipeline", "status": "running" if triggered else "completed",
        })
        perfil_atualizado = _perfil_dict(user_id)
        return {
            "id": assistant_message.get("id"), "text": response_text,
            "actionTriggered": triggered, "actionDetails": details,
            "status": "running" if triggered else "completed",
            "automation_id": run.id if triggered else None,
            "saved_automation_id": automation.id,
            "session_id": session_id,
            "session_title": new_title if is_new_session else None,
            "quota_used": perfil_atualizado.get("quota_used"),
            "monthly_quota_limit": perfil_atualizado.get("monthly_quota_limit"),
            "credits_consumed": pipeline_result.get("credits_consumed", 0),
        }

    @staticmethod
    def _fluxo_padrao(user_id, message, session_id, is_new_session, new_title,
                      is_onboarding_session, ai_result, user_integrations,
                      active_integrations):
        # This check is deliberately server-side.  A client-side toggle is not
        # proof that OAuth exists, and an LLM response is never permission to
        # claim that an external action happened.
        blocked = IntegrationAccessService.blocked_response(
            ai_result.get("action_details"),
            ai_result.get("intent"),
            user_integrations,
            active_integrations,
        )
        if blocked:
            ai_result = {**ai_result, **blocked}

        assistant_message = None
        try:
            assistant_message = SalvarMensagemChatService.executar(
                session_id=session_id,
                role="assistant",
                content=ai_result["response_text"],
                metadata={
                    "action_triggered": ai_result["action_triggered"],
                    "action_details": ai_result.get("action_details"),
                    "components": ai_result.get("components", []),
                    "intent": ai_result.get("intent", "conversation"),
                    "entities": ai_result.get("entities", {}),
                    "source": "gemini_standard",
                    "status": ai_result.get("status", "idle"),
                },
            )
        except Exception:
            pass

        automation_id_val = None
        if ai_result["action_triggered"]:
            try:
                automation_id_val = EnviarMensagemChatService._registrar_log_execucao(
                    user_id=user_id, workflow_name="gemini_action",
                    input_data={"message": message}, result_data=ai_result.get("action_details"),
                    session_id=session_id,
                )
            except Exception:
                automation_id_val = None

            plan = copy.deepcopy(ai_result.get("action_details") or {})
            plan["automation_id"] = str(automation_id_val)
            plan["user_id"] = user_id

            try:
                RegistrarAutomationRunService.executar(
                    str(automation_id_val), user_id,
                    status="running", run_type="direct",
                    input_summary=message[:500],
                    input_payload={"source": "chatbot_gemini", "session_id": session_id},
                    result_metadata={"action_details": plan},
                )
            except Exception:
                pass

            IniciarAutomacaoAssincronaService.executar(str(automation_id_val), plan, user_id)

        perfil_atualizado = _perfil_dict(user_id)

        return {
            "id": assistant_message.get("id") if assistant_message else None,
            "text": ai_result["response_text"],
            "isUser": False,
            "actionTriggered": ai_result["action_triggered"],
            "actionDetails": ai_result.get("action_details"),
            "automation_id": automation_id_val,
            "components": ai_result.get("components", []),
            "status": ai_result.get("status", "idle"),
            "session_id": session_id,
            "session_title": new_title if is_new_session else None,
            "continuation_id": (
                assistant_message.get("id")
                if assistant_message and ai_result.get("status") == "requires_action"
                else None
            ),
            "quota_used": perfil_atualizado.get("quota_used"),
            "monthly_quota_limit": perfil_atualizado.get("monthly_quota_limit"),
            "credits_consumed": ai_result.get("credits_consumed", 0),
        }


def _perfil_dict(user_id: str) -> dict:
    try:
        from models.profile import Profile
        model = Profile.buscar_por_id(user_id)
        return model.to_dict() if model else {}
    except Exception:
        return {}
