# CATAS — Architecture Guide

## New Architecture (`backend/app/`)

```
app/
├── extensions.py          # db = SQLAlchemy()
├── __init__.py             # create_app(), init_firebase(), error handlers
├── routes.py               # Centralized route registration (90 CRUD routes)
├── models/*.py             # 18 SQLAlchemy models with CRUD methods
├── controllers/*.py        # 18 generic CRUD controllers
└── services/*/             # Business logic services
    └── criar_*_service.py  # One service per create operation
```

## Layer Rules

| Layer | Responsibility | CRUD? |
|-------|---------------|-------|
| **Model** | Data schema + `salvar()`, `atualizar()`, `deletar()`, `listar_todos()`, `buscar_por_id()`, `to_dict()` | ✅ Yes |
| **Service** | Business logic, validation, filtering | ✅ Create |
| **Controller** | HTTP request/response handling | ❌ No direct DB |
| **Route** | URL → endpoint mapping | ❌ No logic |

## CRUD Flow

```
HTTP POST /api/v1/profiles
  → routes.py → ProfileController.criar()
    → CriarProfileService.executar(dados)
      → Profile(**dados) → profile.salvar()
    → return jsonify(model.to_dict()), 201
```

## Adding a New Entity

1. Create `app/models/seu_modelo.py` with `salvar/atualizar/deletar/listar_todos/buscar_por_id/to_dict`
2. Create `app/controllers/seu_modelo_controller.py` with CRUD methods
3. Create `app/services/seu_modelo/criar_seu_modelo_service.py`
4. Register routes in `app/routes.py`
5. Add to `app/models/__init__.py`

## Test Commands

```bash
cd backend
python -m pytest tests/test_new_architecture.py -v
python -m pytest tests/test_all_entities.py -v
python -m pytest tests/test_auth_user.py -v
```

## Run

```bash
cd backend
python run.py
```

## Backward Compatibility

Old imports (`from models import Profile`) redirect to `app.models` via `models/__init__.py`.
Old blueprints, repositories, and services continue to work unchanged.
