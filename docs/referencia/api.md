# Referência da API CATAS

> **Base URL:** `http://localhost:8000` (desenvolvimento)  
> **Prefixo:** `/api/v1` para rotas principais  
> **Documentação interativa:** `/docs` (Swagger UI)

## Autenticação

Todas as rotas protegidas exigem o header:

```
Authorization: Bearer <jwt_token>
```

O token JWT é obtido via **Supabase Auth** (Google Sign-In). O Flutter envia o `accessToken` da sessão Supabase.

### Desenvolvimento (Bypass)

Para testes locais sem autenticação real, use:

```
Authorization: Bearer dev-token
```

---

## Endpoints

### 1. Chat

| Método   | Endpoint                                   | Descrição                             |
| -------- | ------------------------------------------ | ------------------------------------- |
| `POST`   | `/api/v1/chat/message`                     | Envia mensagem e obtém resposta da IA |
| `POST`   | `/api/v1/chat/sessions`                    | Cria nova sessão de chat              |
| `GET`    | `/api/v1/chat/sessions`                    | Lista sessões do usuário              |
| `GET`    | `/api/v1/chat/sessions/{session_id}`       | Obtém sessão específica               |
| `GET`    | `/api/v1/chat/history/{session_id}`        | Histórico de mensagens                |
| `PATCH`  | `/api/v1/chat/sessions/{session_id}/title` | Atualiza título da sessão             |
| `DELETE` | `/api/v1/chat/sessions/{session_id}`       | Deleta sessão                         |

#### POST /api/v1/chat/message

**Request:**

```json
{
  "message": "Agendar reunião amanhã às 14h",
  "conversation_id": "uuid-opcional",
  "current_page_url": "https://...",
  "current_page_title": "Título da Página"
}
```

**Response (200):**

```json
{
  "id": "msg-uuid",
  "text": "Reunião agendada para amanhã às 14h!",
  "isUser": false,
  "actionTriggered": true,
  "actionDetails": {
    "tool": "google_calendar",
    "event_link": "https://calendar.google.com/...",
    "status": "created"
  },
  "components": [
    {
      "type": "preview_calendar_event",
      "data": { "title": "Reunião", "start_time": "..." }
    }
  ],
  "status": "completed",
  "session_id": "session-uuid",
  "session_title": "Agendar Reunião de Equipe"
}
```

_Consulte a [referência de componentes](./componentes-ui.md) para mais detalhes sobre o campo `components` e o fluxo multi-turn controlado pelo campo `status`._

_`session_title` só é retornado no primeiro envio da conversa._

#### POST /api/v1/chat/sessions

**Request:**

```json
{
  "title": "Minha Conversa"
}
```

`title` é opcional (padrão: "Nova Conversa").

**Response:**

```json
{
  "status": "success",
  "message": "Sessão criada com sucesso",
  "data": {
    "id": "uuid",
    "user_id": "uuid",
    "title": "Minha Conversa",
    "created_at": "2026-02-14T...",
    "updated_at": "2026-02-14T..."
  }
}
```

#### GET /api/v1/chat/sessions

**Query params:** `limit` (opcional, padrão: 50)

**Response:**

```json
{
  "status": "success",
  "message": "N sessões encontradas",
  "data": [
    {
      "id": "uuid",
      "user_id": "uuid",
      "title": "Nova Conversa",
      "created_at": "...",
      "updated_at": "..."
    }
  ]
}
```

#### GET /api/v1/chat/history/{session_id}

**Query params:** `limit` (opcional, padrão: 100)

**Response:**

```json
{
  "status": "success",
  "message": "N mensagens encontradas",
  "data": [
    {
      "id": "uuid",
      "session_id": "uuid",
      "role": "user",
      "content": "Texto da mensagem",
      "metadata": {},
      "created_at": "..."
    }
  ]
}
```

#### PATCH /api/v1/chat/sessions/{session_id}/title

