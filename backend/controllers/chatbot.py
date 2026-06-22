import json
import os
import re
import asyncio
import traceback
import threading
from datetime import datetime, timedelta
from typing import Optional, List

from flask import Blueprint, request, jsonify, g

from core.security import get_current_user, is_prompt_injection_safe, get_user_rate_limit
from core.errors import sanitize_error

from services.ai_service import AIService
from services.automation_pipeline_service import AutomationPipelineService

from repositories import chat as chat_repo
from repositories import automation_logs as logs_repo
from repositories import automations as automations_repo
from repositories import automation_generation_logs as gen_logs_repo
from repositories import profiles as profiles_repo

chatbot_bp = Blueprint("chatbot", __name__)

ai_service = AIService()
pipeline_service = AutomationPipelineService()


def _start_automation_in_thread(aid: str, plan: dict, user_id: str = None):
    try:
        from services.automation_runner_service import AutomationRunnerService

        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        result = loop.run_until_complete(
            AutomationRunnerService.start_automation(aid, plan, user_id=user_id)
        )
        automations_repo.update_automation_run_execution(aid, result["id"], result.get("first_execution_run_id"))
    except Exception as e:
        traceback.print_exc()
        try:
            automations_repo.update_automation_run_status(
                aid, "failed",
                error_details={"message": str(e), "traceback": traceback.format_exc()},
            )
        except Exception:
            pass


DEMO_ONBOARDING_ENABLED = os.getenv("DEMO_ONBOARDING_ENABLED", "true").lower() == "true"
DEMO_CLIENTES_SPREADSHEET_ID = os.getenv("DEMO_CLIENTES_SPREADSHEET_ID", "")
DEMO_CLIENTES_FOLDER_ID = os.getenv("DEMO_CLIENTES_FOLDER_ID", "")

WEEKDAY_MAP = {
    "segunda": 0, "segunda-feira": 0, "2": 0,
    "terça": 1, "terça-feira": 1, "3": 1,
    "quarta": 2, "quarta-feira": 2, "4": 2,
    "quinta": 3, "quinta-feira": 3, "5": 3,
    "sexta": 4, "sexta-feira": 4, "6": 4,
    "sábado": 5, "sabado": 5,
    "domingo": 6, "7": 6,
}


def _resolve_date(day_ref: str) -> str:
    today = datetime.now()
    day_ref = day_ref.lower().strip()

    if day_ref == "hoje":
        return today.strftime("%Y-%m-%d")
    if day_ref == "amanhã" or day_ref == "amanha":
        return (today + timedelta(days=1)).strftime("%Y-%m-%d")
    if day_ref == "depois de amanhã" or day_ref == "depois de amanha":
        return (today + timedelta(days=2)).strftime("%Y-%m-%d")

    target_weekday = WEEKDAY_MAP.get(day_ref)
    if target_weekday is not None:
        days_ahead = target_weekday - today.weekday()
        if days_ahead <= 0:
            days_ahead += 7
        return (today + timedelta(days=days_ahead)).strftime("%Y-%m-%d")

    return (today + timedelta(days=1)).strftime("%Y-%m-%d")


def _detect_onboarding_demo(message: str) -> Optional[dict]:
    text = message.lower().strip()

    patterns = [
        r"(?:fechamos\s+contrato|contrato\s+fechado|contrato\s+com|novo\s+cliente|onboarding)\s*(?:com|do|da|para|de)?\s*[:\-]?\s*([A-Za-zÀ-ÿ\s]+?)(?:\s*[.,;!?]|\s+e\s+|\s+para\s+|\s+organize\s+|\s+agende\s+|\s*$)",
        r"(?:contrato|cliente)\s+(?:com|do|da|para|de)\s+([A-Za-zÀ-ÿ\s]+?)(?:\s*[.,;!?]|\s+para\s+|\s+organize\s+|\s+agende\s+|\s*$)",
    ]

    client_name = None
    for pattern in patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            candidate = match.group(1).strip().title()
            if len(candidate) > 1:
                client_name = candidate
                break

    if not client_name:
        return None

    meeting_time = "14:00"
    meeting_date = None

    time_match = re.search(r'(\d{1,2})[:h](\d{2})?\s*(?:h|hrs|horas)?', text)
    if time_match:
        h, m = time_match.group(1), time_match.group(2) or "00"
        meeting_time = f"{h.zfill(2)}:{m}"

    date_match = re.search(
        r'(sexta|segunda|terça|quarta|quinta|sábado|domingo|hoje|amanhã|depois de amanhã|depois de amanha|sabado)',
        text, re.IGNORECASE
    )
    if date_match:
        meeting_date = _resolve_date(date_match.group(1))

    if not meeting_date:
        meeting_date = (datetime.now() + timedelta(days=1)).strftime("%Y-%m-%d")

    return {
        "client_name": client_name,
        "meeting_date": meeting_date,
        "meeting_time": meeting_time,
    }


