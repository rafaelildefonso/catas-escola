from __future__ import annotations

import uuid
from datetime import datetime, timezone
from sqlalchemy import (
    Column, String, Integer, Boolean, Float, Text, DateTime,
    ForeignKey, UniqueConstraint, CheckConstraint, JSON, ARRAY,
    types as sqltypes
)
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship, class_mapper
from sqlalchemy.dialects.postgresql import UUID, JSONB, ARRAY as PG_ARRAY


class GUID(sqltypes.TypeDecorator):
    """UUID portavel: tipo nativo no PostgreSQL; String(36) com hifens no SQLite.

    Mantenho os hifens no SQLite para casar com os ids gravados pelos models
    do novo stack (app/models/*), que usam String(36) com str(uuid4()).
    """
    impl = sqltypes.String(36)
    cache_ok = True

    def load_dialect_impl(self, dialect):
        if dialect.name == "postgresql":
            return dialect.type_descriptor(GUID)
        return dialect.type_descriptor(String(36))

    def process_bind_param(self, value, dialect):
        if value is None:
            return None
        if dialect.name == "postgresql":
            return value
        return str(value)

    def process_result_value(self, value, dialect):
        if value is None:
            return None
        if isinstance(value, uuid.UUID):
            return value
        return uuid.UUID(str(value))


class Base(DeclarativeBase):
    def to_dict(self):
        result = {}
        for prop in class_mapper(self.__class__).column_attrs:
            col_name = prop.columns[0].name
            value = getattr(self, prop.key)
            if isinstance(value, uuid.UUID):
                value = str(value)
            elif isinstance(value, datetime):
                value = value.replace(tzinfo=None).isoformat()
            result[col_name] = value
        return result


def utcnow():
    return datetime.now(timezone.utc)


class Profile(Base):
    __tablename__ = "profiles"

    id: Mapped[uuid.UUID] = mapped_column(GUID, primary_key=True)
    subscription_tier: Mapped[str] = mapped_column(String, default="basic")
    monthly_quota_limit: Mapped[int] = mapped_column(Integer, default=500)
    quota_used: Mapped[int] = mapped_column(Integer, default=0)
    rollover_credits: Mapped[int | None] = mapped_column(Integer, default=0)
    last_quota_reset: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), default=utcnow)
    language: Mapped[str] = mapped_column(String, default="en")
    industry: Mapped[str | None] = mapped_column(String, nullable=True)
    role: Mapped[str | None] = mapped_column(String, nullable=True)
    onboarding_completed: Mapped[bool] = mapped_column(Boolean, default=False)
    onboarding_data: Mapped[dict | None] = mapped_column(JSONB, default=dict)
    created_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), default=utcnow, onupdate=utcnow)

    chat_sessions = relationship("ChatSession", back_populates="profile", cascade="all, delete-orphan")
    integrations = relationship("Integration", back_populates="profile", cascade="all, delete-orphan")
    automation_runs = relationship("AutomationRun", back_populates="profile", cascade="all, delete-orphan")


class ChatSession(Base):
    __tablename__ = "chat_sessions"

    id: Mapped[uuid.UUID] = mapped_column(GUID, primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(GUID, ForeignKey("profiles.id", ondelete="CASCADE"))
    title: Mapped[str] = mapped_column(String, default="Nova Conversa")
    is_onboarding: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), default=utcnow, onupdate=utcnow)

    profile = relationship("Profile", back_populates="chat_sessions")
    messages = relationship("Message", back_populates="chat_session", cascade="all, delete-orphan")


class Message(Base):
    __tablename__ = "messages"

    id: Mapped[uuid.UUID] = mapped_column(GUID, primary_key=True, default=uuid.uuid4)
    session_id: Mapped[uuid.UUID | None] = mapped_column(GUID, ForeignKey("chat_sessions.id", ondelete="CASCADE"))
    role: Mapped[str] = mapped_column(String)
    content: Mapped[str] = mapped_column(Text)
    metadata_: Mapped[dict | None] = mapped_column("metadata", JSONB, default=dict)
    created_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), default=utcnow)

    chat_session = relationship("ChatSession", back_populates="messages")

    __table_args__ = (
        CheckConstraint("role IN ('user', 'assistant', 'system')", name="messages_role_check"),
    )


