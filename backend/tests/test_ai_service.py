import pytest
from unittest.mock import MagicMock, AsyncMock, patch
from app.services.ia.ai_service import AIService

@pytest.fixture
def ai_service():
    with patch("app.services.ia.ai_service.AIBase.call_ai", new_callable=AsyncMock) as mock_call_ai, \
         patch("app.services.ia.ai_service.IntentClassifier") as _, \
         patch("app.services.ia.ai_service.EntityExtractor") as _, \
         patch("app.services.ia.ai_service.PayloadBuilder") as _:
        
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
    
    result = await service.analyze_message("Schedule a meeting tomorrow at 3pm")
    
    assert result["action_triggered"] is True
    assert result["action_details"]["tool"] == "google_calendar"
    assert result["action_details"]["payload"]["title"] == "Meeting"
    assert "Preparando para agendar" in result["response_text"]

@pytest.mark.asyncio
async def test_analyze_message_fallback_error(ai_service):
    service, mock_call_ai = ai_service
    
    # Make intent classifier throw an error
    service.intent_classifier.classify_intent = AsyncMock(side_effect=Exception("API failure"))
    
    result = await service.analyze_message("Break it")
    
    # Should fall back to try/except in analyze_message returning error
    assert "Erro ao processar IA: Erro interno do servidor" in result["response_text"]
    assert result["action_triggered"] is False
