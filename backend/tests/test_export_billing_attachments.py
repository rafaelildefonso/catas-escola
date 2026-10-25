from datetime import datetime, timedelta, timezone
from io import BytesIO
from types import SimpleNamespace
import zipfile

import stripe
from jose import jwt
from openpyxl import load_workbook
import pytest

from core.config import settings
from models.profile import Profile
from models.attachment import Attachment
from services.billing.billing_service import BillingService
from services.relatorio.exportar_relatorio_service import (
    ExportacaoRelatorioError,
    ExportarRelatorioService,
)
from services.storage.attachment_service import AttachmentError, AttachmentService
from services.profile.atualizar_profile_service import AtualizarProfileService


def _token(user_id):
    return jwt.encode(
        {
            "user_id": user_id,
            "email": "test@example.com",
            "exp": datetime.now(timezone.utc) + timedelta(minutes=10),
        },
        settings.JWT_SECRET_KEY,
        algorithm="HS256",
    )


def test_relatorio_exporta_csv_excel_e_pdf(monkeypatch):
    dados = {
        "total": 1,
        "items": [{"automation_name": "=SUM(1,1)", "status": "completed"}],
    }
    monkeypatch.setattr(
        ExportarRelatorioService,
        "_obter_dados",
        staticmethod(lambda user_id, tipo, filtros: dados),
    )

    csv_data, csv_type, csv_name = ExportarRelatorioService.executar(
        "user", "automacoes", "csv"
    )
    xlsx_data, xlsx_type, xlsx_name = ExportarRelatorioService.executar(
        "user", "automacoes", "xlsx"
    )
    pdf_data, pdf_type, pdf_name = ExportarRelatorioService.executar(
        "user", "automacoes", "pdf"
    )

    assert csv_data.startswith(b"\xef\xbb\xbf")
    assert b"'=SUM(1,1)" in csv_data
    assert csv_type.startswith("text/csv")
    assert csv_name == "relatorio-automacoes.csv"
    workbook = load_workbook(BytesIO(xlsx_data), read_only=True)
    assert workbook.active["A2"].value == "'=SUM(1,1)"
    assert xlsx_type.endswith("sheet")
    assert xlsx_name == "relatorio-automacoes.xlsx"
    assert pdf_data.startswith(b"%PDF")
    assert pdf_type == "application/pdf"
    assert pdf_name == "relatorio-automacoes.pdf"


def test_relatorio_automacoes_exporta_todas_as_paginas(monkeypatch):
    chamadas = []

    def listar(user_id, **kwargs):
        chamadas.append(kwargs["deslocamento"])
        inicio = kwargs["deslocamento"]
        return {
            "total": 201,
            "items": [{"id": f"run-{i}"} for i in range(inicio, min(inicio + 100, 201))],
        }

    monkeypatch.setattr(
        "services.relatorio.exportar_relatorio_service.GerarRelatorioAutomacoesService.executar",
        listar,
    )
    dados = ExportarRelatorioService._obter_dados("user", "automacoes", {})
    assert chamadas == [0, 100, 200]
    assert len(dados["items"]) == 201


def test_relatorio_rejeita_formato_nao_suportado():
    with pytest.raises(ExportacaoRelatorioError):
        ExportarRelatorioService.executar("user", "chat", "doc")


def test_exportar_relatorio_exige_autenticacao(client):
    resposta = client.get("/api/v1/relatorios/export?tipo=chat&format=csv")
    assert resposta.status_code == 401


def test_checkout_cria_sessao_stripe(monkeypatch):
    profile = Profile()
    profile.salvar()
    monkeypatch.setattr(settings, "STRIPE_SECRET_KEY", "sk_test")
    monkeypatch.setattr(settings, "PRO_PLAN_ID", "price_pro")
    monkeypatch.setattr(
        stripe.Customer,
        "create",
        lambda **kwargs: SimpleNamespace(id="cus_test"),
    )
    checkout_args = {}

    def create_session(**kwargs):
        checkout_args.update(kwargs)
        return SimpleNamespace(url="https://checkout.stripe.test/session")

    monkeypatch.setattr(stripe.checkout.Session, "create", create_session)

    url = BillingService.criar_checkout(profile.id, "test@example.com", "pro")

    assert url == "https://checkout.stripe.test/session"
    assert checkout_args["mode"] == "subscription"
    assert checkout_args["line_items"] == [{"price": "price_pro", "quantity": 1}]
    assert checkout_args["metadata"]["profile_id"] == profile.id
    assert profile.stripe_customer_id == "cus_test"


