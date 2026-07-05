import pytest
from datetime import datetime, timezone, timedelta

from app.extensions import db
from app.models.profile import Profile
from app.models.chat_session import ChatSession
from app.models.message import Message
from app.models.integration import Integration
from app.models.automation import Automation
from app.models.automation_run import AutomationRun
from app.models.automation_step_log import AutomationStepLog
from app.models.automation_generation_log import AutomationGenerationLog
from app.models.execution_log import ExecutionLog
from app.models.message_feedback import MessageFeedback
from app.models.ai_suggestion import AiSuggestion
from app.models.page_context import PageContext
from app.models.browser_session import BrowserSession
from app.models.page_analysis_cache import PageAnalysisCache
from app.models.user_device import UserDevice
from app.models.user_webhook_config import UserWebhookConfig
from app.models.ia_memory import IaMemory


def utcnow():
    return datetime.now(timezone.utc)


def _profile(app, **kw):
    with app.app_context():
        p = Profile(language="en", **(kw))
        p.salvar()
        return p


def _session(app, user_id, **kw):
    with app.app_context():
        s = ChatSession(user_id=user_id, title="T", **(kw))
        s.salvar()
        return s


def _message(app, session_id, **kw):
    with app.app_context():
        m = Message(session_id=session_id, role="user", content="test", **(kw))
        m.salvar()
        return m