def _build_onboarding_plan(client_name: str, meeting_date: str, meeting_time: str, user_id: str) -> dict:
    sheet_id = DEMO_CLIENTES_SPREADSHEET_ID
    parent_folder_id = DEMO_CLIENTES_FOLDER_ID

    start_dt = f"{meeting_date}T{meeting_time}:00"
    end_dt = (datetime.fromisoformat(start_dt) + timedelta(hours=1)).isoformat()

    steps = []

    steps.append({
        "step_id": "agendar_reuniao",
        "module_id": "google_calendar.create_event",
        "params": {
            "summary": f"Onboarding {client_name}",
            "start": start_dt,
            "end": end_dt,
            "description": f"Reunião de onboarding com {client_name}",
        },
    })

    if parent_folder_id:
        steps.append({
            "step_id": "criar_pasta",
            "module_id": "google_drive.create_folder",
            "params": {
                "folder_name": client_name,
                "parent_folder_id": parent_folder_id,
            },
        })

    if sheet_id:
        steps.append({
            "step_id": "registrar_cliente",
            "module_id": "google_sheets.append_row",
            "params": {
                "spreadsheet_id": sheet_id,
                "range": "Sheet1!A:C",
                "values": [[client_name, meeting_date, f"Onboarding {meeting_time}"]],
            },
        })

    return {
        "name": f"Onboarding de {client_name}",
        "steps": steps,
        "context": {
            "client_name": client_name,
            "user_id": user_id,
        },
    }


def _validate_chat_message(data: dict) -> Optional[str]:
    message = data.get("message")
    if not message or not isinstance(message, str) or not message.strip():
        return "Mensagem é obrigatória"
    if not is_prompt_injection_safe(message):
        return "Mensagem contém padrões proibidos"
    return None


