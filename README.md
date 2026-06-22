# CATAS (Centralized Agent Task Automation System)

Agente de Automação Inteligente baseado em Linguagem Natural que **executa ações** no mundo real através de uma interface de chat multiplataforma.

## Arquitetura

- **Client (Flutter):** Interface multiplataforma (Mobile/Desktop)
- **Core API (FastAPI):** Processa linguagem natural com Gemini/Claude
- **Executor (Temporal.io):** Workflows duráveis para integrações com Google APIs

## Tech Stack

| Camada | Tecnologia |
|--------|-----------|
| Frontend | Flutter (Dart) - Android, iOS, Web, Desktop |
| Backend | Python 3.11+, FastAPI |
| AI | Google Gemini 2.5 Flash, Anthropic Claude 3.5 Sonnet |
| Database | Supabase (PostgreSQL) |
| Workflows | Temporal.io |
| Auth | Supabase Auth |

---

## Quick Start

### Pré-requisitos
- Docker e Docker Compose
- Conta Supabase + credenciais Google API (Gemini/Claude)

### 1. Configurar .env
```bash
cd server
cp .env.example .env

cd app_flutter
cp .env.example .env
# Edite com suas credenciais
```

### 2. Subir Temporal
```bash
cd server/docker/temporal
docker-compose up -d
# Aguarde 30-60s
```
UI: http://localhost:8080

### 3. Subir Server + Worker
```bash
docker-compose -f server/docker-compose.yml up -d --build
```
API: http://localhost:8000 | Docs: http://localhost:8000/docs

### Parar tudo
```bash
docker-compose -f server/docker-compose.yml down
cd server/docker/temporal && docker-compose down
```

---

## Rodando localmente (sem Docker)

```bash
cd server
python -m venv venv
venv\Scripts\activate  # Windows
pip install -r requirements.txt
uvicorn app.main:app --reload
```

### Rodando o Flutter App
```bash
cd app_flutter
flutter pub get
flutter run -d chrome --web-port 52159
```

## Estrutura

```
/server          # FastAPI + Temporal Worker (Python)
/app_flutter     # App Flutter (Dart)
/docs            # Documentação Mintlify
```

Documentação completa em `docs/`. Rode com: `mintlify dev`

## Testar

1. Com backend, worker e Temporal rodando, abra o app Flutter
2. No chat: *"Agendar reunião amanhã às 10h"*
3. O sistema interpreta, cria o plano e executa via Temporal
4. Resultado aparece no chat com confirmação

**Ver execuções:** http://localhost:8080 (Temporal UI)