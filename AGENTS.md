# CATAS — Architecture Guide

## Architecture (`backend/`)

```
backend/
├── extensions.py          # db = SQLAlchemy()
├── application.py         # create_app(), init_firebase(), error handlers
├── routes.py              # Centralized route registration (112 routes)
├── models/*.py            # 18 SQLAlchemy models with CRUD methods
├── controllers/*.py       # 18 CRUD controllers + Chat/Chatbot/Feedback/Relatorio
├── services/*/            # Business logic (one service per use case)
│   └── criar_*_service.py # Create operations
├── repositories/          # Complex queries (reports, procedures PostgreSQL)
├── core/                  # Config, security, OAuth
├── worker/                # FastAPI worker (automations)
└── tests/                 # 112 tests
```

## Layer Rules

| Layer | Responsibility | CRUD? |
|-------|---------------|-------|
| **Model** | Data schema + `salvar()`, `atualizar()`, `deletar()`, `listar_todos()`, `buscar_por_id()`, `to_dict()` | Yes |
| **Service** | Business logic, validation, filtering | Yes |
| **Controller** | HTTP request/response handling | No direct DB |
| **Repository** | Complex queries, PostgreSQL procedures, filters | Read-only |
| **Route** | URL → endpoint mapping | No logic |

## CRUD Flow

```
HTTP POST /api/v1/profiles
  → routes.py → ProfileController.criar()
    → CriarProfileService.executar(dados)
      → Profile(**dados) → profile.salvar()
    → return jsonify(model.to_dict()), 201
```

## Adding a New Entity

1. Create `models/seu_modelo.py` with `salvar/atualizar/deletar/listar_todos/buscar_por_id/to_dict`
2. Create `controllers/seu_modelo_controller.py` with CRUD methods
3. Create `services/seu_modelo/criar_seu_modelo_service.py`
4. Register routes in `routes.py`
5. Add to `models/__init__.py`

## Test Commands

```bash
cd backend
python -m pytest tests/ -v
python -m pytest tests/test_all_entities.py -v
python -m pytest tests/test_auth_user.py -v
```

## Run

```bash
cd backend
python run.py
```
