import pytest
from unittest.mock import AsyncMock, patch
from services.intent_classifier import IntentClassifier

@pytest.fixture
def intent_classifier_fixture():
    with patch("app.services.intent_classifier.AIBase.call_ai", new_callable=AsyncMock) as mock_call_ai:
        classifier = IntentClassifier()
        yield classifier, mock_call_ai

@pytest.mark.asyncio
async def test_classify_intent_conversation(intent_classifier_fixture):
    classifier, mock_call_ai = intent_classifier_fixture
    
    mock_call_ai.return_value = {"intent": "conversation"}
    
    result = await classifier.classify_intent("Olá, tudo bem?")
    assert result["intent"] == "conversation"

@pytest.mark.asyncio
async def test_classify_intent_task(intent_classifier_fixture):
    classifier, mock_call_ai = intent_classifier_fixture
    
    mock_call_ai.return_value = {"intent": "task_create"}
    
    result = await classifier.classify_intent("Lembrar de comprar pão amanhã")
    assert result["intent"] == "task_create"

@pytest.mark.asyncio
async def test_classify_intent_calendar(intent_classifier_fixture):
    classifier, mock_call_ai = intent_classifier_fixture
    
    mock_call_ai.return_value = {"intent": "calendar_create_event"}
    
    result = await classifier.classify_intent("Reunião com o cliente quinta as 15h")
    assert result["intent"] == "calendar_create_event"

@pytest.mark.asyncio
async def test_classify_intent_invalid_json_fallback(intent_classifier_fixture):
    classifier, mock_call_ai = intent_classifier_fixture
    
    # AIBase itself handles JSON parsing or returns dict. 
    # If it fails, it might raise an exception or return default.
    # In IntentClassifier, we catch exceptions.
    mock_call_ai.side_effect = Exception("AI Error")
    
    # Should fallback gracefully after retries
    result = await classifier.classify_intent("Break it")
    assert result["intent"] == "conversation"