@chatbot_bp.route("/message/continue", methods=["POST"])
def continue_chat_message():
    current_user = get_current_user()
    if not current_user:
        return jsonify({"detail": "Não autorizado"}), 401

    user_id = current_user["id"]
    data = request.get_json(silent=True) or {}

    session_id = data.get("session_id")
    continuation_id = data.get("continuation_id")
    component_type = data.get("component_type")
    response_data = data.get("response_data", {})
    model = data.get("model", "CATAS Basic")

    if not all([session_id, continuation_id, component_type]):
        return jsonify({"detail": "Dados incompletos"}), 400

    session = chat_repo.get_session(session_id, user_id)
    if not session:
        return jsonify({"detail": "Sessão não encontrada"}), 404

    component_msg_map = {
        "action_approval": "[APROVADO]" if response_data.get("approved") else "[RECUSADO]",
        "contact_select": f"[CONTATOS SELECIONADOS] {','.join(response_data.get('selected_contacts', []))}",
        "date_time_picker": f"[DATA_HORA_SELECIONADA] {response_data.get('iso_date')}",
        "multiple_choice": f"[ESCOLHA] {response_data.get('selected_option')}",
        "text_input": f"[TEXTO_INPUT] {response_data.get('text')}"
    }

    internal_msg = component_msg_map.get(component_type, f"[RESPOSTA_COMPONENTE] {json.dumps(response_data)}")

    chat_repo.save_message(
        session_id=session_id,
        role="user",
        content=internal_msg,
        metadata={"is_hidden": True, "component_origin": component_type}
    )

    history = chat_repo.get_session_messages(session_id, user_id, limit=500)

    user_integrations = []
    try:
        from repositories import integrations as int_repo
        all_integrations = int_repo.get_user_integrations(user_id)
        user_integrations = [i['provider'] for i in all_integrations if i.get('is_connected')]
    except Exception:
        pass
    if not user_integrations and response_data.get("active_integrations"):
        user_integrations = response_data["active_integrations"]

    if component_type == "action_approval" and response_data.get("approved"):
        original_msg_for_plan = next(
            (m for m in reversed(history) if m.get("id") == continuation_id), None
        )
        plan_from_history = None
        if original_msg_for_plan:
            plan_from_history = original_msg_for_plan.get("metadata", {}).get("action_details")

        if plan_from_history:
            ai_response = {
                "response_text": "Ação confirmada! Executando agora...",
                "action_triggered": True,
                "action_details": plan_from_history,
                "components": [],
                "status": "completed",
                "credits_consumed": 0,
                "intent": original_msg_for_plan.get("metadata", {}).get("intent", "action"),
                "entities": original_msg_for_plan.get("metadata", {}).get("entities", {}),
            }
        else:
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            ai_response = loop.run_until_complete(
                ai_service.analyze_message(
                    text=internal_msg,
                    user_id=user_id,
                    history=history,
                    model_requested=model,
                    user_integrations=user_integrations,
                    active_integrations=user_integrations,
                )
            )
    else:
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        ai_response = loop.run_until_complete(
            ai_service.analyze_message(
                text=internal_msg,
                user_id=user_id,
                history=history,
                model_requested=model,
                user_integrations=user_integrations,
                active_integrations=user_integrations,
            )
        )

    original_msg = next((m for m in reversed(history) if m["id"] == continuation_id), None)
    if not original_msg:
        return jsonify({"detail": "Mensagem original não encontrada"}), 404

    current_chunks = original_msg.get("metadata", {}).get("chunks_count", 1)
    if current_chunks >= 15:
        ai_response["response_text"] = "\n\n(Limite de interação atingido para esta automação.)"
        ai_response["status"] = "completed"
        ai_response["components"] = []

    separator = "\n\n---\n\n"
    updated_content = original_msg["content"] + separator + ai_response["response_text"]

    new_metadata = {
        "chunks_count": current_chunks + 1,
        "last_status": ai_response.get("status", "idle"),
        "components": ai_response.get("components", []),
        "action_triggered": ai_response.get("action_triggered", False),
        "action_details": ai_response.get("action_details")
    }

    chat_repo.update_message(continuation_id, content=updated_content, metadata=new_metadata)

    automation_id = None
    if ai_response.get("action_triggered") and ai_response.get("action_details"):
        try:
            automation_log = logs_repo.log_automation(
                user_id=user_id,
                workflow_name="gemini_action_approved",
                status="running",
                input_data={"source": "continue_approval", "original_continuation": continuation_id},
                result_data=ai_response.get("action_details"),
                session_id=session_id
            )
            real_automation_id = str(automation_log["id"])
            plan = ai_response.get("action_details") or {}
            plan["automation_id"] = real_automation_id
            plan["user_id"] = user_id
            plan["input_payload"] = {
                "source": "chatbot_gemini_continue",
                "session_id": session_id,
            }
            automations_repo.upsert_automation_run(
                real_automation_id,
                user_id,
                status="running",
                run_type="direct",
                input_summary=ai_response.get("response_text", "Approval processed")[:500],
                input_payload={
                    "source": "chatbot_gemini_continue",
                    "session_id": session_id,
                    "original_continuation": continuation_id,
                },
                result_metadata={"action_details": plan},
            )

            threading.Thread(
                target=_start_automation_in_thread,
                args=(real_automation_id, ai_response["action_details"], user_id),
                daemon=True,
            ).start()
            automation_id = real_automation_id
        except Exception as ae:
            traceback.print_exc()

    updated_profile = profiles_repo.get_user_profile(user_id) or {}

    return jsonify({
        "text": ai_response["response_text"],
        "components": ai_response.get("components", []),
        "status": ai_response.get("status", "idle"),
        "actionTriggered": ai_response.get("action_triggered", False),
        "actionDetails": ai_response.get("action_details"),
        "automation_id": automation_id,
        "continuation_id": continuation_id,
        "quota_used": updated_profile.get("quota_used"),
        "monthly_quota_limit": updated_profile.get("monthly_quota_limit"),
        "credits_consumed": ai_response.get("credits_consumed", 0)
    })


