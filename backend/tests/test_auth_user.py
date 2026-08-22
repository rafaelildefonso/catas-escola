import importlib
import inspect
import json
import pkgutil

import models
import controllers
from extensions import db
from models.user import User


CRUD_METHODS = ["salvar", "atualizar", "deletar", "listar_todos", "buscar_por_id", "to_dict"]


def _all_models():
    from sqlalchemy.orm import DeclarativeMeta
    result = []
    for name in dir(models):
        obj = getattr(models, name)
        if isinstance(obj, DeclarativeMeta) and issubclass(obj, db.Model):
            result.append(obj)
    return result


def _controller_modules():
    modules = []
    for _, modname, ispkg in pkgutil.iter_modules(controllers.__path__):
        if ispkg:
            continue
        modules.append(importlib.import_module(f"{controllers.__name__}.{modname}"))
    return modules


class TestUserModelCRUD:
    def test_criar_e_listar(self, app):
        with app.app_context():
            u = User(email="a@test.com")
            u.set_password("password123")
            u.salvar()
            assert u.id is not None
            assert User.listar_todos() == [u]

    def test_buscar_por_id(self, app):
        with app.app_context():
            u = User(email="b@test.com")
            u.set_password("password123")
            u.salvar()
            assert User.buscar_por_id(u.id).email == "b@test.com"

    def test_buscar_por_email(self, app):
        with app.app_context():
            u = User(email="c@test.com")
            u.set_password("password123")
            u.salvar()
            assert User.buscar_por_email("c@test.com") is u

    def test_atualizar_email(self, app):
        with app.app_context():
            u = User(email="d@test.com")
            u.set_password("password123")
            u.salvar()
            u.atualizar(email="d2@test.com")
            assert User.buscar_por_id(u.id).email == "d2@test.com"

    def test_atualizar_senha_via_set_password(self, app):
        with app.app_context():
            u = User(email="e@test.com")
            u.set_password("password123")
            u.salvar()
            u.set_password("newpass123")
            updated = User.buscar_por_id(u.id)
            assert updated.check_password("newpass123")
            assert not updated.check_password("password123")

    def test_atualizar_ignora_password_hash_direto(self, app):
        with app.app_context():
            u = User(email="f@test.com")
            u.set_password("password123")
            u.salvar()
            u.atualizar(password_hash="raw-hash")  # não deve sobrescrever
            updated = User.buscar_por_id(u.id)
            assert updated.check_password("password123")

    def test_deletar(self, app):
        with app.app_context():
            u = User(email="g@test.com")
            u.set_password("password123")
            u.salvar()
            u.deletar()
            assert User.buscar_por_id(u.id) is None


class TestAuthFlow:
    BASE = "/api/v1/auth"

    def test_signup(self, client):
        resp = client.post(
            f"{self.BASE}/signup",
            data=json.dumps({"email": "signup@test.com", "password": "password123"}),
            content_type="application/json",
        )
        assert resp.status_code == 201
        data = resp.json
        assert data["token"]
        assert data["user"]["email"] == "signup@test.com"
        assert data["profile"]["subscription_tier"] == "basic"

    def test_signup_email_valido_e_senha_minima(self, client):
        resp = client.post(
            f"{self.BASE}/signup",
            data=json.dumps({"email": "invalido", "password": "password123"}),
            content_type="application/json",
        )
        assert resp.status_code == 400

    def test_signup_duplicado(self, client):
        payload = json.dumps({"email": "dup@test.com", "password": "password123"})
        assert client.post(f"{self.BASE}/signup", data=payload, content_type="application/json").status_code == 201
        resp = client.post(f"{self.BASE}/signup", data=payload, content_type="application/json")
        assert resp.status_code == 409

    def test_login(self, client):
        client.post(
            f"{self.BASE}/signup",
            data=json.dumps({"email": "login@test.com", "password": "password123"}),
            content_type="application/json",
        )
        resp = client.post(
            f"{self.BASE}/login",
            data=json.dumps({"email": "login@test.com", "password": "password123"}),
            content_type="application/json",
        )
        assert resp.status_code == 200
        assert resp.json["token"]
        assert resp.json["user"]["email"] == "login@test.com"

    def test_login_senha_incorreta(self, client):
        client.post(
            f"{self.BASE}/signup",
            data=json.dumps({"email": "wrong@test.com", "password": "password123"}),
            content_type="application/json",
        )
        resp = client.post(
            f"{self.BASE}/login",
            data=json.dumps({"email": "wrong@test.com", "password": "nope1234"}),
            content_type="application/json",
        )
        assert resp.status_code == 401

    def test_me(self, client):
        signup = client.post(
            f"{self.BASE}/signup",
            data=json.dumps({"email": "me@test.com", "password": "password123"}),
            content_type="application/json",
        ).json
        resp = client.get(
            f"{self.BASE}/me",
            headers={"Authorization": f"Bearer {signup['token']}"},
        )
        assert resp.status_code == 200
        assert resp.json["user"]["email"] == "me@test.com"
        assert resp.json["profile"] is not None

    def test_me_nao_autenticado(self, client):
        resp = client.get(f"{self.BASE}/me")
        assert resp.status_code == 401


class TestUserControllerRoutes:
    BASE = "/api/v1/users"

    def test_criar_listar_buscar(self, client):
        created = client.post(
            self.BASE,
            data=json.dumps({"email": "user1@test.com", "password": "password123"}),
            content_type="application/json",
        )
        assert created.status_code == 201
        user_id = created.json["id"]
        listed = client.get(self.BASE)
        assert listed.status_code == 200
        assert any(u["id"] == user_id for u in listed.json)
        found = client.get(f"{self.BASE}/{user_id}")
        assert found.status_code == 200
        assert found.json["email"] == "user1@test.com"

    def test_atualizar(self, client):
        user_id = client.post(
            self.BASE,
            data=json.dumps({"email": "src2@test.com", "password": "password123"}),
            content_type="application/json",
        ).json["id"]
        resp = client.put(f"{self.BASE}/{user_id}", data=json.dumps({"email": "src2b@test.com"}), content_type="application/json")
        assert resp.status_code == 200
        assert resp.json["email"] == "src2b@test.com"

    def test_deletar(self, client):
        user_id = client.post(
            self.BASE,
            data=json.dumps({"email": "src3@test.com", "password": "password123"}),
            content_type="application/json",
        ).json["id"]
        resp = client.delete(f"{self.BASE}/{user_id}")
        assert resp.status_code in (200, 204)
        assert client.get(f"{self.BASE}/{user_id}").status_code == 404


class TestArchitectureCompliance:
    def test_todo_model_tem_metodos_crud(self):
        for model in _all_models():
            for method in CRUD_METHODS:
                assert hasattr(model, method), f"{model.__name__} falta {method}()"

    def test_nenhuma_controller_faz_persistencia_direta(self):
        for mod in _controller_modules():
            src = inspect.getsource(mod)
            assert "db.session." not in src, f"{mod.__name__} usa persistencia direta"
            assert "from extensions import db" not in src, f"{mod.__name__} importa db"
            assert "import db" not in src

    def test_controller_chama_service(self):
        for mod in _controller_modules():
            src = inspect.getsource(mod)
            assert "from services" in src, f"{mod.__name__} nao chama services"