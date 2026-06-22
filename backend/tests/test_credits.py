import pytest
from unittest.mock import MagicMock, patch
from services.credit_service import CreditService
# from core.config import settings

@pytest.fixture
def credit_service():
    return CreditService()

def test_calculate_credits(credit_service):
    # 2000 tokens = 1 credit
    assert credit_service.calculate_credits(2000) == 1
    assert credit_service.calculate_credits(3000) == 2  # 1.5 -> round to 2
    assert credit_service.calculate_credits(1000) == 1  # min 1
    assert credit_service.calculate_credits(0) == 0
    assert credit_service.calculate_credits(5000) == 3  # 2.5 -> round to 3

def test_calculate_rollover(credit_service):
    # Limit: 100, Usage: 40 -> 60 remain. Rollover: 60.
    assert credit_service.calculate_rollover(40, 100, 0) == 60
    
    # Max rollover: 3x limit = 300.
    # Limit: 100, Usage: 0, Current Rollover: 250 -> 100 + 250 = 350 -> capped at 300.
    assert credit_service.calculate_rollover(0, 100, 250) == 300
    
    # Usage > Limit (consumed from rollover already)
    # Limit: 100, Usage: 120 -> -20 remain. Rollover: current - 20.
    # Current Rollover: 50 -> 50 - 20 = 30.
    assert credit_service.calculate_rollover(120, 100, 50) == 30

@patch("app.services.db_supabase.supabase.rpc")
def test_debit_credits_success(mock_rpc, credit_service):
    mock_rpc.return_value.execute.return_value = MagicMock(data={"status": "success"})
    
    result = credit_service.debit_credits("user_123", 5)
    
    assert result["status"] == "success"
    mock_rpc.assert_called_with("handle_credit_debit", {"p_user_id": "user_123", "p_amount": 5})

@patch("app.services.db_supabase.supabase.rpc")
def test_debit_credits_insufficient(mock_rpc, credit_service):
    mock_rpc.return_value.execute.return_value = MagicMock(data={"status": "error", "message": "Insufficient credits"})
    
    result = credit_service.debit_credits("user_123", 1000)
    
    assert result["status"] == "error"
    assert "Insufficient credits" in result["message"]
