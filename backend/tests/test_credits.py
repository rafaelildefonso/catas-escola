import pytest
from services.credit_service import CreditService

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
