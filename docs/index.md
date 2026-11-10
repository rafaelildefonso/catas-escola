# CATAS Documentation

> **CATAS** = Context Aware Task Automation System
>
> Um agente de automação inteligente baseado em linguagem natural.

---

## Quero Comecar Agora

**Setup completo em 15 minutos:**

```bash
# 1. Backend API (Flask)
cd backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
python run.py

# 2. Worker (FastAPI, novo terminal)
cd backend
venv\Scripts\activate
python -m worker.server

# 3. Flutter
cd frontend
flutter pub get
flutter run
```

**[Quick Start Completo →](./comecando/quickstart.md)**

---

## Navegue por Perfil

### Frontend Developer
Trabalhando com Flutter e UI?  
**[Comece aqui →](./flutter/index.md)**

**Topicos:** Providers, Componentes, Telas, State Management

---

### Backend Developer
Trabalhando com Python, Flask ou automacoes?  
**[Comece aqui →](./backend/index.md)**

**Topicos:** Pipeline de IA, Automacao, API REST

---

### DevOps / Infra
Configurando deploy, banco ou integracoes?  
**[Comece aqui →](./infra/index.md)**

**Topicos:** Supabase, Firebase, Stripe, Docker

---

## Guias por Tarefa

| Eu quero... | Ir para |
|-------------|---------|
| Rodar o projeto pela primeira vez | [Quick Start](./comecando/quickstart.md) |
| Adicionar nova integracao (Google, Slack, etc) | [Guia: Nova Integracao](./guias/nova-integracao/index.md) |
| Depurar um bug em producao | [Guia: Debugging](./guias/debugging/index.md) |
| Adicionar novo provider Flutter | [Flutter: Providers](./flutter/providers.md) |
| Modificar pipeline de automacao | [Backend: Automacao](./backend/automation-pipeline.md) |
| Escrever testes | [Flutter Testing](./flutter/testing.md) ou [Backend Testing](./backend/testing.md) |
| Entender o fluxo de creditos | [Backend: Creditos](./backend/api/credits.md) |

---

## Referencia Rapida

- [API Endpoints](./ref/api-endpoints.md) - Todos os endpoints REST
- [Database Schema](./ref/database-schema.md) - Tabelas e relacoes
- [Variaveis de Ambiente](./comecando/variaveis-ambiente.md) - Lista completa de envs
- [Componentes UI](./ref/component-library.md) - Biblioteca de widgets

---

## Links Uteis

| Recurso | URL |
|---------|-----|
| Repositorio | https://github.com/seu-usuario/catas |
| API Docs | http://localhost:8000/docs |
| Produção | https://catas-ai.vercel.app |

---

## Precisa de Ajuda?

1. **Erro no setup?** → [Troubleshooting](./comecando/troubleshooting.md)
2. **Divida sobre codigo?** → Navegue pelo seu perfil acima
3. **Problema especifico?** → [Guia: Debugging](./guias/debugging/index.md)

---

> **Dica:** Esta documentacao esta organizada para voce encontrar o que precisa em **menos de 3 cliques**.