class Integration(Base):
    __tablename__ = "integrations"

    id: Mapped[uuid.UUID] = mapped_column(GUID, primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(GUID, ForeignKey("profiles.id", ondelete="CASCADE"))
    provider: Mapped[str] = mapped_column(String)
    is_connected: Mapped[bool] = mapped_column(Boolean, default=False)
    access_token: Mapped[str | None] = mapped_column(Text, nullable=True)
    refresh_token: Mapped[str | None] = mapped_column(Text, nullable=True)
    token_expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    settings: Mapped[dict | None] = mapped_column(JSONB, default=dict)
    created_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), default=utcnow, onupdate=utcnow)

    profile = relationship("Profile", back_populates="integrations")

    __table_args__ = (
        UniqueConstraint("user_id", "provider", name="integrations_user_id_provider_key"),
    )


class Automation(Base):
    __tablename__ = "automations"

    id: Mapped[uuid.UUID] = mapped_column(GUID, primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(GUID, ForeignKey("profiles.id", ondelete="CASCADE"))
    name: Mapped[str | None] = mapped_column(String, nullable=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    trigger: Mapped[dict] = mapped_column(JSONB, default=dict)
    steps: Mapped[dict] = mapped_column(JSONB, default=list)
    status: Mapped[str] = mapped_column(String, default="draft")
    version: Mapped[int] = mapped_column(Integer, default=1)
    external_ref: Mapped[dict] = mapped_column(JSONB, default=dict)
    expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), default=utcnow, onupdate=utcnow)

    __table_args__ = (
        CheckConstraint("status IN ('draft', 'active', 'paused')", name="automations_status_check"),
    )


class AutomationRun(Base):
    __tablename__ = "automation_runs"

    id: Mapped[uuid.UUID] = mapped_column(GUID, primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(GUID, ForeignKey("profiles.id", ondelete="CASCADE"))
    automation_id: Mapped[uuid.UUID | None] = mapped_column(GUID, ForeignKey("automations.id", ondelete="SET NULL"), nullable=True)
    temporal_workflow_id: Mapped[str | None] = mapped_column(String, nullable=True)
    temporal_run_id: Mapped[str | None] = mapped_column(String, nullable=True)
    correlation_id: Mapped[str] = mapped_column(String)
    status: Mapped[str] = mapped_column(String, default="pending")
    run_type: Mapped[str] = mapped_column(String, default="direct")
    input_summary: Mapped[str | None] = mapped_column(Text, nullable=True)
    input_payload: Mapped[dict] = mapped_column(JSONB, default=dict)
    result_metadata: Mapped[dict] = mapped_column(JSONB, default=dict)
    error_details: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    steps_summary: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    execution_id: Mapped[str | None] = mapped_column(String, nullable=True)
    execution_run_id: Mapped[str | None] = mapped_column(String, nullable=True)
    started_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), default=utcnow)
    finished_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), default=utcnow, onupdate=utcnow)

    profile = relationship("Profile", back_populates="automation_runs")

    __table_args__ = (
        UniqueConstraint("correlation_id", name="automation_runs_correlation_unique"),
        CheckConstraint(
            "status IN ('pending', 'running', 'paused', 'completed', 'failed', 'canceled')",
            name="automation_runs_status_check"
        ),
        CheckConstraint(
            "run_type IN ('temporal', 'n8n', 'direct')",
            name="automation_runs_run_type_check"
        ),
    )


