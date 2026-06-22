# Integrações

O CATAS integra-se com vários serviços externos. Este documento descreve cada uma.

---

## 1. Supabase

**Uso:** Banco de dados (PostgreSQL) e autenticação.

- **Backend:** Usa `SUPABASE_SERVICE_ROLE_KEY` para operações server-side (bypassa RLS).
- **Flutter:** Usa `SUPABASE_ANON_KEY` e respeita RLS para acesso seguro no cliente.
- **Auth:** Google OAuth via `signInWithIdToken`.

**Tabelas principais:** `chat_sessions`, `messages`, `automation_logs`, `automations`, `profiles`.

---

## 2. Google Gemini (AI)

**Uso:** Fallback de IA quando o n8n não está configurado ou falha.

- **Serviço:** `app/services/ai_service.py` → `GeminiService`
- **Modelo:** `gemini-2.5-flash-lite`
- **Função:** Classifica intenção, extrai parâmetros, gera títulos e **decide quais componentes de UI exibir** para interação ou preview.
- **Variável:** `GOOGLE_API_KEY`

**Fluxo:**

1. Usuário envia mensagem.
2. Backend tenta n8n primeiro.
3. Se n8n falhar ou não existir, chama `GeminiService.analyze_message()`.
4. A IA analisa o pedido e verifica se faltam informações ou se precisa de aprovação.
5. Se for a primeira mensagem da sessão, chama `generate_chat_title()`.
6. Retorna `{ response_text, action_triggered, action_details, components, status, session_title }`.

O campo `status` controla se a conversa parou para uma ação do usuário (`requires_action`) ou se foi concluída (`completed`).

---

## 3. n8n (Automações)

**Uso:** Motor de workflows para executar automações (Calendário, Notion, Gmail, etc.).

### Webhook do Chatbot

- **Endpoint n8n:** `{N8N_WEBHOOK_URL}/chatbot`
- **Método:** POST
- **Headers:** `Content-Type: application/json`, `X-N8N-Webhook-Secret: {N8N_WEBHOOK_SECRET}`

**Payload enviado:**

```json
{
  "user_id": "uuid",
  "email": "user@example.com",
  "message": "Agendar reunião amanhã às 14h",
  "conversation_id": "session-uuid",
  "current_page_url": "https://...",
  "current_page_title": "Título"
}
```

**Resposta esperada:**

```json
{
  "text": "Reunião agendada!",
  "actionTriggered": true,
  "actionDetails": {
    "tool": "google_calendar",
    "event_link": "https://...",
    "status": "created"
  }
}
```

### Webhook de Execução

Para `POST /api/v1/execute/action`, a URL é construída como:
`{N8N_WEBHOOK_URL}/{action_type}` (ex: `create_task`, `save_lead`).

### Callback n8n → Backend

O n8n pode enviar notificações para:

- **Endpoint:** `POST /api/webhooks/n8n/callback`
- **Validação:** Header `X-N8N-Webhook-Secret`
- **Payload:** `{ automation_id, status, result }` — atualiza a tabela `automations`.

### Mock n8n

Use `python server/mock_n8n.py` para testes locais. Ele simula respostas para palavras-chave como "reunião", "tarefa", "email".

**Documentação detalhada:** `server/N8N_PAYLOADS.md`

---

## 4. Stripe (Pagamentos)

**Uso:** Checkout e assinaturas.

### Endpoints

- **create-checkout-session:** Redireciona para Checkout do Stripe.
- **create-subscription:** Retorna `clientSecret` para usar com PaymentElement (formulário de pagamento embutido).

### Webhook Stripe

- **Endpoint:** `POST /api/webhooks/stripe`
- **Evento tratado:** `checkout.session.completed` → atualiza `profiles` para tier "pro".

**Variáveis:** `STRIPE_API_TESTE_KEY`, `STRIPE_WEBHOOK_SECRET`

---

## 5. Google Workspace (Selective Scopes)

**Uso:** Integração com serviços específicos do Google Workspace (Calendar, Gmail, Drive, Meet).

- **Princípio:** O sistema utiliza o princípio de menor privilégio. Ao clicar em uma integração específica, o app solicita apenas os escopos necessários para aquele serviço.
- **Prefixos de Provedor:** Para diferenciar as integrações, o backend e o app utilizam o padrão `google_<serviço>` (ex: `google_calendar`, `google_gmail`).
- **Escopos por Serviço:**
  - `google_calendar`, `google_meet`: `https://www.googleapis.com/auth/calendar`
  - `google_gmail`: `https://www.googleapis.com/auth/gmail.readonly`
  - `google_drive`, `google_docs`: `https://www.googleapis.com/auth/drive.readonly`
- **Flutter:** `google_sign_in` dinâmico baseado no serviço selecionado.
- **Segurança:** O usuário concede permissão apenas ao que deseja integrar, sem necessidade de autorizar todo o Workspace de uma vez.

---

## Resumo de Variáveis por Integração

| Integração   | Variáveis                                                        |
| ------------ | ---------------------------------------------------------------- |
| Supabase     | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_ANON_KEY` |
| Gemini       | `GOOGLE_API_KEY`                                                 |
| n8n          | `N8N_WEBHOOK_URL`, `N8N_WEBHOOK_SECRET`                          |
| Stripe       | `STRIPE_API_TESTE_KEY`, `STRIPE_WEBHOOK_SECRET`                  |
| Google OAuth | `WEB_CLIENT_ID`, `ANDROID_CLIENT_ID`, `IOS_CLIENT_ID`            |

---

## 6. Gerenciamento de Integrações

O sistema utiliza uma arquitetura modular para gerenciar as conexões do usuário com serviços externos.

### Arquitetura de Armazenamento

As conexões são persistidas na tabela `integrations` do Supabase:

- **`user_id`**: Identifica o dono da conexão.
- **`provider`**: Identifica o serviço (ex: `google_calendar`, `notion`).
- **`access_token` / `refresh_token`**: Credenciais gravadas **criptografadas** (AES-256-GCM; leitura compatível com tokens antigos Fernet).
- **`token_expires_at`**: usado para **refresh lazy** de OAuth (Google) no backend quando o token está perto de expirar.
- **`settings`**: JSON (escopos e metadados por integração).

**Variáveis de ambiente (refresh Google):** `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET` (ou `GOOGLE_OAUTH_CLIENT_SECRET` / `WEB_CLIENT_ID` conforme o ambiente).

### Como a IA envia dados para as integrações

O fluxo de automação segue estas etapas:

1. **Detecção de Intenção**: A IA (`GeminiService`) identifica o que o usuário deseja fazer.
2. **Extração de Entidades**: Parâmetros como datas, nomes e valores são extraídos.
3. **Verificação de Permissão**: O backend consulta a tabela `integrations` para verificar se o usuário já conectou o serviço necessário e se o CATAS tem permissão para a ação solicitada.
4. **Disparo do Workflow**: Se autorizado, o backend envia os dados extraídos + o token de acesso do usuário para um webhook no **n8n**.
5. **Execução**: O n8n utiliza as credenciais para realizar a ação final na API do serviço (ex: Google Calendar).

### Interface de Gerenciamento

No app Flutter:

- **Listagem**: Tela principal de integrações mostra todos os serviços disponíveis.
- **Detalhes**: Ao clicar em uma integração, a `IntegrationDetailsScreen` exibe:
  - Permissões detalhadas concedidas.
  - Botão **Configurar** para editar o que o sistema pode ou não fazer.
  - Botão **Desconectar** para revogar o acesso e remover os tokens do banco.
  - Links para política de privacidade e site original.
  - Canal de **Feedback** específico para a integração.
