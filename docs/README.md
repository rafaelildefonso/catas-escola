# Documentacao CATAS

> **CATAS** = Context Aware Task Automation System  
> Agente de automacao inteligente baseado em linguagem natural

---

## Comece Aqui

**Primeira vez?** → [Quick Start em 15 minutos](comecando/quickstart.md)

```bash
# Setup rapido
cd backend && .\.venv\Scripts\activate && flask run --port 8000
cd backend && .\.venv\Scripts\activate && python -m worker.server
cd app_flutter && flutter run
```

---

## Navegue por Perfil

Escolha seu caminho:

### [Frontend Developer](flutter/index.md)
Trabalhando com Flutter e UI?

**Topicos:** Providers, Componentes, Telas, Realtime

### [Backend Developer](backend/index.md)
Trabalhando com Python, Flask ou automacoes?

**Topicos:** Pipeline de IA, Automacao, API REST

### [DevOps / Infra](infra/index.md)
Configurando deploy, banco ou integracoes?

**Topicos:** Supabase, Firebase, Stripe, Docker

---

## Guias Praticos

| Eu quero... | Guia |
|-------------|------|
| Rodar o projeto pela primeira vez | [Quick Start](comecando/quickstart.md) |
| Adicionar nova integracao (Slack, Notion, etc) | [Nova Integracao](guias/nova-integracao/index.md) |
| Depurar um bug | [Debugging](guias/debugging/index.md) |
| Configurar variaveis de ambiente | [Variaveis de Ambiente](comecando/variaveis-ambiente.md) |
| Resolver erro comum | [Troubleshooting](comecando/troubleshooting.md) |

---

## Documentacao Tecnica

### Arquitetura
- [Sistema](arquitetura/sistema.md) - Componentes tecnicos
- [Backend](arquitetura/backend.md) - Estrutura Python
- [App Flutter](arquitetura/app-flutter.md) - Estrutura Dart
- [Banco de Dados](arquitetura/banco-dados.md) - Schema e RLS

### Referencia
- [API](referencia/api.md) - Endpoints REST
- [Integracoes](referencia/integracoes.md) - Google, Stripe, etc
- [Componentes UI](referencia/componentes-ui.md) - Biblioteca de widgets
- [Faturamento](referencia/faturamento.md) - Stripe e planos

---

## Links Uteis

| Recurso | Link |
|---------|------|
| API Docs | http://localhost:8000/docs |

---

## Sobre esta Documentacao

Organizacao:
- **Comecando** - Setup rapido e troubleshooting
- **Por Perfil** - Guias especificos (Flutter, Backend, Infra)
- **Guias** - Tarefas comuns passo a passo
- **Arquitetura** - Documentacao tecnica detalhada
- **Referencia** - APIs, componentes, integracoes

> **Dica:** Use a busca (Ctrl+K) para encontrar qualquer topico em segundos.

---

*CATAS - Context Aware Task Automation System*
