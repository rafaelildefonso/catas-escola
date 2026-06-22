# Worker — Motor de Execução (MVP sem Temporal)

Este diretório contém o motor de execução de automações do CATAS. As automações são executadas localmente em Python puro usando o `AutomationRunner`, sem dependência do Temporal.io.

---

## Arquitetura

O sistema opera em dois momentos distintos:

### A. Build-Time (Momento de Criação)
- **Ator:** Agente Arquiteto (via pipeline de IA)
- **Saída:** JSON estático, validado pelo Pydantic — **O Plano (AutomationPlan)**
- **Catálogo de Módulos:** Lido pelo Agente via `module_registry.py`

### B. Run-Time (Momento de Execução)
- **Ator:** `AutomationRunner` (Python puro, execução in-process ou standalone)
- **Módulos:** Funções Python registradas via `@register_module(module_id)`
- **Data Flow:** `VariableResolver` injeta dados entre steps usando sintaxe `{{step_id.campo}}` (Jinja2)

---

## Estrutura Atual

```
worker/
├── main.py          # Entry point standalone (debug/teste local)
├── runner.py        # AutomationRunner — executa planos passo a passo
├── test_runner.py   # Testes do runner
├── modules/         # Módulos registrados (http, ai, flow, gmail, sheets, calendar)
│   ├── registry.py  # Catálogo de módulos (decorator @register_module)
│   ├── http_modules.py
│   ├── ai_modules.py
│   ├── flow_modules.py
│   ├── gmail_modules.py
│   ├── google_sheets_modules.py
│   └── google_calendar_modules.py
└── utils/           # Utilitários
    ├── resolver.py      # VariableResolver (Jinja2)
    ├── decorators.py    # async_retry
    └── google_auth.py   # OAuth Google
```

## Como Executar (Standalone)

```bash
cd server/worker
python main.py plan.json
```

Sem argumentos, executa um plano de exemplo.

---

## Como Adicionar um Novo Módulo

1. Crie o arquivo em `modules/<categoria>_modules.py`
2. Decore a função com `@register_module("<id>")`
3. Importe o módulo em `modules/__init__.py`

```python
from .registry import register_module

@register_module("exemplo.meu_modulo")
async def meu_modulo(params: dict) -> dict:
    # params já resolvido pelo VariableResolver
    return {"status": "ok", "resultado": ...}
```

## Dependências Principais

| Biblioteca | Função |
|---|---|
| httpx | Chamadas REST para integrações |
| jinja2 | Variable Resolver |
| python-dotenv | Carregar variáveis de ambiente |
