# CATAS (Centralized Agent Task Automation System)

## Equipe

- Rafael Ildefonso Furtado
- Lucas Salman Resende
- Henrique Santos Tavares
- Miguel Teixeira Valadao
- Lucas Nunes Araujo

Agente de Automação Inteligente baseado em Linguagem Natural que **executa ações** no mundo real através de uma interface de chat multiplataforma.

## Arquitetura

- **Client (Flutter):** Interface multiplataforma (Mobile/Desktop)
- **Core API (Flask):** Processa linguagem natural com IA multi-agente
- **Executor (Temporal.io):** Workflows duráveis para integrações com Google APIs

## Tech Stack

| Camada | Tecnologia |
|--------|-----------|
| Frontend | Flutter (Dart) - Android, iOS, Web, Desktop |
| Backend | Python 3.11+, Flask + SQLAlchemy |
| AI | Groq, OpenAI, Google Gemini |
| Database | Supabase (PostgreSQL) ou SQLite (dev) |
| Workflows | Temporal.io |
| Auth | Supabase Auth + Firebase |

---

## Quick Start (Recomendado)

### Pré-requisitos
- Python 3.11+
- Conta Supabase + credenciais de API

### 1. Configurar .env

```bash
cd backend
cp .env.example .env
# Edite com suas credenciais (ou deixe DATABASE_URL vazio para SQLite local)
```

### 2. Rodar a API

```bash
cd backend
python -m venv venv
.\venv\Scripts\activate
pip install -r requirements.txt
python run.py
```

API: http://localhost:8000 | Health: http://localhost:8000/health

### 3. Rodar o Worker (opcional, para automações)

```bash
cd backend
.\venv\Scripts\activate
python -m worker.server
```

### Usando o Script de Atalho

```powershell
.\run_catas.ps1          # Só API
.\run_catas.ps1 -Mode worker   # Só Worker
.\run_catas.ps1 -Mode all      # API + Worker
```

---

## Rodando o Flutter App

```bash
cd frontend
flutter pub get
flutter run -d chrome --web-port 52159
```

## Estrutura

```
backend/
├── app/              # Flask API (controllers, models, services, routes)
├── core/             # Config, settings, error handling
├── worker/           # Temporal Worker
├── migrations/       # Alembic migrations
├── run.py            # Entrypoint da API
run_catas.ps1         # Script de atalho para startup
frontend/             # App Flutter (Dart)
docs/                 # Documentação Mintlify
```

Documentação completa em `docs/`.

## Testar

1. Com a API rodando, visite http://localhost:8000/health
2. Use o Swagger em `/` para explorar os endpoints
3. Para testes automatizados:

```bash
cd backend
.\venv\Scripts\activate
python -m pytest tests/ -v
```