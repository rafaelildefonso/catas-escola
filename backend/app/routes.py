from app.controllers.auth_controller import AuthController
from app.controllers.user_controller import UserController
from app.controllers.profile_controller import ProfileController
from app.controllers.chat_session_controller import ChatSessionController
from app.controllers.message_controller import MessageController
from app.controllers.automation_controller import AutomationController
from app.controllers.automation_run_controller import AutomationRunController
from app.controllers.automation_step_log_controller import AutomationStepLogController
from app.controllers.automation_generation_log_controller import AutomationGenerationLogController
from app.controllers.execution_log_controller import ExecutionLogController
from app.controllers.integration_controller import IntegrationController
from app.controllers.message_feedback_controller import MessageFeedbackController
from app.controllers.ai_suggestion_controller import AiSuggestionController
from app.controllers.page_context_controller import PageContextController
from app.controllers.browser_session_controller import BrowserSessionController
from app.controllers.page_analysis_cache_controller import PageAnalysisCacheController
from app.controllers.user_device_controller import UserDeviceController
from app.controllers.user_webhook_config_controller import UserWebhookConfigController
from app.controllers.ia_memory_controller import IaMemoryController


def _rota(app, url, methods, controller_func, endpoint):
    app.add_url_rule(url, endpoint=endpoint, view_func=controller_func, methods=methods)


