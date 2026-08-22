import json
from datetime import datetime, timedelta, timezone

from models.automation import Automation
from models.automation_run import AutomationRun
from models.chat_session import ChatSession
from models.integration import Integration
from models.message import Message
from models.message_feedback import MessageFeedback
from models.profile import Profile


class _Contexto:
    pass


_contexto = _Contexto()
_next_id = 0


def _criar_contexto(app):
    """Cria perfil + sessão + mensagens + automações/runs + integrações."""
    global _next_id
    perfil = Profile(language="pt-BR", subscription_tier="pro")
    perfil.salvar()
    sessao = ChatSession(user_id=perfil.id, title="Conversa de testes")
    sessao.salvar()
    msg1 = Message(session_id=sessao.id, role="user", content="Quero um relatório de vendas")
    msg2 = Message(session_id=sessao.id, role="assistant", content="Gerando relatório de vendas...")
    msg3 = Message(session_id=sessao.id, role="user", content="Outro assunto qualquer")
    msg1.salvar()
    msg2.salvar()
    msg3.salvar()
    MessageFeedback(message_id=msg1.id, user_id=perfil.id, session_id=sessao.id, is_liked=True).salvar()
    MessageFeedback(message_id=msg2.id, user_id=perfil.id, session_id=sessao.id, is_liked=False).salvar()

    automacao = Automation(user_id=perfil.id, name="Relatorio semanal", description="Gera PDF")
    automacao.salvar()

    antigo = datetime.now(timezone.utc) - timedelta(days=2)
    for status in ("completed", "failed", "completed"):
        _next_id += 1
        run = AutomationRun(
            user_id=perfil.id,
            automation_id=automacao.id,
            correlation_id=f"corr-{status}-{_next_id}",
            status=status,
            input_summary="gerar relatorio",
        )
        run.created_at = antigo
        run.salvar()

    Integration(user_id=perfil.id, provider="gmail", is_connected=True).salvar()
    Integration(user_id=perfil.id, provider="google_sheets", is_connected=True).salvar()

    _contexto.usuario_id = perfil.id
    _contexto.automation_id = automacao.id
    _contexto.session_id = sessao.id


class TestRelatorioController:
    def test_dashboard_estatisticas(self, client, app):
        with app.app_context():
            _criar_contexto(app)
            resp = client.get(f"/api/v1/relatorios/dashboard?user_id={_contexto.usuario_id}")
            assert resp.status_code == 200
            dados = resp.json
            assert dados["total_execucoes"] == 3
            assert dados["taxa_sucesso"] == 67
            assert dados["execucoes_por_status"]["completed"] == 2
            integracoes = {r["provider"]: r["total"] for r in dados["top_integracoes"]}
            assert integracoes == {"gmail": 1, "google_sheets": 1}
            assert dados["total_sessoes_chat"] == 1
            assert dados["total_mensagens_chat"] == 3

    def test_dashboard_exige_user_id(self, client):
        resp = client.get("/api/v1/relatorios/dashboard")
        assert resp.status_code == 400
        assert "user_id" in resp.json["detail"]

    def test_relatorio_automacoes_paginado(self, client, app):
        with app.app_context():
            _criar_contexto(app)
            u = _contexto.usuario_id
            resp = client.get(f"/api/v1/relatorios/automacoes?user_id={u}")
            assert resp.status_code == 200
            dados = resp.json
            assert dados["total"] == 3
            assert len(dados["items"]) == 3
            assert dados["items"][0]["automation_name"] == "Relatorio semanal"

            filtro_status = client.get(f"/api/v1/relatorios/automacoes?user_id={u}&status=completed")
            assert filtro_status.json["total"] == 2

            busca_errada = client.get(f"/api/v1/relatorios/automacoes?user_id={u}&busca=inexistente")
            assert busca_errada.json["total"] == 0

    def test_relatorio_automacoes_busca_curta_rejeitada(self, client, app):
        with app.app_context():
            _criar_contexto(app)
            resp = client.get(f"/api/v1/relatorios/automacoes?user_id={_contexto.usuario_id}&busca=a")
            assert resp.status_code == 400

    def test_relatorio_chat(self, client, app):
        with app.app_context():
            _criar_contexto(app)
            resp = client.get(f"/api/v1/relatorios/chat?user_id={_contexto.usuario_id}")
            assert resp.status_code == 200
            dados = resp.json
            assert dados["total_mensagens"] == 3
            assert dados["total_sessoes"] == 1
            assert dados["sessoes_ativas"] == 1
            assert dados["mensagens_por_role"]["user"] == 2
            assert dados["feedback"]["likes"] == 1
            assert dados["feedback"]["dislikes"] == 1

    def test_buscar_mensagens(self, client, app):
        with app.app_context():
            _criar_contexto(app)
            resp = client.get(
                f"/api/v1/relatorios/mensagens/busca?user_id={_contexto.usuario_id}&termo=vendas"
            )
            assert resp.status_code == 200
            dados = resp.json
            assert dados["total"] == 2
            assert all("vendas" in item["content"] for item in dados["items"])

    def test_buscar_mensagens_sem_termo(self, client, app):
        with app.app_context():
            _criar_contexto(app)
            resp = client.get(f"/api/v1/relatorios/mensagens/busca?user_id={_contexto.usuario_id}")
            assert resp.status_code == 200
            assert resp.json == {"items": [], "total": 0}


class TestRotasRelatorios:
    def test_rotas_registradas(self, app):
        rules = [r.rule for r in app.url_map.iter_rules()]
        for esperada in (
            "/api/v1/relatorios/dashboard",
            "/api/v1/relatorios/automacoes",
            "/api/v1/relatorios/chat",
            "/api/v1/relatorios/mensagens/busca",
        ):
            assert esperada in rules, f"rota ausente: {esperada}"