@chatbot_bp.route("/message", methods=["POST"])
def send_chat_message():
    current_user = get_current_user()
    if not current_user:
        return jsonify({"detail": "Não autorizado"}), 401

    user_id = current_user["id"]
    data = request.get_json(silent=True) or {}

    validation_error = _validate_chat_message(data)
    if validation_error:
        return jsonify({"detail": validation_error}), 400

    message = data.get("message", "")
    conversation_id = data.get("conversation_id")
    current_page_url = data.get("current_page_url")
    current_page_title = data.get("current_page_title")
    model = data.get("model", "CATAS Basic")
    attachment_urls = data.get("attachment_urls", [])
    active_integrations = data.get("active_integrations", [])
    user_tools = data.get("user_tools", [])

    is_dev_user = user_id.startswith("dev-user-")

    profile = {}
    if not is_dev_user:
        allowed, error_msg, profile = profiles_repo.check_and_increment_quota(user_id, model_requested=model)
        if not allowed:
            return jsonify({"detail": error_msg}), 403
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

    ONBOARDING_MSGS = [
        "CATAS: quero criar minha primeira automação de demonstração — um lembrete simples para começar.",
        "CATAS: Quero organizar meus leads do Zap Imóveis no Google Sheets e enviar um e-mail de boas-vindas automático.",
        "CATAS: Quero consolidar os dados das minhas campanhas em uma planilha do Google Sheets e gerar um relatório resumido com IA.",
        "CATAS: Quero resumir meus processos jurídicos em PDF e criar tarefas de acompanhamento no meu calendário."
    ]
    is_onboarding_message = message.strip() in ONBOARDING_MSGS or message.strip().startswith("CATAS: quero criar minha primeira automação de demonstração")

    if not is_dev_user:
        tier = profile.get("subscription_tier", "basic")
        if tier == "basic":
            if not session_id:
                if not is_onboarding_message:
                    return jsonify({"detail": "Apenas assinantes podem iniciar novas conversas com a IA livremente."}), 403
            else:
                if not chat_repo.is_session_onboarding(session_id, user_id):
                    return jsonify({"detail": "Apenas assinantes podem interagir no chat fora do modo de demonstração."}), 403

    is_onboarding_session = False
    if not session_id:
        if is_dev_user:
            session_id = f"dev-session-{user_id}"
            is_new_session = True
        else:
            session = chat_repo.create_session(
                user_id,
                title="Nova Conversa",
                is_onboarding=is_onboarding_message
            )
            session_id = session["id"]
            is_new_session = True
            is_onboarding_session = is_onboarding_message
    else:
        if not is_dev_user:
            is_onboarding_session = chat_repo.is_session_onboarding(session_id, user_id)
        try:
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            new_title = loop.run_until_complete(ai_service.generate_chat_title(message))
            if not is_dev_user:
                chat_repo.update_session_title(session_id, user_id, new_title)
        except Exception as e:
            pass

    if not is_dev_user:
        try:
            chat_repo.save_message(
                session_id=session_id,
                role="user",
                content=message,
                metadata={
                    "current_page_url": current_page_url,
                    "current_page_title": current_page_title,
                    "attachment_urls": attachment_urls
                }
            )
        except Exception as e:
            pass

    try:
        historico_recente = []
        if session_id:
            try:
                mensagens_db = chat_repo.get_session_messages(session_id, user_id, limit=10)
                for msg in mensagens_db:
                    if msg.get("role") in ["user", "assistant"]:
                        if msg.get("role") == "user" and msg.get("content") == message:
                            continue
                        historico_recente.append({
                            "role": msg["role"],
                            "content": msg.get("content", ""),
                            "metadata": msg.get("metadata", {})
                        })
            except Exception as e:
                pass

            user_integrations = []
            try:
                from repositories import integrations as int_repo
                all_integrations = int_repo.get_user_integrations(user_id)
                user_integrations = [i['provider'] for i in all_integrations if i.get('is_connected')]
            except Exception:
                pass
            if not user_integrations and active_integrations:
                user_integrations = active_integrations

        if DEMO_ONBOARDING_ENABLED:
            demo_data = _detect_onboarding_demo(message)
            if demo_data:
                plan = _build_onboarding_plan(
                    demo_data["client_name"],
                    demo_data["meeting_date"],
                    demo_data["meeting_time"],
                    user_id,
                )

                response_text = (
                    f"Onboarding de {demo_data['client_name']} iniciado!\n\n"
                    f"Acompanhe o progresso abaixo"
                )

                try:
                    saved = chat_repo.save_message(
                        session_id=session_id, role="assistant",
                        content=response_text,
                        metadata={
                            "action_triggered": True,
                            "action_details": plan,
                            "components": [{
                                "type": "automation_progress",
                                "automation_id": "pending",
                                "title": f"Onboarding {demo_data['client_name']}"
                            }],
                            "source": "demo_onboarding",
                            "status": "running",
                        }
                    )
                    assistant_msg_id = saved.get("id") if saved else None
                except Exception as e:
                    assistant_msg_id = None

                demo_automation_id = None
                try:
                    automation_log = logs_repo.log_automation(
                        user_id=user_id, workflow_name="demo_onboarding", status="running",
                        input_data={"message": message},
                        result_data=plan, session_id=session_id,
                    )
                    demo_automation_id = str(automation_log["id"])
                    plan["automation_id"] = demo_automation_id
                    plan["user_id"] = user_id

                    automations_repo.upsert_automation_run(
                        demo_automation_id, user_id, status="running", run_type="direct",
                        input_summary=f"Onboarding {demo_data['client_name']}",
                        input_payload={"source": "demo_onboarding", "session_id": session_id, "message": message},
                        result_metadata={"plan": plan},
                    )

                    threading.Thread(
                        target=_start_automation_in_thread,
                        args=(demo_automation_id, plan, user_id),
                        daemon=True,
                    ).start()
                except Exception as e:
                    traceback.print_exc()

                updated_profile = profiles_repo.get_user_profile(user_id) or {}

                return jsonify({
                    "id": assistant_msg_id,
                    "text": response_text,
                    "actionTriggered": True,
                    "actionDetails": plan,
                    "automation_id": demo_automation_id,
                    "components": [{
                        "type": "automation_progress",
                        "automation_id": demo_automation_id or "pending",
                        "title": f"Onboarding {demo_data['client_name']}"
                    }],
                    "session_id": session_id,
                    "session_title": new_title if is_new_session else None,
                    "quota_used": updated_profile.get("quota_used"),
                    "monthly_quota_limit": updated_profile.get("monthly_quota_limit"),
                    "credits_consumed": 0,
                })

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
            loop2 = asyncio.new_event_loop()
            asyncio.set_event_loop(loop2)
            pipeline_result = loop2.run_until_complete(
                pipeline_service.process(
                    user_message=message,
                    user_id=user_id,
                    attachment_urls=attachment_urls
                )
            )

            pipeline_status = pipeline_result.get("pipeline_status", "completed")

            def _try_save_msg(sid, text, meta):
                try:
                    return chat_repo.save_message(session_id=sid, role="assistant", content=text, metadata=meta)
                except Exception as e:
                    return {"id": None}

            if pipeline_status == "needs_clarification":
                clarification_text = pipeline_result.get("message", "Pode me dar mais detalhes?")
                assistant_message = _try_save_msg(session_id, clarification_text, {"source": "pipeline", "pipeline_status": "needs_clarification"})
                return jsonify({
                    "id": assistant_message.get("id"), "text": clarification_text,
                    "session_id": session_id, "session_title": new_title if is_new_session else None
                })

            if pipeline_status == "rejected":
                rejection_text = pipeline_result.get("message", "Não entendi como criar essa automação. Pode reformular?")
                assistant_message = _try_save_msg(session_id, rejection_text, {"source": "pipeline", "pipeline_status": "rejected"})
                return jsonify({
                    "id": assistant_message.get("id"), "text": rejection_text,
                    "session_id": session_id, "session_title": new_title if is_new_session else None
                })

            if pipeline_status != "completed":
                error_text = f"Não foi possível processar sua solicitação: {pipeline_result.get('message', 'Erro desconhecido')}"
                assistant_message = _try_save_msg(session_id, error_text, {"source": "pipeline", "pipeline_status": pipeline_status})
                return jsonify({
                    "id": assistant_message.get("id"), "text": error_text,
                    "session_id": session_id, "session_title": new_title if is_new_session else None
                })

            plan_data = pipeline_result.get("workflow_json", {})
            objetivo = pipeline_result.get("objetivo", "Automação personalizada")

            response_text = (
                f"Automação Preparada!\n\n"
                f"Analisei seu pedido e estruturei um plano de execução resiliente.\n"
                f"Objetivo: {objetivo}\n\n"
                f"Vou iniciar o processamento agora. Você pode acompanhar o status em tempo real."
            )

            assistant_message = _try_save_msg(session_id, response_text, {
                "action_triggered": True,
                "action_details": plan_data,
                "source": "automation_pipeline",
                "status": "running"
            })

            try:
                automation_log = logs_repo.log_automation(user_id, objetivo, "running", {"message": message}, plan_data, session_id=session_id)
                automation_id_val = automation_log["id"]
                plan_data["automation_id"] = str(automation_id_val)
            except Exception:
                automation_id_val = None

            expires_at = None
            if is_onboarding_session:
                expires_at = (datetime.utcnow() + timedelta(days=7)).isoformat()

            automations_repo.upsert_automation_run(
                str(automation_id_val), user_id, status="running", run_type="direct",
                input_summary=(objetivo or message)[:500],
                input_payload={"source": "chatbot_meta", "session_id": session_id, "message": message},
                result_metadata={"plan": plan_data},
                expires_at=expires_at
            )

            try:
                gen_logs_repo.log_generation(
                    user_id, session_id=session_id, intent_raw=message,
                    attempts=[], errors=[], final_plan=plan_data, model=model
                )
            except Exception:
                pass

            threading.Thread(
                target=_start_automation_in_thread,
                args=(str(automation_id_val), plan_data, user_id),
                daemon=True,
            ).start()

            updated_profile = profiles_repo.get_user_profile(user_id) or {}

            return jsonify({
                "id": assistant_message.get("id"), "text": response_text,
                "actionTriggered": True, "actionDetails": plan_data,
                "automation_id": automation_id_val, "session_id": session_id,
                "session_title": new_title if is_new_session else None,
                "quota_used": updated_profile.get("quota_used"),
                "monthly_quota_limit": updated_profile.get("monthly_quota_limit"),
                "credits_consumed": pipeline_result.get("credits_consumed", 0)
            })

        assistant_message = None
        try:
            saved = chat_repo.save_message(
                session_id=session_id,
                role="assistant",
                content=ai_result["response_text"],
                metadata={
                    "action_triggered": ai_result["action_triggered"],
                    "action_details": ai_result.get("action_details"),
                    "components": ai_result.get("components", []),
                    "intent": ai_result.get("intent", "conversation"),
                    "entities": ai_result.get("entities", {}),
                    "source": "gemini_standard"
                }
            )
            assistant_message = saved
        except Exception as e:
            pass

        automation_id_val = None
        if ai_result["action_triggered"]:
            try:
                automation_log = logs_repo.log_automation(
                    user_id=user_id, workflow_name="gemini_action", status="running",
                    input_data={"message": message}, result_data=ai_result.get("action_details"), session_id=session_id
                )
                automation_id_val = automation_log["id"]
            except Exception:
                automation_id_val = None

            plan = ai_result.get("action_details") or {}
            plan["automation_id"] = str(automation_id_val)
            plan["user_id"] = user_id

            expires_at = None
            if is_onboarding_session:
                expires_at = (datetime.utcnow() + timedelta(days=7)).isoformat()

            try:
                automations_repo.upsert_automation_run(
                    str(automation_id_val), user_id, status="running", run_type="direct",
                    input_summary=message[:500],
                    input_payload={"source": "chatbot_gemini", "session_id": session_id},
                    result_metadata={"action_details": plan}, expires_at=expires_at
                )
            except Exception:
                pass

            threading.Thread(
                target=_start_automation_in_thread,
                args=(str(automation_id_val), plan, user_id),
                daemon=True,
            ).start()

        updated_profile = profiles_repo.get_user_profile(user_id) or {}

        return jsonify({
            "id": assistant_message.get("id") if assistant_message else None,
            "text": ai_result["response_text"],
            "isUser": False,
            "actionTriggered": ai_result["action_triggered"],
            "actionDetails": ai_result.get("action_details"),
            "automation_id": automation_id_val,
            "components": ai_result.get("components", []),
            "session_id": session_id,
            "session_title": new_title if is_new_session else None,
            "continuation_id": assistant_message.get("id") if assistant_message and ai_result.get("status") == "requires_action" else None,
            "quota_used": updated_profile.get("quota_used"),
            "monthly_quota_limit": updated_profile.get("monthly_quota_limit"),
            "credits_consumed": ai_result.get("credits_consumed", 0)
        })

    except Exception as e:
        traceback.print_exc()
        return jsonify({"detail": f"Erro ao processar mensagem: {sanitize_error(e)}"}), 500
