import pytest
import json
import uuid
from datetime import datetime, timedelta, timezone

from jose import jwt
from core.config import settings

from models.profile import Profile
from models.chat_session import ChatSession
from models.message import Message


def _profile_auth(user_id):
    token = jwt.encode(
        {"user_id": user_id, "email": "owner@example.com", "exp": datetime.now(timezone.utc) + timedelta(minutes=10)},
        settings.JWT_SECRET_KEY,
        algorithm="HS256",
    )
    return {"Authorization": f"Bearer {token}"}


class TestProfileModelCRUD:
    def test_criar_e_listar(self, app):
        with app.app_context():
            p = Profile(
                subscription_tier="pro",
                language="pt",
                industry="tech",
            )
            p.salvar()
            assert p.id is not None
            assert Profile.listar_todos() == [p]

    def test_buscar_por_id(self, app):
        with app.app_context():
            p = Profile(language="en")
            p.salvar()
            found = Profile.buscar_por_id(p.id)
            assert found is not None
            assert found.language == "en"

    def test_atualizar(self, app):
        with app.app_context():
            p = Profile(subscription_tier="basic")
            p.salvar()
            p.atualizar(subscription_tier="pro")
            updated = Profile.buscar_por_id(p.id)
            assert updated.subscription_tier == "pro"

    def test_deletar(self, app):
        with app.app_context():
            p = Profile(language="en")
            p.salvar()
            p.deletar()
            assert Profile.buscar_por_id(p.id) is None

    def test_to_dict(self, app):
        with app.app_context():
            p = Profile(language="pt-BR", subscription_tier="pro")
            p.salvar()
            d = p.to_dict()
            assert d["language"] == "pt-BR"
            assert d["subscription_tier"] == "pro"
            assert "id" in d


class TestChatSessionModelCRUD:
    def test_criar_com_profile(self, app):
        with app.app_context():
            p = Profile(language="en")
            p.salvar()
            s = ChatSession(user_id=p.id, title="Test Session")
            s.salvar()
            assert s.id is not None
            assert s.title == "Test Session"

    def test_relacionamento_messages(self, app):
        with app.app_context():
            p = Profile(language="en")
            p.salvar()
            s = ChatSession(user_id=p.id, title="Rel Session")
            s.salvar()
            m = Message(session_id=s.id, role="user", content="Hello")
            m.salvar()
            assert m in s.messages


class TestMessageModelCRUD:
    def test_criar_mensagem(self, app):
        with app.app_context():
            p = Profile(language="en")
            p.salvar()
            s = ChatSession(user_id=p.id, title="Msg Session")
            s.salvar()
            m = Message(session_id=s.id, role="user", content="Test message")
            m.salvar()
            found = Message.buscar_por_id(m.id)
            assert found.content == "Test message"
            assert found.role == "user"

    def test_role_check_constraint(self, app):
        with app.app_context():
            p = Profile(language="en")
            p.salvar()
            s = ChatSession(user_id=p.id, title="Role Session")
            s.salvar()
            with pytest.raises(Exception):
                m = Message(session_id=s.id, role="invalid_role", content="Bad")
                m.salvar()


class TestProfileController:
    BASE = "/api/v1/profiles"

    def test_listar_vazio(self, client):
        assert client.get(self.BASE).status_code == 401
        resp = client.get(self.BASE, headers=_profile_auth(str(uuid.uuid4())))
        assert resp.status_code == 200
        assert resp.json == []

    def test_criar(self, client, app):
        with app.app_context():
            user_id = str(uuid.uuid4())
            resp = client.post(
                self.BASE,
                data=json.dumps({"language": "pt-BR", "subscription_tier": "pro"}),
                content_type="application/json",
                headers=_profile_auth(user_id),
            )
            assert resp.status_code in (200, 201)
            data = resp.json
            assert data["language"] == "pt-BR"
            assert data["id"] == user_id
            assert data["subscription_tier"] == "basic"

    def test_criar_e_buscar(self, client, app):
        with app.app_context():
            user_id = str(uuid.uuid4())
            headers = _profile_auth(user_id)
            created = client.post(
                self.BASE,
                data=json.dumps({"language": "en", "industry": "tech"}),
                content_type="application/json",
                headers=headers,
            ).json
            resp = client.get(f"{self.BASE}/{created['id']}", headers=headers)
            assert resp.status_code == 200
            assert resp.json["language"] == "en"
            assert client.get(f"{self.BASE}/{created['id']}", headers=_profile_auth(str(uuid.uuid4()))).status_code == 404

    def test_atualizar(self, client, app):
        with app.app_context():
            headers = _profile_auth(str(uuid.uuid4()))
            created = client.post(
                self.BASE,
                data=json.dumps({"language": "es", "subscription_tier": "basic"}),
                content_type="application/json",
                headers=headers,
            ).json
            resp = client.put(
                f"{self.BASE}/{created['id']}",
                data=json.dumps({"language": "pt"}),
                content_type="application/json",
                headers=headers,
            )
            assert resp.status_code == 200
            assert resp.json["language"] == "pt"
            assert resp.json["subscription_tier"] == "basic"
            alteracao_plano = client.put(
                f"{self.BASE}/{created['id']}",
                data=json.dumps({"subscription_tier": "pro"}),
                content_type="application/json",
                headers=headers,
            )
            assert alteracao_plano.status_code == 400
            assert client.put(f"{self.BASE}/{created['id']}", json={"language": "fr"}, headers=_profile_auth(str(uuid.uuid4()))).status_code == 404

    def test_deletar(self, client, app):
        with app.app_context():
            headers = _profile_auth(str(uuid.uuid4()))
            created = client.post(
                self.BASE,
                data=json.dumps({"language": "fr"}),
                content_type="application/json",
                headers=headers,
            ).json
            assert client.delete(f"{self.BASE}/{created['id']}", headers=_profile_auth(str(uuid.uuid4()))).status_code == 404
            resp = client.delete(f"{self.BASE}/{created['id']}", headers=headers)
            assert resp.status_code in (200, 204)
            resp2 = client.get(f"{self.BASE}/{created['id']}", headers=headers)
            assert resp2.status_code == 404


class TestRoutes:
    def test_health(self, client):
        resp = client.get("/health")
        assert resp.status_code == 200
        assert resp.json == {"status": "ok"}

    def test_root(self, client):
        resp = client.get("/")
        assert resp.status_code == 200
        assert "version" in resp.json

    def test_all_crud_routes_registered(self, app):
        rules = sorted([r.rule for r in app.url_map.iter_rules()])
        expected_prefixes = [
            "/api/v1/profiles",
            "/api/v1/users",
            "/api/v1/chat-sessions",
            "/api/v1/messages",
            "/api/v1/automations",
            "/api/v1/automation-runs",
            "/api/v1/automation-step-logs",
            "/api/v1/automation-generation-logs",
            "/api/v1/execution-logs",
            "/api/v1/integrations",
            "/api/v1/message-feedback",
            "/api/v1/ai-suggestions",
            "/api/v1/page-contexts",
            "/api/v1/browser-sessions",
            "/api/v1/page-analysis-cache",
            "/api/v1/user-devices",
            "/api/v1/user-webhook-configs",
            "/api/v1/ia-memories",
        ]
        for prefix in expected_prefixes:
            count = sum(1 for r in rules if r.startswith(prefix))
            assert count >= 5, f"{prefix} tem apenas {count} rotas (esperado >= 5)"