class AutomationStepLog(Base):
    __tablename__ = "automation_step_logs"

    id: Mapped[uuid.UUID] = mapped_column(GUID, primary_key=True, default=uuid.uuid4)
    automation_id: Mapped[str] = mapped_column(String)
    step_index: Mapped[int] = mapped_column(Integer)
    module_id: Mapped[str] = mapped_column(String)
    status: Mapped[str] = mapped_column(String)
    result: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    intent: Mapped[str | None] = mapped_column(String, nullable=True)
    run_id: Mapped[uuid.UUID | None] = mapped_column(GUID, ForeignKey("automation_runs.id", ondelete="SET NULL"), nullable=True)
    user_id: Mapped[uuid.UUID | None] = mapped_column(GUID, ForeignKey("profiles.id", ondelete="CASCADE"), nullable=True)
    updated_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), default=utcnow, onupdate=utcnow)

    __table_args__ = (
        UniqueConstraint("automation_id", "step_index", name="automation_step_logs_automation_step_unique"),
    )


class AutomationGenerationLog(Base):
    __tablename__ = "automation_generation_logs"

    id: Mapped[uuid.UUID] = mapped_column(GUID, primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(GUID, ForeignKey("profiles.id", ondelete="CASCADE"))
    session_id: Mapped[uuid.UUID | None] = mapped_column(GUID, ForeignKey("chat_sessions.id", ondelete="SET NULL"), nullable=True)
    intent_raw: Mapped[str | None] = mapped_column(Text, nullable=True)
    attempts: Mapped[dict] = mapped_column(JSONB, default=list)
    errors: Mapped[dict] = mapped_column(JSONB, default=list)
    final_plan: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    model: Mapped[str | None] = mapped_column(String, nullable=True)
    tokens_used: Mapped[int | None] = mapped_column(Integer, nullable=True)
    created_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), default=utcnow)


class ExecutionLog(Base):
    __tablename__ = "execution_logs"

    id: Mapped[uuid.UUID] = mapped_column(GUID, primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(GUID, ForeignKey("profiles.id", ondelete="CASCADE"))
    suggestion_id: Mapped[uuid.UUID | None] = mapped_column(GUID, ForeignKey("ai_suggestions.id", ondelete="SET NULL"), nullable=True)
    session_id: Mapped[uuid.UUID | None] = mapped_column(GUID, ForeignKey("chat_sessions.id", ondelete="SET NULL"), nullable=True)
    workflow_name: Mapped[str | None] = mapped_column(String, nullable=True)
    status: Mapped[str] = mapped_column(String, default="running")
    input_data: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    result_data: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    error_message: Mapped[str | None] = mapped_column(Text, nullable=True)
    started_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), default=utcnow)
    finished_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    __table_args__ = (
        CheckConstraint("status IN ('running', 'success', 'failed')", name="execution_logs_status_check"),
    )


class AiSuggestion(Base):
    __tablename__ = "ai_suggestions"

    id: Mapped[uuid.UUID] = mapped_column(GUID, primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(GUID, ForeignKey("profiles.id", ondelete="CASCADE"))
    context_id: Mapped[uuid.UUID | None] = mapped_column(GUID, ForeignKey("page_contexts.id", ondelete="SET NULL"), nullable=True)
    title: Mapped[str] = mapped_column(String)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    confidence_score: Mapped[float | None] = mapped_column(Float, nullable=True)
    payload_preview: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    suggested_workflow: Mapped[str | None] = mapped_column(String, nullable=True)
    status: Mapped[str] = mapped_column(String, default="pending")
    created_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), default=utcnow)

    __table_args__ = (
        CheckConstraint(
            "status IN ('pending', 'accepted', 'rejected', 'executed')",
            name="ai_suggestions_status_check"
        ),
    )


