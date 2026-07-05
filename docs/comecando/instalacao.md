# Como Rodar o CATAS

## Pre-requisitos

- **Python 3.10+**
- **Flutter SDK**
- **Git**
- **Conta Supabase** e **Google Cloud** (para auth)

---

## 1. Configurar Variaveis de Ambiente

Crie os arquivos `.env` conforme [variaveis de ambiente](variaveis-ambiente.md):

- `backend/.env` -- Supabase, Database, Groq, Stripe.
- `app_flutter/.env` -- Supabase, API_BASE_URL, Client IDs do Google.

---

## 2. Banco de Dados

As migrations em `backend/migrations/*.sql` sao executadas automaticamente
pelo SQLAlchemy (ou manualmente no Supabase SQL Editor).

---

## 3. Iniciar o Backend

O backend precisa estar rodando para o app funcionar.

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\activate
pip install -r requirements.txt
flask run --port 8000 --debug
```

Servidor em `http://127.0.0.1:8000`.

---

## 4. Iniciar o Worker (novo terminal)

```powershell
cd backend
.\.venv\Scripts\activate
python -m worker.server
```

Worker em `http://127.0.0.1:8001`.

---

## 5. Iniciar o App Flutter

```powershell
cd app_flutter
flutter pub get
flutter run -d windows   # ou chrome, android
```

---

## Troubleshooting

- **Erro de conexao**: Verifique se o backend esta rodando. No Android Emulator, use `API_BASE_URL=http://10.0.2.2:8000/api/v1`.
- **CORS**: O backend permite todas as origens (`*`) em desenvolvimento.
- **Auth**: Para testes rapidos, use `Authorization: Bearer dev-token` (bypass no backend).
