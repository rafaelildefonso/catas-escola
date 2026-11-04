import json
from uuid import uuid4

from models.user import User
from models.profile import Profile
from models.termo_aceite import TermoAceite


def _criar_usuario(app, tier="basic"):
    """Cria usuário + perfil e devolve headers com JWT válido."""
    with app.app_context():
        user = User(email=f"termos-{uuid4().hex[:8]}@test.com")
        user.set_password("password123")
        profile = Profile(id=user.id, subscription_tier=tier)
        user.salvar()
        profile.salvar()
        token = user.generate_token()
        return {
            "id": user.id,
            "headers": {"Authorization": f"Bearer {token}"},
        }


class TestTermosAceiteEndpoints:
    BASE = "/api/v1/termos/aceite"

    def test_requer_autenticacao(self, client):
        assert client.get(self.BASE).status_code == 401
        assert client.post(self.BASE, data="{}").status_code == 401

    def test_consulta_sem_aceite(self, client, app):
        usuario = _criar_usuario(app)
        resp = client.get(self.BASE, headers=usuario["headers"])
        assert resp.status_code == 200
        corpo = resp.json
        assert corpo["aceito_todos"] is False
        assert corpo["versao_atual"] == "1.0"
        assert corpo["termos"]["uso"] is None
        assert corpo["termos"]["consentimento"] is None

    def test_registrar_aceite_padrao(self, client, app):
        usuario = _criar_usuario(app)
        resp = client.post(
            self.BASE,
            data="{}",
            content_type="application/json",
            headers=usuario["headers"],
        )
        assert resp.status_code == 201
        assert resp.json["aceito_todos"] is True
        assert resp.json["versao"] == "1.0"
        tipos = {item["tipo"] for item in resp.json["termos"]}
        assert tipos == {"uso", "consentimento"}

        # Consulta reflete o aceite registrado
        resp = client.get(self.BASE, headers=usuario["headers"])
        assert resp.json["aceito_todos"] is True
        assert resp.json["termos"]["uso"]["versao"] == "1.0"
        assert resp.json["termos"]["consentimento"]["origem"] == "web"

    def test_nao_duplica_aceite_da_mesma_versao(self, client, app):
        usuario = _criar_usuario(app)
        headers = {"Content-Type": "application/json", **usuario["headers"]}
        client.post(self.BASE, data="{}", content_type="application/json", headers=headers)
        client.post(self.BASE, data="{}", content_type="application/json", headers=headers)

        with app.app_context():
            registros = TermoAceite.listar_por_usuario(usuario["id"])
            assert len(registros) == 2  # um 'uso' + um 'consentimento'

    def test_rejeita_tipo_invalido(self, client, app):
        usuario = _criar_usuario(app)
        resp = client.post(
            self.BASE,
            data=json.dumps({"tipos": ["bananinha"]}),
            content_type="application/json",
            headers=usuario["headers"],
        )
        assert resp.status_code == 400


class TestSignupComTermos:
    SIGNUP = "/api/v1/auth/signup"

    def test_signup_sem_aceite_e_recusado(self, client):
        resp = client.post(
            self.SIGNUP,
            data=json.dumps({"email": "semtermo@test.com", "password": "senha12345"}),
            content_type="application/json",
        )
        assert resp.status_code == 400
        assert "aceitar" in resp.json["detail"].lower()

    def test_signup_com_aceite_registra_termos(self, client, app):
        resp = client.post(
            self.SIGNUP,
            data=json.dumps(
                {
                    "email": "comtermo@test.com",
                    "password": "senha12345",
                    "aceito_termos": True,
                }
            ),
            content_type="application/json",
        )
        assert resp.status_code == 201
        user_id = resp.json["user"]["id"]

        with app.app_context():
            aceite_uso = TermoAceite.buscar_ultimo(user_id, "uso")
            aceite_consent = TermoAceite.buscar_ultimo(user_id, "consentimento")
            assert aceite_uso is not None
            assert aceite_consent is not None
            assert aceite_uso.origem == "signup"
            assert aceite_uso.versao == "1.0"
