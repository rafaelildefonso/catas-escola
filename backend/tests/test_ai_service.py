import pytest
from unittest.mock import MagicMock, AsyncMock, patch
from services.ia.ai_service import AIService

@pytest.fixture
def ai_service():
    with patch("services.ia.ai_service.AIBase.call_ai", new_callable=AsyncMock) as mock_call_ai, \
         patch("services.ia.ai_service.IntentClassifier") as _, \
         patch("services.ia.ai_service.EntityExtractor") as _, \
         patch("services.ia.ai_service.PayloadBuilder") as _:
        
        service = AIService()
        yield service, mock_call_ai

@pytest.mark.asyncio
async def test_analyze_message_text_only(ai_service):
    service, mock_call_ai = ai_service
    
    # Setup mocks
    service.intent_classifier.classify_intent = AsyncMock(return_value={"intent": "conversation"})
    
    # AIBase returns a dict with response_text
    mock_call_ai.return_value = {"response_text": "Hello! How can I help you?", "status": "idle", "components": []}
    
    result = await service.analyze_message("Hello")
    
    assert result["response_text"] == "Hello! How can I help you?"
    assert result["action_triggered"] is False

@pytest.mark.asyncio
async def test_analyze_message_action_trigger(ai_service):
    service, mock_call_ai = ai_service
    
    # Setup mocks
    service.intent_classifier.classify_intent = AsyncMock(return_value={"intent": "calendar_create_event"})
    
    mock_entities = {"date": "2024-03-20", "time": "15:00", "title": "Meeting"}
    service.entity_extractor.extract_entities = AsyncMock(return_value=mock_entities)
    
    service.payload_builder.build_payload = MagicMock(return_value={
        "tool": "google_calendar",
        "payload": mock_entities
    })
    
    mock_call_ai.return_value = {
        "response_text": "Preparando para agendar sua reunião...",
        "status": "completed",
        "components": []
    }
    
    result = await service.analyze_message(
        "Schedule a meeting tomorrow at 3pm",
        user_integrations=["google_calendar"],
        active_integrations=["google_calendar"],
    )
    
    assert result["action_triggered"] is True
    assert result["action_details"]["tool"] == "google_calendar"
    assert result["action_details"]["payload"]["title"] == "Meeting"
    assert "Preparando para agendar" in result["response_text"]


@pytest.mark.asyncio
async def test_action_is_blocked_when_required_integration_is_not_connected(ai_service):
    service, mock_call_ai = ai_service
    service.intent_classifier.classify_intent = AsyncMock(
        return_value={"intent": "email_draft"}
    )
    service.entity_extractor.extract_entities = AsyncMock(
        return_value={"recipient": "cliente@exemplo.com", "subject": "Olá", "body_topic": "Teste"}
    )
    service.payload_builder.build_payload = MagicMock(return_value={
        "steps": [{"module_id": "gmail.send_email", "params": {}}]
    })
    # Even an incorrect/overconfident model response must not create an action.
    mock_call_ai.return_value = {
        "response_text": "E-mail enviado!",
        "status": "completed",
        "components": [],
    }

    result = await service.analyze_message(
        "Envie um e-mail", user_integrations=[], active_integrations=[]
    )

    assert result["action_triggered"] is False
    assert result["status"] == "requires_action"
    assert result["action_details"] == {}
    assert result["components"] == [{
        "type": "integration_connect",
        "provider": "google_gmail",
        "provider_name": "Gmail",
        "action": "connect",
        "message": "Conecte o Gmail para continuar com esta ação.",
        "readonly": False,
    }]
    assert "Nenhuma ação foi executada" in result["response_text"]


@pytest.mark.asyncio
async def test_action_is_blocked_when_connected_integration_is_inactive_in_chat(ai_service):
    service, mock_call_ai = ai_service
    service.intent_classifier.classify_intent = AsyncMock(
        return_value={"intent": "email_draft"}
    )
    service.entity_extractor.extract_entities = AsyncMock(return_value={})
    service.payload_builder.build_payload = MagicMock(return_value={
        "steps": [{"module_id": "gmail.send_email", "params": {}}]
    })
    mock_call_ai.return_value = {
        "response_text": "E-mail enviado!",
        "status": "completed",
        "components": [],
    }

    result = await service.analyze_message(
        "Envie um e-mail",
        user_integrations=["google_gmail"],
        active_integrations=[],
    )

    assert result["action_triggered"] is False
    assert result["components"][0]["action"] == "activate_in_chat"
    assert result["components"][0]["provider"] == "google_gmail"

@pytest.mark.asyncio
async def test_analyze_message_fallback_error(ai_service):
    service, mock_call_ai = ai_service
    
    # Make intent classifier throw an error
    service.intent_classifier.classify_intent = AsyncMock(side_effect=Exception("API failure"))
    
    result = await service.analyze_message("Break it")
    
    # Should fall back to try/except in analyze_message returning error
    assert "Erro ao processar IA: Erro interno do servidor" in result["response_text"]
    assert result["action_triggered"] is False


@pytest.mark.asyncio
async def test_uses_logged_email_and_accessible_instructions(ai_service):
    service, mock_call_ai = ai_service
    service.intent_classifier.classify_intent = AsyncMock(
        return_value={"intent": "email_draft"}
    )
    service.entity_extractor.extract_entities = AsyncMock(
        return_value={"subject": "Boas-vindas", "recipient": None, "body_topic": "Boas-vindas"}
    )
    service.payload_builder.build_payload = MagicMock(return_value={"steps": []})
    mock_call_ai.return_value = {
        "response_text": "Tudo certo!",
        "status": "idle",
        "components": [],
    }

    profile = MagicMock()
    profile.to_dict.return_value = {"industry": "real_estate", "role": "Corretor"}
    user = MagicMock(email="corretor@exemplo.com")

    with patch("models.profile.Profile.buscar_por_id", return_value=profile), patch(
        "models.user.User.buscar_por_id", return_value=user
    ):
        result = await service.analyze_message("Envie as boas-vindas", user_id="user-1")

    system_prompt = mock_call_ai.await_args.kwargs["system_prompt"]
    assert "Logged account email: corretor@exemplo.com" in system_prompt
    assert "ACCESSIBLE LANGUAGE" in system_prompt
    assert "schedule/frequency" in system_prompt
    assert result["entities"]["recipient"] == "corretor@exemplo.com"
