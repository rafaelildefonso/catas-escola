# Referência da API (Backend)

Base URL: `API_BASE_URL/api/v1`

## Autenticação

### `POST /auth/signup`

Cria uma nova conta de usuário.

**Corpo da Requisição:**

```json
{
  "email": "string",
  "password": "string",
  "name": "string"
}
```

### `POST /auth/login`

Autentica um usuário existente.

**Corpo da Requisição:**

```json
{
  "email": "string",
  "password": "string"
}
```

---

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

### `POST /chat/sessions`

Cria uma nova sessão de chat.

### `PATCH /chat/sessions/{session_id}`

Atualiza uma sessão (renomear).

### `DELETE /chat/sessions/{session_id}`

Deleta uma sessão de chat.

---

## Automações

### `GET /automations`

Lista todas as automações do usuário.

### `GET /automations/{id}`

Retorna uma automação específica.

### `POST /automations`

Cria uma nova automação.

### `PUT /automations/{id}`

Atualiza uma automação.

### `DELETE /automations/{id}`

Deleta uma automação.

### `POST /automations/trigger`

Dispara uma automação específica.

---

## Integrações

### `GET /integrations`

Lista todas as integrações do usuário.

### `GET /integrations/{id}`

Retorna uma integração específica.

### `POST /integrations`

Cria uma nova integração.

### `PUT /integrations/{id}`

Atualiza uma integração.

### `DELETE /integrations/{id}`

Deleta uma integração.

---

## Perfis

### `GET /profiles`

Lista todos os perfis.

### `GET /profiles/{id}`

Retorna um perfil específico.

### `POST /profiles`

Cria um novo perfil.

### `PUT /profiles/{id}`

Atualiza um perfil.

### `DELETE /profiles/{id}`

Deleta um perfil.

---

## Relatórios

### `GET /relatorios/dashboard`

Retorna estatísticas gerais do dashboard.

### `GET /relatorios/automacoes`

Retorna relatório de automações com filtros.

**Parâmetros de Query:**
- `status` - Filtrar por status
- `data_inicio` - Data inicial
- `data_fim` - Data final
- `busca` - Termo de busca
- `ordem` - Ordenação
- `limite` - Limite de resultados
- `deslocamento` - Offset para paginação

### `GET /relatorios/chat`

Retorna relatório de conversas.

### `GET /relatorios/mensagens/busca`

Busca mensagens por termo.

**Parâmetros de Query:**
- `termo` - Termo de busca (mín. 2 caracteres)
- `limite` - Limite de resultados
- `deslocamento` - Offset para paginação

---

## Feedback

### `POST /message-feedback`

Registra feedback em uma mensagem.

### `GET /message-feedback`

Lista feedbacks do usuário.

---

## Sugestões de IA

### `GET /ai-suggestions`

Lista sugestões de IA do usuário.

---

## Dispositivos

### `GET /user-devices`

Lista dispositivos do usuário.

### `POST /user-devices`

Registra um novo dispositivo (FCM token).

### `DELETE /user-devices/{id}`

Remove um dispositivo.

---

## Webhooks

### `GET /user-webhook-configs`

Lista configurações de webhook do usuário.

### `POST /user-webhook-configs`

Cria uma nova configuração de webhook.

---

## Memória de IA

### `GET /ia-memories`

Lista memórias de IA do usuário.

### `POST /ia-memories`

Cria uma nova memória de IA.

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

## Padrão CRUD

Cada entidade possui 5 endpoints REST:

| Método | Endpoint | Função |
|--------|----------|--------|
| GET | `/api/v1/<recursos>` | Listar todos |
| GET | `/api/v1/<recursos>/<id>` | Buscar por ID |
| POST | `/api/v1/<recursos>` | Criar |
| PUT | `/api/v1/<recursos>/<id>` | Atualizar |
| DELETE | `/api/v1/<recursos>/<id>` | Deletar |

---

## Erros

A API retorna erros no seguinte formato:

```json
{
  "error": "string",
  "message": "string",
  "status_code": 400
}
```

### Códigos de Erro Comuns

| Código | Descrição |
|--------|-----------|
| 400 | Requisição inválida |
| 401 | Não autenticado |
| 403 | Não autorizado |
| 404 | Recurso não encontrado |
| 409 | Conflito (recurso já existe) |
| 500 | Erro interno do servidor |

---

## Autenticação

Todas as rotas (exceto `/auth/*`) requerem um token JWT no cabeçalho:

```
Authorization: Bearer <token>
```

O token é obtido através do endpoint `/auth/login` ou `/auth/signup`.