**Request:**

```json
{
  "title": "Novo Título da Conversa"
}
```

**Response:**

```json
{
  "status": "success",
  "message": "Título atualizado com sucesso",
  "data": {
    "id": "uuid",
    "title": "Novo Título da Conversa",
    "updated_at": "..."
  }
}
```

---

### 2. Execute (Automações)

| Método | Endpoint                 | Descrição                    |
| ------ | ------------------------ | ---------------------------- |
| `POST` | `/api/v1/execute/action` | Executa ação via webhook n8n |

#### POST /api/v1/execute/action

**Request:**

```json
{
  "action_type": "create_task",
  "payload": {
    "title": "Tarefa exemplo",
    "description": "Detalhes..."
  }
}
```

**Response:**

```json
{
  "status": "success",
  "message": "Ação enviada para execução",
  "data": {
    "automation_id": "uuid",
    "status": "pending",
    "n8n_response": { ... }
  }
}
```

---

### 3. User

| Método | Endpoint          | Descrição                |
| ------ | ----------------- | ------------------------ |
| `GET`  | `/api/v1/user/me` | Perfil do usuário e cota |

#### GET /api/v1/user/me

**Response:**

```json
{
  "status": "success",
  "message": "Perfil recuperado com sucesso",
  "data": {
    "id": "uuid",
    "email": "user@example.com",
    "subscription_tier": "free",
    "daily_quota_limit": 5,
    "quota_used_today": 2,
    "quota_remaining": 3,
    "last_quota_reset": "2026-02-14"
  }
}
```

---

### 4. Automations

| Método | Endpoint                      | Descrição               |
| ------ | ----------------------------- | ----------------------- |
| `GET`  | `/api/v1/automations/history` | Histórico de automações |
| `GET`  | `/api/v1/automations/stats`   | Estatísticas (gráficos) |

---

### 5. Payments (Stripe)

| Método | Endpoint                                   | Descrição                        |
| ------ | ------------------------------------------ | -------------------------------- |
| `POST` | `/api/v1/payments/create-checkout-session` | Cria sessão Checkout             |
| `POST` | `/api/v1/payments/create-subscription`     | Cria assinatura (PaymentElement) |

#### POST /api/v1/payments/create-checkout-session

**Request:**

```json
{
  "price_id": "price_..."
}
```

**Response:**

```json
{
  "url": "https://checkout.stripe.com/..."
}
```

#### POST /api/v1/payments/create-subscription

**Request:**

```json
{
  "price_id": "price_..."
}
```

**Response:**

```json
{
  "subscriptionId": "sub_...",
  "clientSecret": "pi_..._secret_..."
}
```

---

### 6. Prompt

| Método | Endpoint          | Descrição                 |
| ------ | ----------------- | ------------------------- |
| `POST` | `/prompt/improve` | Melhora um prompt textual |

#### POST /prompt/improve

**Request:**

```json
{
  "text": "escrever um código em python para ler um csv"
}
```

**Response:**

```json
{
  "original": "...",
  "improved": "# Solicitação de Desenvolvimento\n\n## Objetivo\n..."
}
```

---

### 7. Webhooks (incoming)

| Método | Endpoint | Descrição |
| ------ | -------- | --------- |
| `POST` | `/api/webhooks/stripe` | Webhook Stripe (checkout.session.completed) |

---

### 8. Health

| Método | Endpoint  | Descrição           |
| ------ | --------- | ------------------- |
| `GET`  | `/health` | Health check da API |
| `GET`  | `/`       | Informações da API  |

---

## Códigos de Erro

| Código | Significado                                        |
| ------ | -------------------------------------------------- |
| 401    | Token inválido ou ausente                          |
| 403    | Sem permissão                                      |
| 404    | Recurso não encontrado                             |
| 500    | Erro interno do servidor                           |
| 503    | Serviço de IA indisponível                         |
