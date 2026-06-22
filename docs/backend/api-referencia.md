# Referência da API (Backend)

Base URL: `API_BASE_URL/api/v1`

## Chatbot

### `POST /chat/message`

Processa uma mensagem do usuário e retorna texto ou uma ação.

**Corpo da Requisição:**

```json
{
  "message": "string",
  "conversation_id": "uuid (opcional)",
  "current_page_url": "string (opcional)",
  "current_page_title": "string (opcional)",
  "model": "CATAS Basic | CATAS Pro | CATAS MAX"
}
```

**Resposta de Sucesso (Ação):**

```json
{
  "id": "uuid",
  "text": "Preparando para agendar...",
  "isUser": false,
  "actionTriggered": true,
  "actionDetails": {
    "tool": "google_calendar",
    "payload": { ... }
  },
  "session_id": "uuid"
}
```

---

## Sessões e Histórico

### `GET /chat/sessions`

Lista todas as sessões de chat do usuário autenticado.

### `GET /chat/history/{session_id}`

Retorna todas as mensagens de uma sessão específica.

---

## Pagamentos (Stripe)

### `POST /payments/create-checkout-session`

Inicia o fluxo de assinatura para o Stripe.

### `POST /payments/webhook`

Endpoint para receber notificações do Stripe (uso interno).

---

## Usuário

### `GET /user/profile`

Retorna dados do perfil, incluindo cota restante e nível de assinatura.

---

## Automações

### `GET /automations/logs`

Retorna o histórico de execuções de automação do usuário.
