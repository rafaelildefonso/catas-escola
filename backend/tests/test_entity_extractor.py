import pytest
from unittest.mock import AsyncMock, patch
from services.ia.entity_extractor import EntityExtractor

@pytest.fixture
def entity_extractor_fixture():
    with patch("services.ia.entity_extractor.AIBase.call_ai", new_callable=AsyncMock) as mock_call_ai:
        extractor = EntityExtractor()
        yield extractor, mock_call_ai

@pytest.mark.asyncio
async def test_extract_entities_calendar(entity_extractor_fixture):
    extractor, mock_call_ai = entity_extractor_fixture
    
    mock_call_ai.return_value = {
        "date": "2024-03-20", 
        "time": "15:00:00", 
        "title": "Reunião de Vendas", 
        "description": None, 
        "attendees": []
    }
    
    result = await extractor.extract_entities("Agendar reunião de vendas amanhã às 15h", "calendar_create_event")
    assert result["date"] == "2024-03-20"
    assert result["time"] == "15:00:00"
    assert result["title"] == "Reunião de Vendas"

@pytest.mark.asyncio
async def test_extract_entities_task(entity_extractor_fixture):
    extractor, mock_call_ai = entity_extractor_fixture
    
    mock_call_ai.return_value = {
        "task_name": "Comprar pão", 
        "due_date": "2024-03-20", 
        "priority": "alta", 
        "value": "5"
    }
    
    result = await extractor.extract_entities("Lembrar de comprar pão amanhã com prioridade alta valor 5 reais", "task_create")
    assert result["task_name"] == "Comprar pão"
    assert result["priority"] == "alta"
    assert result["value"] == "5"

@pytest.mark.asyncio
async def test_extract_entities_conversation_returns_empty(entity_extractor_fixture):
    extractor, mock_call_ai = entity_extractor_fixture
    
    result = await extractor.extract_entities("Olá", "conversation")
    assert result == {}
