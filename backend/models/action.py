from pydantic import BaseModel
from typing import Any, Optional, Literal


class ActionCard(BaseModel):
    id: str
    title: str
    description: str
    icon: str
    priority: Literal["low", "medium", "high"]
    badge: Optional[str] = None
    type: str
    payload: dict[str, Any]
