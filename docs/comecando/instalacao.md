# Como Rodar o CATAS

## Pre-requisitos

- **Python 3.11+**
- **Flutter SDK 3.10.8+**
- **Git**
- **Conta Supabase** e **Google Cloud** (para auth)
- **Docker** (opcional, para containerizacao)

---

## 1. Configurar Variaveis de Ambiente

Crie os arquivos `.env` conforme [variaveis de ambiente](variaveis-ambiente.md):

- `backend/.env` -- Supabase, Database, Groq, Stripe, Firebase.
- `frontend/.env` -- Supabase, API_BASE_URL, Client IDs do Google.

---

## 2. Banco de Dados

As migrations em `backend/migrations/*.sql` sao executadas automaticamente
pelo SQLAlchemy (ou manualmente no Supabase SQL Editor).

---

## 3. Iniciar o Backend

O backend precisa estar rodando para o app funcionar.

```powershell
cd backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
python run.py
```

Servidor em `http://127.0.0.1:8000`.

---

## 4. Iniciar o Worker (novo terminal)

O Worker e necessario para executar automacoes.

```powershell
cd backend
venv\Scripts\activate
python -m worker.server
```

Worker em `http://127.0.0.1:8001`.

---

## 5. Iniciar o App Flutter

```powershell
cd frontend
flutter pub get
flutter run -d windows   # ou chrome, android
```

---

## 6. Usando Docker (Alternativa)

Para rodar backend + worker com Docker:

```powershell
cd backend
docker-compose up -d
```

Servicos:
- `catas_server`: API Flask (port 8000)
- `catas_worker`: FastAPI Worker (port 8001)

---

## Troubleshooting

- **Erro de conexao**: Verifique se o backend esta rodando. No Android Emulator, use `API_BASE_URL=http://10.0.2.2:8000/api/v1`.
- **CORS**: O backend permite todas as origens (`*`) em desenvolvimento.
- **Auth**: Para testes rapidos, use `Authorization: Bearer dev-token` (bypass no backend).
- **Worker nao conecta**: Verifique se `WORKER_URL` esta configurado corretamente.
- **Erro de portas**: Verifique se as portas 8000 e 8001 nao estao em uso.

---

## Proximos Passos

- [Variaveis de Ambiente](variaveis-ambiente.md) - Configuracao completa
- [Pipeline de IA](../backend/ia-pipeline.md) - Como funciona o pipeline
- [Guia de Integracoes](../guias/nova-integracao/index.md) - Adicionar novas integracoes
