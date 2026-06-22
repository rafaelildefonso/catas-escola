# Como Rodar o CATAS

## Pré-requisitos

- **Python 3.10+**
- **Flutter SDK**
- **Git**
- **Conta Supabase** e **Google Cloud** (para auth)

## 1. Configurar Variáveis de Ambiente

Crie os arquivos `.env` conforme [variáveis de ambiente](variaveis-ambiente.md):

- `server/.env` — Supabase, Gemini, n8n, Stripe.
- `app_flutter/.env` — Supabase, API_BASE_URL, Client IDs do Google.

## 2. Banco de Dados

Execute a migration em `server/migrations/002_create_chat_schema.sql` no Supabase Dashboard (SQL Editor). Ver [banco de dados](../arquitetura/banco-dados.md).

## 3. Iniciar o Backend

O backend precisa estar rodando para o app funcionar.

```powershell
cd server
python -m venv .venv
.\.venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

Servidor em `http://127.0.0.1:8000`. Swagger: `http://127.0.0.1:8000/docs`.

## 4. (Opcional) Mock n8n

Para testes sem n8n real:

```powershell
python server/mock_n8n.py
```

Configure no `server/.env`:
```env
N8N_WEBHOOK_URL=http://localhost:5678/webhook
N8N_WEBHOOK_SECRET=dev-secret-123
```

## 5. Iniciar o App Flutter

```powershell
cd app_flutter
flutter pub get
flutter run -d windows   # ou chrome, android
```

## Troubleshooting

- **Erro de conexão**: Verifique se o backend está rodando. No Android Emulator, use `API_BASE_URL=http://10.0.2.2:8000/api/v1`.
- **CORS**: O backend permite todas as origens (`*`) em desenvolvimento.
- **Auth**: Para testes rápidos, use `Authorization: Bearer dev-token` (bypass no backend).
