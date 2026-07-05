# CATAS Backend API

Backend Flask do CATAS - Sistema de Automação de Tarefas com IA usando Temporal.io.

## 🚀 Funcionalidades

- ✅ API REST com Flask
- ✅ Arquitetura CRUD genérica (Model → Service → Controller → Route)
- ✅ 17 entidades com CRUD completo
- ✅ Autenticação via Supabase Auth (Bearer Token)
- ✅ Pipeline de IA multi-agente (Intent → Entities → Action)
- ✅ Orquestração de automações com Temporal.io
- ✅ Integrações: Google Calendar, Gmail, Google Sheets
- ✅ Sistema de créditos por uso de tokens
- ✅ Notificações push via Firebase
- ✅ Webhooks para Stripe (assinaturas)

## 📋 Pré-requisitos

- Python 3.11+
- Arquivo `.env` configurado (veja `.env.example`)
- (Opcional) Conta Supabase para PostgreSQL

## 🔧 Instalação

```bash
# 1. Clone e entre no diretório
cd backend

# 2. Configure o .env
cp .env.example .env
# Edite com suas credenciais (DATABASE_URL vazio = SQLite local)

# 3. Ambiente virtual
python -m venv venv
.\venv\Scripts\activate  # Windows
# source .venv/bin/activate  # Linux/Mac

# 4. Instalar dependências
pip install -r requirements.txt
```

## 🏃 Executar

### API (modo local)

```bash
cd backend
.\venv\Scripts\activate
python run.py
```

A API estará em http://localhost:8000 | Health: http://localhost:8000/health

### Worker (automações Temporal)

```bash
cd backend
.\venv\Scripts\activate
$env:PYTHONPATH = "."
python -m worker.server
```

### Script de atalho

```powershell
# Da raiz do projeto
.\run_catas.ps1          # Só API
.\run_catas.ps1 -Mode all      # API + Worker
```

## ⚙️ Configuração

Copie `.env.example` para `.env` e preencha as variáveis. As principais:

| Variável | Descrição |
|----------|-----------|
| `DATABASE_URL` | PostgreSQL. Deixe vazio para SQLite local |
| `SUPABASE_URL` | URL do projeto Supabase |
| `SUPABASE_SERVICE_ROLE_KEY` | Chave de serviço Supabase |
| `OPENAI_API_KEY` | API Key OpenAI |
| `GROQ_API_KEY` | API Key Groq (modelos gratuitos) |
| `ENCRYPTION_KEY` | Chave para criptografia interna |

## 🧪 Testar

```bash
cd backend
.\venv\Scripts\activate
python -m pytest tests/ -v
```

## 🏗️ Arquitetura

### CRUD Flow

```
HTTP POST /api/v1/profiles
  → routes.py → ProfileController.criar()
    → CriarProfileService.executar(dados)
      → Profile(**dados) → profile.salvar()
    → return jsonify(model.to_dict()), 201
```

### Pipeline de IA

```
User Message → Intent Classifier → Entity Extractor → Payload Builder → AI Response
```

### Execução Temporal

```
API Flask → Temporal Client → Temporal Server → Worker → Activities
```

## 📂 Estrutura

```
backend/
├── app/
│   ├── __init__.py         # create_app(), init_firebase()
│   ├── extensions.py       # db = SQLAlchemy()
│   ├── routes.py           # 85 rotas CRUD centralizadas
│   ├── models/             # 17 modelos SQLAlchemy
│   ├── controllers/        # 17 controllers CRUD
│   └── services/           # Lógica de negócio
├── core/
│   ├── config.py           # Settings via Pydantic
│   └── errors.py           # Error handling
├── worker/                 # Temporal Worker
├── tests/                  # Testes
├── migrations/             # Alembic
├── run.py                  # Entrypoint
└── requirements.txt
```

## 🔗 Links

- [Frontend](../frontend/README.md)
- [Documentação Geral](../docs/README.md)
