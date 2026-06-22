# Infra & DevOps Guide

> 🔧 **Você está configurando:** Deploy, banco, integrações  
> 🏗️ **Stack:** Docker, Supabase, Firebase, Stripe, Temporal

---

## 🎯 O que você precisa saber

O CATAS depende de **5 serviços externos** que precisam ser configurados:

```
┌─────────────────────────────────────────────────────────┐
│  Serviços Essenciais                                    │
├─────────────────────────────────────────────────────────┤
│  1. Supabase           ← Banco de dados + Auth         │
│  2. Temporal Server    ← Orquestração de workflows     │
│  3. Firebase           ← Push notifications            │
├─────────────────────────────────────────────────────────┤
│  Serviços Opcionais (para produção)                   │
├─────────────────────────────────────────────────────────┤
│  4. Stripe             ← Pagamentos e planos           │
│  5. Google Cloud       ← OAuth para Google apps        │
└─────────────────────────────────────────────────────────┘
```

---

## 🚀 Quick Setup

### Local (Desenvolvimento)

```bash
# 1. Supabase
# Criar projeto gratuito em https://supabase.com
# Anotar URL e Service Role Key

# 2. Temporal (Docker)
cd server/docker/temporal
docker-compose up -d

# 3. Firebase (opcional para dev)
# Criar projeto em https://console.firebase.google.com
# Baixar serviceAccountKey.json

# Pronto! API e Worker podem rodar.
```

### Produção

```bash
# 1. Supabase Pro ou Self-hosted
# 2. Temporal Cloud (recomendado) ou self-hosted
# 3. Firebase (obrigatório para push)
# 4. Stripe (obrigatório para pagamentos)
# 5. Google OAuth (obrigatório para integrações)
```

---

## 📂 Guias por Serviço

### 1. Supabase (Banco de Dados)

**O que é:** PostgreSQL + Auth + Realtime + Storage

**Setup:**
- [Criar projeto](./supabase/setup.md)
- [Executar migrations](./supabase/migrations.md)
- [Configurar RLS (Row Level Security)](./supabase/rls.md)
- [Realtime channels](./supabase/realtime.md)

**Arquivos:**
- `server/migrations/*.sql` - Schema
- `server/app/repositories/*.py` - Acesso

### 2. Temporal (Orquestração)

**O que é:** Workflows resilientes para automações

**Setup:**
- [Local com Docker](./temporal/local.md)
- [Temporal Cloud](./temporal/cloud.md)
- [Monitoreo](./temporal/monitoring.md)

**Arquivos:**
- `server/docker/temporal/` - Docker compose
- `server/worker/` - Código do worker

### 3. Firebase (Notificações)

**O que é:** FCM (Firebase Cloud Messaging) para push

**Setup:**
- [Criar projeto](./firebase/setup.md)
- [Configurar FCM](./firebase/fcm.md)
- [Integrar com Flutter](./firebase/flutter.md)

**Arquivos:**
- `app_flutter/lib/firebase/` - Config
- `server/app/services/notifications.py` - Backend

### 4. Stripe (Pagamentos)

**O que é:** Assinaturas e pagamentos

**Setup:**
- [Criar conta](./stripe/setup.md)
- [Configurar webhooks](./stripe/webhooks.md)
- [Planos e preços](./stripe/plans.md)

**Arquivos:**
- `server/app/routers/stripe.py` - Endpoints
- `server/app/services/credit_service.py` - Créditos

### 5. Google OAuth (Integrações)

**O que é:** Acesso a Google Calendar, Gmail, Sheets

**Setup:**
- [Criar projeto Cloud](./google/setup.md)
- [Configurar OAuth consent](./google/oauth.md)
- [Habilitar APIs](./google/apis.md)

**Arquivos:**
- `server/app/repositories/integrations.py` - Tokens
- `server/worker/activities/calendar/` - Uso

---

## 📋 Checklists de Deploy

### Antes do Primeiro Deploy

- [ ] Supabase projeto criado
- [ ] Migrations executadas
- [ ] RLS configurado
- [ ] Temporal Server acessível
- [ ] Firebase projeto criado
- [ ] Variáveis de ambiente preenchidas
- [ ] Testes passando

### Produção

- [ ] Supabase Pro (ou backup configurado)
- [ ] Temporal Cloud (ou cluster configurado)
- [ ] Stripe em Live Mode
- [ ] Google OAuth em produção
- [ ] SSL/HTTPS configurado
- [ ] Domínio configurado
- [ ] Sentry/PostHog para erros
- [ ] Backups automatizados

---

## 🔧 Variáveis de Ambiente por Ambiente

### Desenvolvimento (.env)

```env
ENVIRONMENT=development
SUPABASE_URL=https://dev-project.supabase.co
TEMPORAL_HOST=localhost:7233
STRIPE_SECRET_KEY=sk_test_...
```

### Produção (.env)

```env
ENVIRONMENT=production
SUPABASE_URL=https://prod-project.supabase.co
TEMPORAL_HOST=temporal.cloud:7233
TEMPORAL_TLS_CERT=/certs/cert.pem
TEMPORAL_TLS_KEY=/certs/key.pem
STRIPE_SECRET_KEY=sk_live_...
```

---

## 🆘 Troubleshooting Infra

### Supabase
- **"JWT expired"** → Verificar Service Role Key
- **"RLS violation"** → Políticas de acesso
- **"Connection refused"** → Pool de conexões

### Temporal
- **"Worker not found"** → Verificar task queue
- **"Connection refused"** → Temporal Server rodando?
- **"TLS error"** → Certificados válidos?

### Firebase
- **"FCM token invalid"** → Token expirado, pedir novo
- **"Auth error"** → serviceAccountKey.json correto?

### Stripe
- **"Webhook signature invalid"** → STRIPE_WEBHOOK_SECRET correto?
- **"Customer not found"** → Sync entre Stripe e Supabase

---

## 📚 Tópicos Detalhados

### Setup Passo a Passo
- [Setup Completo Local](./setup-local.md)
- [Setup Produção](./setup-producao.md)
- [Migração de Ambiente](./migration.md)

### Monitoramento
- [Logs e Debugging](./monitoring/logs.md)
- [Métricas](./monitoring/metrics.md)
- [Alertas](./monitoring/alerts.md)

### Segurança
- [RLS no Supabase](./security/rls.md)
- [Secrets Management](./security/secrets.md)
- [Auditoria](./security/audit.md)

---

> ⬅️ [Voltar para Documentação](../index.md)
