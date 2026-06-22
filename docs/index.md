# CATAS Documentation

> 🤖 **CATAS** = Context Aware Task Automation System
>
> Um agente de automação inteligente baseado em linguagem natural.

---

## 🚀 Quero Começar Agora

**Setup completo em 15 minutos:**

```bash
# 1. Temporal Server
cd server/docker/temporal && docker-compose up -d

# 2. Backend API
cd server && venv\Scripts\activate && uvicorn app.main:app --reload

# 3. Worker (novo terminal)
cd server && venv\Scripts\activate && $env:PYTHONPATH="." && python worker/main.py

# 4. Flutter
cd app_flutter && flutter run
```

📖 **[Quick Start Completo →](./comecando/quickstart.md)**

---

## 🗺️ Navegue por Perfil

### 👨‍💻 Frontend Developer
Trabalhando com Flutter e UI?  
**[Comece aqui →](./flutter/index.md)**

**Tópicos:** Providers, Componentes, Telas, State Management

---

### 🐍 Backend Developer
Trabalhando com Python, FastAPI ou automações?  
**[Comece aqui →](./backend/index.md)**

**Tópicos:** Pipeline de IA, Temporal Workflows, API REST

---

### 🔧 DevOps / Infra
Configurando deploy, banco ou integrações?  
**[Comece aqui →](./infra/index.md)**

**Tópicos:** Temporal, Supabase, Firebase, Stripe

---

## 📚 Guias por Tarefa

| Eu quero... | Ir para |
|-------------|---------|
| 🆕 Rodar o projeto pela primeira vez | [Quick Start](./comecando/quickstart.md) |
| 🔌 Adicionar nova integração (Google, Slack, etc) | [Guia: Nova Integração](./guias/nova-integracao/index.md) |
| 🐛 Debugar um bug em produção | [Guia: Debugging](./guias/debugging/index.md) |
| ➕ Adicionar novo provider Flutter | [Flutter: Providers](./flutter/providers.md) |
| ⚡ Modificar workflow Temporal | [Backend: Workflows](./backend/worker/workflows.md) |
| 🧪 Escrever testes | [Flutter Testing](./flutter/testing.md) ou [Backend Testing](./backend/testing.md) |
| 📊 Entender o fluxo de créditos | [Backend: Créditos](./backend/api/credits.md) |

---

## 📖 Referência Rápida

- [API Endpoints](./ref/api-endpoints.md) - Todos os endpoints REST
- [Database Schema](./ref/database-schema.md) - Tabelas e relações
- [Variáveis de Ambiente](./comecando/variaveis-ambiente.md) - Lista completa de envs
- [Componentes UI](./ref/component-library.md) - Biblioteca de widgets
- [Temporal Activities](./ref/temporal-activities.md) - Lista de atividades

---

## 🔗 Links Úteis

| Recurso | URL |
|---------|-----|
| 🏠 Repositório | `c:\Users\faely\PROJETOS\saas\CATAS\CATAS - Escola` |
| ⏱️ Temporal UI | http://localhost:8080 |
| 📚 API Docs | http://localhost:8000/docs |
| 💬 Swagger | http://localhost:8000/redoc |

---

## 🆘 Precisa de Ajuda?

1. **Erro no setup?** → [Troubleshooting](./comecando/troubleshooting.md)
2. **Dúvida sobre código?** → Navegue pelo seu perfil acima
3. **Problema específico?** → [Guia: Debugging](./guias/debugging/index.md)

---

> 💡 **Dica:** Esta documentação está organizada para você encontrar o que precisa em **menos de 3 cliques**.
