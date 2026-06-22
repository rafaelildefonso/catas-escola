from pydantic import BaseModel
from typing import Optional


class PageContextModel(BaseModel):
    id: Optional[str] = None
    url: str
    domain: str
    page_title: Optional[str] = None
    html_summary: Optional[str] = None
    session_id: Optional[str] = None
    user_id: Optional[str] = None
    created_at: Optional[str] = None