def test_webhook_stripe_atualiza_plano_e_cota(monkeypatch):
    profile = Profile()
    profile.quota_used = 200
    profile.salvar()
    monkeypatch.setattr(settings, "STRIPE_WEBHOOK_SECRET", "whsec_test")
    monkeypatch.setattr(settings, "PRO_PLAN_ID", "price_pro")
    evento = {
        "type": "customer.subscription.updated",
        "data": {
            "object": {
                "metadata": {"profile_id": profile.id, "plan_tier": "pro"},
                "customer": "cus_test",
                "id": "sub_test",
                "status": "active",
                "current_period_end": 1_800_000_000,
                "items": {"data": [{"price": {"id": "price_pro"}}]},
            }
        },
    }
    monkeypatch.setattr(
        stripe.Webhook,
        "construct_event",
        lambda payload, signature, secret: evento,
    )

    BillingService.processar_webhook(b"{}", "signature")

    assert profile.subscription_tier == "pro"
    assert profile.monthly_quota_limit == 7500
    assert profile.quota_used == 200
    assert profile.subscription_status == "active"
    assert profile.stripe_subscription_id == "sub_test"


def test_profile_nao_expoe_identificadores_stripe():
    profile = Profile(
        stripe_customer_id="cus_private",
        stripe_subscription_id="sub_private",
    )
    data = profile.to_dict()
    assert "stripe_customer_id" not in data
    assert "stripe_subscription_id" not in data
    assert data["has_billing_account"] is True
    assert data["has_billing_subscription"] is True


def test_profile_nao_permite_alterar_plano_pelo_endpoint_crud():
    profile = Profile()
    profile.salvar()
    with pytest.raises(ValueError, match="sistema de cobrança"):
        AtualizarProfileService.executar(
            profile.id,
            {"subscription_tier": "max", "monthly_quota_limit": 25000},
        )
    assert profile.subscription_tier == "basic"


def test_validacao_de_upload_rejeita_extensao_nao_permitida():
    with pytest.raises(AttachmentError, match="Tipo de arquivo não permitido"):
        AttachmentService.upload("user", "payload.exe", "application/octet-stream", b"MZ")


def test_validacao_docx_exige_documento_word():
    buffer = BytesIO()
    with zipfile.ZipFile(buffer, "w") as arquivo:
        arquivo.writestr("not-a-document.txt", "conteúdo")
    with pytest.raises(AttachmentError, match="não contém um documento DOCX"):
        AttachmentService._validar_docx(buffer.getvalue())


def test_upload_armazena_metadados_e_url_assinada(monkeypatch):
    profile = Profile()
    profile.salvar()
    monkeypatch.setattr(AttachmentService, "_upload_storage", staticmethod(lambda *args: None))
    monkeypatch.setattr(
        AttachmentService,
        "_url_assinada",
        staticmethod(lambda path: f"https://storage.test/{path}"),
    )

    resultado = AttachmentService.upload(
        profile.id,
        "foto.png",
        "image/png",
        b"\x89PNG\r\n\x1a\nconteudo",
    )

    registro = Attachment.query.filter_by(id=resultado["id"]).one()
    assert registro.user_id == profile.id
    assert registro.content_type == "image/png"
    assert resultado["url"].endswith(registro.storage_path)


def test_upload_respeita_limite_de_arquivos_do_plano(monkeypatch):
    profile = Profile(subscription_tier="basic")
    profile.salvar()
    for indice in range(5):
        Attachment(
            user_id=profile.id,
            original_name=f"arquivo-{indice}.png",
            storage_path=f"{profile.id}/{indice}.png",
            content_type="image/png",
            size_bytes=8,
        ).salvar()

    with pytest.raises(AttachmentError, match="limite de arquivos"):
        AttachmentService.upload(
            profile.id,
            "novo.png",
            "image/png",
            b"\x89PNG\r\n\x1a\nconteudo",
        )


def test_upload_exige_autenticacao(client):
    resposta = client.get("/api/v1/attachments")
    assert resposta.status_code == 401