def registrar_rotas(app):
    # Auth
    _rota(app, "/api/v1/auth/signup", ["POST"], AuthController.signup, "auth.signup")
    _rota(app, "/api/v1/auth/login", ["POST"], AuthController.login, "auth.login")
    _rota(app, "/api/v1/auth/me", ["GET"], AuthController.me, "auth.me")

    # Blueprints legados (chat, chatbot, feedback)
    from controllers.chat import chat_bp
    from controllers.chatbot import chatbot_bp
    from controllers.feedback import feedback_bp
    app.register_blueprint(chat_bp)
    app.register_blueprint(chatbot_bp, url_prefix="/api/v1/chat")
    app.register_blueprint(feedback_bp)
    _rota(app, "/api/v1/profiles", ["GET"], ProfileController.listar, "profile.listar")
    _rota(app, "/api/v1/profiles/<id>", ["GET"], ProfileController.buscar_por_id, "profile.buscar")
    _rota(app, "/api/v1/profiles", ["POST"], ProfileController.criar, "profile.criar")
    _rota(app, "/api/v1/profiles/<id>", ["PUT"], ProfileController.atualizar, "profile.atualizar")
    _rota(app, "/api/v1/profiles/me", ["PUT"], ProfileController.atualizar_me, "profile.atualizar_me")
    _rota(app, "/api/v1/profiles/<id>", ["DELETE"], ProfileController.deletar, "profile.deletar")
    _rota(app, "/api/v1/profiles/me", ["DELETE"], ProfileController.deletar_me, "profile.deletar_me")

    _rota(app, "/api/v1/users", ["GET"], UserController.listar, "user.listar")
    _rota(app, "/api/v1/users/<id>", ["GET"], UserController.buscar_por_id, "user.buscar")
    _rota(app, "/api/v1/users", ["POST"], UserController.criar, "user.criar")
    _rota(app, "/api/v1/users/<id>", ["PUT"], UserController.atualizar, "user.atualizar")
    _rota(app, "/api/v1/users/<id>", ["DELETE"], UserController.deletar, "user.deletar")

    _rota(app, "/api/v1/chat-sessions", ["GET"], ChatSessionController.listar, "chat_session.listar")
    _rota(app, "/api/v1/chat-sessions/<id>", ["GET"], ChatSessionController.buscar_por_id, "chat_session.buscar")
    _rota(app, "/api/v1/chat-sessions", ["POST"], ChatSessionController.criar, "chat_session.criar")
    _rota(app, "/api/v1/chat-sessions/<id>", ["PUT"], ChatSessionController.atualizar, "chat_session.atualizar")
    _rota(app, "/api/v1/chat-sessions/<id>", ["DELETE"], ChatSessionController.deletar, "chat_session.deletar")

    _rota(app, "/api/v1/messages", ["GET"], MessageController.listar, "message.listar")
    _rota(app, "/api/v1/messages/<id>", ["GET"], MessageController.buscar_por_id, "message.buscar")
    _rota(app, "/api/v1/messages", ["POST"], MessageController.criar, "message.criar")
    _rota(app, "/api/v1/messages/<id>", ["PUT"], MessageController.atualizar, "message.atualizar")
    _rota(app, "/api/v1/messages/<id>", ["DELETE"], MessageController.deletar, "message.deletar")

    _rota(app, "/api/v1/automations", ["GET"], AutomationController.listar, "automation.listar")
    _rota(app, "/api/v1/automations/<id>", ["GET"], AutomationController.buscar_por_id, "automation.buscar")
    _rota(app, "/api/v1/automations", ["POST"], AutomationController.criar, "automation.criar")
    _rota(app, "/api/v1/automations/<id>", ["PUT"], AutomationController.atualizar, "automation.atualizar")
    _rota(app, "/api/v1/automations/<id>", ["DELETE"], AutomationController.deletar, "automation.deletar")

    _rota(app, "/api/v1/automation-runs", ["GET"], AutomationRunController.listar, "automation_run.listar")
    _rota(app, "/api/v1/automation-runs/<id>", ["GET"], AutomationRunController.buscar_por_id, "automation_run.buscar")
    _rota(app, "/api/v1/automation-runs", ["POST"], AutomationRunController.criar, "automation_run.criar")
    _rota(app, "/api/v1/automation-runs/<id>", ["PUT"], AutomationRunController.atualizar, "automation_run.atualizar")
    _rota(app, "/api/v1/automation-runs/<id>", ["DELETE"], AutomationRunController.deletar, "automation_run.deletar")

    _rota(app, "/api/v1/automation-step-logs", ["GET"], AutomationStepLogController.listar, "automation_step_log.listar")
    _rota(app, "/api/v1/automation-step-logs/<id>", ["GET"], AutomationStepLogController.buscar_por_id, "automation_step_log.buscar")
    _rota(app, "/api/v1/automation-step-logs", ["POST"], AutomationStepLogController.criar, "automation_step_log.criar")
    _rota(app, "/api/v1/automation-step-logs/<id>", ["PUT"], AutomationStepLogController.atualizar, "automation_step_log.atualizar")
    _rota(app, "/api/v1/automation-step-logs/<id>", ["DELETE"], AutomationStepLogController.deletar, "automation_step_log.deletar")

    _rota(app, "/api/v1/automation-generation-logs", ["GET"], AutomationGenerationLogController.listar, "automation_generation_log.listar")
    _rota(app, "/api/v1/automation-generation-logs/<id>", ["GET"], AutomationGenerationLogController.buscar_por_id, "automation_generation_log.buscar")
    _rota(app, "/api/v1/automation-generation-logs", ["POST"], AutomationGenerationLogController.criar, "automation_generation_log.criar")
    _rota(app, "/api/v1/automation-generation-logs/<id>", ["PUT"], AutomationGenerationLogController.atualizar, "automation_generation_log.atualizar")
    _rota(app, "/api/v1/automation-generation-logs/<id>", ["DELETE"], AutomationGenerationLogController.deletar, "automation_generation_log.deletar")

    _rota(app, "/api/v1/execution-logs", ["GET"], ExecutionLogController.listar, "execution_log.listar")
    _rota(app, "/api/v1/execution-logs/<id>", ["GET"], ExecutionLogController.buscar_por_id, "execution_log.buscar")
    _rota(app, "/api/v1/execution-logs", ["POST"], ExecutionLogController.criar, "execution_log.criar")
    _rota(app, "/api/v1/execution-logs/<id>", ["PUT"], ExecutionLogController.atualizar, "execution_log.atualizar")
    _rota(app, "/api/v1/execution-logs/<id>", ["DELETE"], ExecutionLogController.deletar, "execution_log.deletar")

    _rota(app, "/api/v1/integrations", ["GET"], IntegrationController.listar, "integration.listar")
    _rota(app, "/api/v1/integrations/<id>", ["GET"], IntegrationController.buscar_por_id, "integration.buscar")
    _rota(app, "/api/v1/integrations", ["POST"], IntegrationController.criar, "integration.criar")
    _rota(app, "/api/v1/integrations/<id>", ["PUT"], IntegrationController.atualizar, "integration.atualizar")
    _rota(app, "/api/v1/integrations/<id>", ["DELETE"], IntegrationController.deletar, "integration.deletar")

    _rota(app, "/api/v1/message-feedback", ["GET"], MessageFeedbackController.listar, "message_feedback.listar")
    _rota(app, "/api/v1/message-feedback/<id>", ["GET"], MessageFeedbackController.buscar_por_id, "message_feedback.buscar")
    _rota(app, "/api/v1/message-feedback", ["POST"], MessageFeedbackController.criar, "message_feedback.criar")
    _rota(app, "/api/v1/message-feedback/<id>", ["PUT"], MessageFeedbackController.atualizar, "message_feedback.atualizar")
    _rota(app, "/api/v1/message-feedback/<id>", ["DELETE"], MessageFeedbackController.deletar, "message_feedback.deletar")

    _rota(app, "/api/v1/ai-suggestions", ["GET"], AiSuggestionController.listar, "ai_suggestion.listar")
    _rota(app, "/api/v1/ai-suggestions/<id>", ["GET"], AiSuggestionController.buscar_por_id, "ai_suggestion.buscar")
    _rota(app, "/api/v1/ai-suggestions", ["POST"], AiSuggestionController.criar, "ai_suggestion.criar")
    _rota(app, "/api/v1/ai-suggestions/<id>", ["PUT"], AiSuggestionController.atualizar, "ai_suggestion.atualizar")
    _rota(app, "/api/v1/ai-suggestions/<id>", ["DELETE"], AiSuggestionController.deletar, "ai_suggestion.deletar")

    _rota(app, "/api/v1/page-contexts", ["GET"], PageContextController.listar, "page_context.listar")
    _rota(app, "/api/v1/page-contexts/<id>", ["GET"], PageContextController.buscar_por_id, "page_context.buscar")
    _rota(app, "/api/v1/page-contexts", ["POST"], PageContextController.criar, "page_context.criar")
    _rota(app, "/api/v1/page-contexts/<id>", ["PUT"], PageContextController.atualizar, "page_context.atualizar")
    _rota(app, "/api/v1/page-contexts/<id>", ["DELETE"], PageContextController.deletar, "page_context.deletar")

    _rota(app, "/api/v1/browser-sessions", ["GET"], BrowserSessionController.listar, "browser_session.listar")
    _rota(app, "/api/v1/browser-sessions/<id>", ["GET"], BrowserSessionController.buscar_por_id, "browser_session.buscar")
    _rota(app, "/api/v1/browser-sessions", ["POST"], BrowserSessionController.criar, "browser_session.criar")
    _rota(app, "/api/v1/browser-sessions/<id>", ["PUT"], BrowserSessionController.atualizar, "browser_session.atualizar")
    _rota(app, "/api/v1/browser-sessions/<id>", ["DELETE"], BrowserSessionController.deletar, "browser_session.deletar")

    _rota(app, "/api/v1/page-analysis-cache", ["GET"], PageAnalysisCacheController.listar, "page_analysis_cache.listar")
    _rota(app, "/api/v1/page-analysis-cache/<id>", ["GET"], PageAnalysisCacheController.buscar_por_id, "page_analysis_cache.buscar")
    _rota(app, "/api/v1/page-analysis-cache", ["POST"], PageAnalysisCacheController.criar, "page_analysis_cache.criar")
    _rota(app, "/api/v1/page-analysis-cache/<id>", ["PUT"], PageAnalysisCacheController.atualizar, "page_analysis_cache.atualizar")
    _rota(app, "/api/v1/page-analysis-cache/<id>", ["DELETE"], PageAnalysisCacheController.deletar, "page_analysis_cache.deletar")

    _rota(app, "/api/v1/user-devices", ["GET"], UserDeviceController.listar, "user_device.listar")
    _rota(app, "/api/v1/user-devices/<id>", ["GET"], UserDeviceController.buscar_por_id, "user_device.buscar")
    _rota(app, "/api/v1/user-devices", ["POST"], UserDeviceController.criar, "user_device.criar")
    _rota(app, "/api/v1/user-devices/<id>", ["PUT"], UserDeviceController.atualizar, "user_device.atualizar")
    _rota(app, "/api/v1/user-devices/<id>", ["DELETE"], UserDeviceController.deletar, "user_device.deletar")

    _rota(app, "/api/v1/user-webhook-configs", ["GET"], UserWebhookConfigController.listar, "user_webhook_config.listar")
    _rota(app, "/api/v1/user-webhook-configs/<id>", ["GET"], UserWebhookConfigController.buscar_por_id, "user_webhook_config.buscar")
    _rota(app, "/api/v1/user-webhook-configs", ["POST"], UserWebhookConfigController.criar, "user_webhook_config.criar")
    _rota(app, "/api/v1/user-webhook-configs/<id>", ["PUT"], UserWebhookConfigController.atualizar, "user_webhook_config.atualizar")
    _rota(app, "/api/v1/user-webhook-configs/<id>", ["DELETE"], UserWebhookConfigController.deletar, "user_webhook_config.deletar")

    _rota(app, "/api/v1/ia-memories", ["GET"], IaMemoryController.listar, "ia_memory.listar")
    _rota(app, "/api/v1/ia-memories/<id>", ["GET"], IaMemoryController.buscar_por_id, "ia_memory.buscar")
    _rota(app, "/api/v1/ia-memories", ["POST"], IaMemoryController.criar, "ia_memory.criar")
    _rota(app, "/api/v1/ia-memories/<id>", ["PUT"], IaMemoryController.atualizar, "ia_memory.atualizar")
    _rota(app, "/api/v1/ia-memories/<id>", ["DELETE"], IaMemoryController.deletar, "ia_memory.deletar")
