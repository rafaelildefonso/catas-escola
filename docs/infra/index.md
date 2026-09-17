# Infra & DevOps Guide

> **Voce esta configurando:** Deploy, banco, integracoes  
> **Stack:** Docker, Supabase, Firebase, Stripe

---

## O que voce precisa saber

O CATAS depende de **servicos externos** que precisam ser configurados:

```
  Servicos Essenciais
  1. Supabase           Banco de dados + Auth
  2. Firebase           Push notifications + Auth
  Servicos Opcionais (para producao)
  3. Stripe             Pagamentos e planos
  4. Google Cloud       OAuth para Google apps
```

---

## Quick Setup

### Local (Desenvolvimento)

```bash
# 1. Supabase
# Criar projeto gratuito em https://supabase.com
# Anotar URL, Service Role Key e DATABASE_URL

# 2. Firebase (opcional para dev)
# Criar projeto em https://console.firebase.google.com
# Baixar serviceAccountKey.json

# Pronto! API e Worker podem rodar.
```

### Producao

```bash
# 1. Supabase Pro ou Self-hosted
# 2. Firebase (obrigatorio para push)
# 3. Stripe (obrigatorio para pagamentos)
# 4. Google OAuth (obrigatorio para integracoes)
```

---

## Guias por Servico

### 1. Supabase (Banco de Dados + Auth)

**O que e:** PostgreSQL + Auth + Realtime + Storage

**Setup:**
- [Criar projeto](./supabase/setup.md)
- [Executar migrations](./supabase/migrations.md)
- [Configurar RLS (Row Level Security)](./supabase/rls.md)

**Arquivos:**
- `backend/migrations/*.sql` - Schema
- `backend/models/*.py` - Models SQLAlchemy
- `backend/repositories/*.py` - Acesso via SQLAlchemy
- `backend/core/security.py` - Validacao de JWT

### 2. Firebase (Notificacoes + Auth)

**O que e:** Firebase Auth + FCM (Firebase Cloud Messaging) para push

**Setup:**
- [Criar projeto](./firebase/setup.md)
- [Configurar FCM](./firebase/fcm.md)
- [Integrar com Flutter](./firebase/flutter.md)

**Arquivos:**
- `frontend/lib/` - Config Firebase
- `backend/services/notification_service.py` - Backend

### 3. Stripe (Pagamentos)

**O que e:** Assinaturas e pagamentos

**Setup:**
- [Criar conta](./stripe/setup.md)
- [Configurar webhooks](./stripe/webhooks.md)
- [Planos e precos](./stripe/plans.md)

**Arquivos:**
- `backend/controllers/` - Endpoints de pagamento
- `backend/services/` - Servicos de creditos

### 4. Google OAuth (Integracoes)

**O que e:** Acesso a Google Calendar, Gmail, Sheets, Drive

**Setup:**
- [Criar projeto Cloud](./google/setup.md)
- [Configurar OAuth consent](./google/oauth.md)
- [Habilitar APIs](./google/apis.md)

**Arquivos:**
- `backend/models/integration.py` - Tokens
- `backend/worker/modules/google_calendar_modules.py` - Uso

---

## Checklists de Deploy

### Antes do Primeiro Deploy

- [ ] Supabase projeto criado
- [ ] Migrations executadas
- [ ] RLS configurado
- [ ] Firebase projeto criado
- [ ] Variaveis de ambiente preenchidas
- [ ] Testes passando

### Producao

- [ ] Supabase Pro (ou backup configurado)
- [ ] Stripe em Live Mode
- [ ] Google OAuth em producao
- [ ] SSL/HTTPS configurado
- [ ] Dominio configurado
- [ ] Sentry/PostHog para erros
- [ ] Backups automatizados

---

## Variaveis de Ambiente por Ambiente

### Desenvolvimento (.env)

```env
ENVIRONMENT=development
SUPABASE_URL=https://dev-project.supabase.co
DATABASE_URL=postgresql://...
WORKER_URL=http://localhost:8001
STRIPE_SECRET_KEY=sk_test_...
```

### Producao (.env)

```env
ENVIRONMENT=production
SUPABASE_URL=https://prod-project.supabase.co
DATABASE_URL=postgresql://...
WORKER_URL=http://worker:8001
STRIPE_SECRET_KEY=sk_live_...
```

---

## Docker

### Docker Compose

O projeto inclui Docker Compose para containerizacao:

```yaml
services:
  catas_server:    # API Flask (port 8000)
  catas_worker:    # FastAPI Worker (port 8001)
```

### Como usar

```bash
cd backend
docker-compose up -d
```

### Dockerfiles

- `Dockerfile` - API Flask (Python 3.11-slim, gunicorn, 4 workers)
- `Dockerfile.worker` - FastAPI Worker (Python 3.11-slim)

---

## Troubleshooting Infra

### Supabase
- **"JWT expired"**  Verificar Service Role Key
- **"RLS violation"**  Politicas de acesso
- **"Connection refused"**  Pool de conexoes

### Firebase
- **"FCM token invalid"**  Token expirado, pedir novo
- **"Auth error"**  serviceAccountKey.json correto?

### Stripe
- **"Webhook signature invalid"**  STRIPE_WEBHOOK_SECRET correto?
- **"Customer not found"**  Sync entre Stripe e banco

### Docker
- **"Port already in use"**  Verificar se portas 8000/8001 estao livres
- **"Container not starting"**  Verificar logs com `docker-compose logs`

---

## Topicos Detalhados

### Setup Passo a Passo
- [Setup Completo Local](./setup-local.md)
- [Setup Producao](./setup-producao.md)
- [Migracao de Ambiente](./migration.md)

### Monitoramento
- [Logs e Debugging](./monitoring/logs.md)
- [Metricas](./monitoring/metrics.md)
- [Alertas](./monitoring/alerts.md)

### Seguranca
- [RLS no Supabase](./security/rls.md)
- [Secrets Management](./security/secrets.md)
- [Auditoria](./security/audit.md)

---

> [Voltar para Documentacao](../index.md)
