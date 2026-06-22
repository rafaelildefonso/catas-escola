# Documentação CATAS

> 🤖 **CATAS** = Context Aware Task Automation System  
> Agente de automação inteligente baseado em linguagem natural

---

## 🚀 Comece Aqui

**Primeira vez?** → [Quick Start em 15 minutos](comecando/quickstart.md)

```bash
# Setup rápido
cd server/docker/temporal && docker-compose up -d
cd server && uvicorn app.main:app --reload
cd server && python worker/main.py
cd app_flutter && flutter run
```

---

## 🗺️ Navegue por Perfil

Escolha seu caminho:

### 👨‍💻 [Frontend Developer](flutter/index.md)
Trabalhando com Flutter e UI?

**Tópicos:** Providers, Componentes, Telas, Realtime

### 🐍 [Backend Developer](backend/index.md)
Trabalhando com Python, FastAPI ou automações?

**Tópicos:** Pipeline de IA, Temporal Workflows, API REST

### 🔧 [DevOps / Infra](infra/index.md)
Configurando deploy, banco ou integrações?

**Tópicos:** Temporal, Supabase, Firebase, Stripe

---

## 📚 Guias Práticos

| Eu quero... | Guia |
|-------------|------|
| 🆕 Rodar o projeto pela primeira vez | [Quick Start](comecando/quickstart.md) |
| 🔌 Adicionar nova integração (Slack, Notion, etc) | [Nova Integração](guias/nova-integracao/index.md) |
| 🐛 Debugar um bug | [Debugging](guias/debugging/index.md) |
| ⚙️ Configurar variáveis de ambiente | [Variáveis de Ambiente](comecando/variaveis-ambiente.md) |
| 🆘 Resolver erro comum | [Troubleshooting](comecando/troubleshooting.md) |

---

## 📖 Documentação Técnica

### Arquitetura
- [Visão Geral](arquitetura/visao-geral.md) - Fluxo do sistema
- [Sistema](arquitetura/sistema.md) - Componentes técnicos
- [Backend](arquitetura/backend.md) - Estrutura Python
- [App Flutter](arquitetura/app-flutter.md) - Estrutura Dart
- [Banco de Dados](arquitetura/banco-dados.md) - Schema e RLS

### Referência
- [API](referencia/api.md) - Endpoints REST
- [Integrações](referencia/integracoes.md) - Google, Stripe, etc
- [Componentes UI](referencia/componentes-ui.md) - Biblioteca de widgets
- [Faturamento](referencia/faturamento.md) - Stripe e planos

---

## 🔗 Links Úteis

| Recurso | Link |
|---------|------|
| ⏱️ Temporal UI | http://localhost:8080 |
| 📚 API Docs | http://localhost:8000/docs |
| 💬 Swagger | http://localhost:8000/redoc |

---

## 📝 Sobre esta Documentação

Organização:
- **Começando** - Setup rápido e troubleshooting
- **Por Perfil** - Guias específicos (Flutter, Backend, Infra)
- **Guias** - Tarefas comuns passo a passo
- **Arquitetura** - Documentação técnica detalhada
- **Referência** - APIs, componentes, integrações

> 💡 **Dica:** Use a busca (Ctrl+K) para encontrar qualquer tópico em segundos.

---

*CATAS - Context Aware Task Automation System*
