from pydantic import BaseModel
from typing import List, Dict, Any, Optional


class AnalyzeRequest(BaseModel):
    url: str
    html_content: str
    user_context: Optional[str] = ""
    session_id: Optional[str] = None
    browser_session_id: Optional[str] = None
    model: Optional[str] = "CATAS Basic"


class SuggestedAction(BaseModel):
    id: Optional[str] = None
    type: str
    title: str
    description: str
    confidence: float
    extracted_data: Dict[str, Any]
    suggested_workflow: Optional[str] = None


class AnalyzeResponse(BaseModel):
    status: str
    message: str
    data: Dict[str, Any]


class ExecuteRequest(BaseModel):
    action_type: str
    payload: Dict[str, Any]
    suggestion_id: Optional[str] = None
    session_id: Optional[str] = None


class ExecuteResponse(BaseModel):
    status: str
    message: str
    data: Dict[str, Any]


class IntegrationResponse(BaseModel):
    id: str
    provider: str
    is_connected: bool
    settings: Dict[str, Any]
    created_at: str


class PageContextCreate(BaseModel):
    url: str
    domain: str
    page_title: Optional[str] = None
    html_summary: Optional[str] = None
    session_id: Optional[str] = None


class ExecutionLogResponse(BaseModel):
    id: str
    workflow_name: Optional[str] = None
    status: str
    input_data: Optional[Dict[str, Any]]
    result_data: Optional[Dict[str, Any]]
    error_message: Optional[str] = None
    started_at: str
    finished_at: Optional[str]


class UserProfileResponse(BaseModel):
    status: str
    message: str
    data: Dict[str, Any]


class CreateSessionRequest(BaseModel):
    title: Optional[str] = None


class ChatSessionResponse(BaseModel):
    id: str
    user_id: str
    title: str
    created_at: str
    updated_at: str


class ChatSessionsListResponse(BaseModel):
    status: str
    message: str
    data: List[ChatSessionResponse]


class MessageResponse(BaseModel):
    id: str
    session_id: str
    role: str
    content: str
    metadata: Dict[str, Any]
    created_at: str


class ChatHistoryResponse(BaseModel):
    status: str
    message: str
    data: List[MessageResponse]