class PageContext(Base):
    __tablename__ = "page_contexts"

    id: Mapped[uuid.UUID] = mapped_column(GUID, primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(GUID, ForeignKey("profiles.id", ondelete="CASCADE"))
    session_id: Mapped[uuid.UUID | None] = mapped_column(GUID, ForeignKey("browser_sessions.id", ondelete="SET NULL"), nullable=True)
    url: Mapped[str] = mapped_column(Text)
    domain: Mapped[str] = mapped_column(String)
    page_title: Mapped[str | None] = mapped_column(String, nullable=True)
    html_summary: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), default=utcnow)


class MessageFeedback(Base):
    __tablename__ = "message_feedback"

    id: Mapped[uuid.UUID] = mapped_column(GUID, primary_key=True, default=uuid.uuid4)
    message_id: Mapped[uuid.UUID] = mapped_column(GUID)
    user_id: Mapped[uuid.UUID] = mapped_column(GUID)
    session_id: Mapped[uuid.UUID] = mapped_column(GUID)
    is_liked: Mapped[bool] = mapped_column(Boolean)
    reason: Mapped[str | None] = mapped_column(String, nullable=True)
    created_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), default=utcnow, onupdate=utcnow)

    __table_args__ = (
        UniqueConstraint("message_id", "user_id", name="uq_feedback_message_user"),
    )


class UserWebhookConfig(Base):
    __tablename__ = "user_webhook_configs"

    id: Mapped[uuid.UUID] = mapped_column(GUID, primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(GUID, ForeignKey("profiles.id", ondelete="CASCADE"))
    automation_id: Mapped[uuid.UUID | None] = mapped_column(GUID, ForeignKey("automations.id", ondelete="SET NULL"), nullable=True)
    slug: Mapped[str] = mapped_column(String, unique=True)
    name: Mapped[str] = mapped_column(String)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    hmac_secret: Mapped[str] = mapped_column(String)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    allowed_sources: Mapped[list | None] = mapped_column(PG_ARRAY(String), nullable=True)
    payload_mapping: Mapped[dict] = mapped_column(JSONB, default=dict)
    created_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), default=utcnow, onupdate=utcnow)


class UserDevice(Base):
    __tablename__ = "user_devices"

    id: Mapped[uuid.UUID] = mapped_column(GUID, primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(GUID, ForeignKey("profiles.id", ondelete="CASCADE"))
    fcm_token: Mapped[str] = mapped_column(String)
    platform: Mapped[str | None] = mapped_column(String, nullable=True)
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    last_seen_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), default=utcnow)
    created_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), default=utcnow, onupdate=utcnow)

    __table_args__ = (
        UniqueConstraint("user_id", "fcm_token", name="user_devices_user_id_fcm_token_key"),
        CheckConstraint(
            "platform IN ('android', 'ios', 'web')",
            name="user_devices_platform_check"
        ),
    )


class IaMemory(Base):
    __tablename__ = "ia_memory"

    id: Mapped[uuid.UUID] = mapped_column(GUID, primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(GUID, ForeignKey("profiles.id", ondelete="CASCADE"))
    key: Mapped[str] = mapped_column(String, default="user_preference")
    content: Mapped[str] = mapped_column(Text)
    embedding: Mapped[list | None] = mapped_column(JSONB, nullable=True)
    metadata_: Mapped[dict] = mapped_column("metadata", JSONB, default=dict)
    created_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), default=utcnow)


class BrowserSession(Base):
    __tablename__ = "browser_sessions"

    id: Mapped[uuid.UUID] = mapped_column(GUID, primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID | None] = mapped_column(GUID, ForeignKey("profiles.id", ondelete="CASCADE"), nullable=True)
    user_agent: Mapped[str | None] = mapped_column(String, nullable=True)
    started_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), default=utcnow)
    last_activity_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), default=utcnow)


class PageAnalysisCache(Base):
    __tablename__ = "page_analysis_cache"

    url_hash: Mapped[str] = mapped_column(String, primary_key=True)
    url: Mapped[str] = mapped_column(Text)
    analysis_result: Mapped[dict] = mapped_column(JSONB)
    created_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), default=utcnow)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