class TestAllModelsCRUD:
    """CRUD tests for every model — each test creates its own data inline."""

    def test_profile(self, app):
        with app.app_context():
            p = Profile(language="pt", subscription_tier="pro")
            p.salvar()
            assert p.id is not None
            assert Profile.buscar_por_id(p.id).language == "pt"
            p.atualizar(language="en")
            assert Profile.buscar_por_id(p.id).language == "en"
            p.deletar()
            assert Profile.buscar_por_id(p.id) is None

    def test_chat_session(self, app):
        with app.app_context():
            p = Profile(language="en"); p.salvar()
            s = ChatSession(user_id=p.id, title="Test")
            s.salvar()
            assert s.id is not None
            assert ChatSession.buscar_por_id(s.id).title == "Test"
            s.atualizar(title="Updated")
            assert ChatSession.buscar_por_id(s.id).title == "Updated"
            s.deletar()
            assert ChatSession.buscar_por_id(s.id) is None

    def test_message(self, app):
        with app.app_context():
            p = Profile(language="en"); p.salvar()
            s = ChatSession(user_id=p.id, title="S"); s.salvar()
            m = Message(session_id=s.id, role="user", content="Hello")
            m.salvar()
            assert Message.buscar_por_id(m.id).content == "Hello"
            m.atualizar(content="Changed")
            assert Message.buscar_por_id(m.id).content == "Changed"
            m.deletar()
            assert Message.buscar_por_id(m.id) is None

    def test_integration(self, app):
        with app.app_context():
            p = Profile(language="en"); p.salvar()
            i = Integration(user_id=p.id, provider="slack", access_token="xoxb-test")
            i.salvar()
            assert Integration.buscar_por_id(i.id).provider == "slack"
            i.atualizar(provider="google")
            assert Integration.buscar_por_id(i.id).provider == "google"
            i.deletar()
            assert Integration.buscar_por_id(i.id) is None

    def test_automation(self, app):
        with app.app_context():
            p = Profile(language="en"); p.salvar()
            a = Automation(user_id=p.id, name="Auto", trigger={"type": "manual"}, steps=[])
            a.salvar()
            assert Automation.buscar_por_id(a.id).name == "Auto"
            a.atualizar(name="Changed")
            assert Automation.buscar_por_id(a.id).name == "Changed"
            a.deletar()
            assert Automation.buscar_por_id(a.id) is None

    def test_automation_run(self, app):
        with app.app_context():
            p = Profile(language="en"); p.salvar()
            a = Automation(user_id=p.id, name="A", trigger={}, steps=[]); a.salvar()
            r = AutomationRun(user_id=p.id, automation_id=a.id, status="pending", correlation_id="c1")
            r.salvar()
            assert AutomationRun.buscar_por_id(r.id).status == "pending"
            r.atualizar(status="completed")
            assert AutomationRun.buscar_por_id(r.id).status == "completed"
            r.deletar()
            assert AutomationRun.buscar_por_id(r.id) is None

    def test_automation_step_log(self, app):
        with app.app_context():
            p = Profile(language="en"); p.salvar()
            a = Automation(user_id=p.id, name="A", trigger={}, steps=[]); a.salvar()
            r = AutomationRun(user_id=p.id, automation_id=a.id, status="pending", correlation_id="c"); r.salvar()
            sl = AutomationStepLog(run_id=r.id, user_id=p.id, automation_id=a.id, step_index=0, module_id="m", status="pending")
            sl.salvar()
            assert AutomationStepLog.buscar_por_id(sl.id).status == "pending"
            sl.atualizar(status="success")
            assert AutomationStepLog.buscar_por_id(sl.id).status == "success"
            sl.deletar()
            assert AutomationStepLog.buscar_por_id(sl.id) is None

    def test_automation_generation_log(self, app):
        with app.app_context():
            p = Profile(language="en"); p.salvar()
            gl = AutomationGenerationLog(user_id=p.id, intent_raw="hi")
            gl.salvar()
            assert AutomationGenerationLog.buscar_por_id(gl.id).intent_raw == "hi"

    def test_execution_log(self, app):
        with app.app_context():
            p = Profile(language="en"); p.salvar()
            el = ExecutionLog(user_id=p.id, workflow_name="test", status="running")
            el.salvar()
            assert ExecutionLog.buscar_por_id(el.id).workflow_name == "test"

    def test_message_feedback(self, app):
        with app.app_context():
            p = Profile(language="en"); p.salvar()
            s = ChatSession(user_id=p.id, title="S"); s.salvar()
            m = Message(session_id=s.id, role="user", content="hi"); m.salvar()
            fb = MessageFeedback(message_id=m.id, user_id=p.id, session_id=s.id, is_liked=True)
            fb.salvar()
            assert MessageFeedback.buscar_por_id(fb.id).is_liked is True

    def test_ai_suggestion(self, app):
        with app.app_context():
            p = Profile(language="en"); p.salvar()
            sug = AiSuggestion(user_id=p.id, title="T", description="my context", status="pending")
            sug.salvar()
            assert AiSuggestion.buscar_por_id(sug.id).title == "T"

    def test_page_context(self, app):
        with app.app_context():
            p = Profile(language="en"); p.salvar()
            pc = PageContext(user_id=p.id, url="https://ex.com", domain="ex.com")
            pc.salvar()
            assert PageContext.buscar_por_id(pc.id).url == "https://ex.com"

    def test_browser_session(self, app):
        with app.app_context():
            p = Profile(language="en"); p.salvar()
            bs = BrowserSession(user_id=p.id, user_agent="Mozilla/5.0")
            bs.salvar()
            assert BrowserSession.buscar_por_id(bs.id).user_agent == "Mozilla/5.0"

    def test_page_analysis_cache(self, app):
        with app.app_context():
            pac = PageAnalysisCache(url_hash="x", url="https://ex.com", analysis_result={}, expires_at=utcnow())
            pac.salvar()
            found = PageAnalysisCache.buscar_por_id("x")
            assert found.url == "https://ex.com"
            pac.deletar()
            assert PageAnalysisCache.buscar_por_id("x") is None

    def test_user_device(self, app):
        with app.app_context():
            p = Profile(language="en"); p.salvar()
            d = UserDevice(user_id=p.id, platform="ios", fcm_token="tok")
            d.salvar()
            assert UserDevice.buscar_por_id(d.id).platform == "ios"

    def test_user_webhook_config(self, app):
        with app.app_context():
            p = Profile(language="en"); p.salvar()
            wh = UserWebhookConfig(user_id=p.id, slug="hook1", name="Hook", hmac_secret="secret")
            wh.salvar()
            assert UserWebhookConfig.buscar_por_id(wh.id).slug == "hook1"

    def test_ia_memory(self, app):
        with app.app_context():
            p = Profile(language="en"); p.salvar()
            mem = IaMemory(user_id=p.id, key="pref", content="likes dark")
            mem.salvar()
            assert IaMemory.buscar_por_id(mem.id).content == "likes dark"
