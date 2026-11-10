from services.integration.google_auth_service import montar_url_retorno_integracoes


def test_retorno_oauth_usa_rota_de_integracoes_do_flutter(monkeypatch):
    monkeypatch.setenv("FRONTEND_URL", "http://localhost:52159/")

    url = montar_url_retorno_integracoes(connected="google_gmail")

    assert url == "http://localhost:52159/app/integrations"


def test_retorno_oauth_preserva_parametro_de_erro(monkeypatch):
    monkeypatch.setenv("FRONTEND_URL", "https://catas-ai.vercel.app")

    url = montar_url_retorno_integracoes(error="callback_failed")

    assert url == "https://catas-ai.vercel.app/app/integrations"
