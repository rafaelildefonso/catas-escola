# Integracoes

O CATAS integra-se com varios servicos externos. Este documento descreve cada uma.

---

## 1. Supabase

**Uso:** Autenticacao (Auth) e banco de dados PostgreSQL (via SQLAlchemy).

- **Backend:** Usa `SUPABASE_SERVICE_ROLE_KEY` para validar JWTs via REST API.
- **Flutter:** Usa `SUPABASE_ANON_KEY` para login com Google OAuth via `supabase_flutter`.
- **Banco:** Acesso via SQLAlchemy 2.0 (psycopg2), nao pelo SDK do Supabase.

**Tabelas principais:** `chat_sessions`, `messages`, `automation_logs`, `automations`, `profiles`.

---

## 2. IA (Groq / Gemini / OpenAI)

**Uso:** Pipeline de IA para classificacao de intencao, extracao de entidades e geracao de planos.

- **Servico:** `backend/services/ai_service.py`
- **Provedores:** Groq (padrao), Gemini, OpenAI
- **Funcao:** Classifica intencao, extrai parametros, gera titulos e decide quais componentes de UI exibir.
- **Variavel:** `GROQ_API_KEY`, `GOOGLE_API_KEY`, `OPENAI_API_KEY`

**Fluxo:**

1. Usuario envia mensagem.
2. Backend classifica intencao via IA.
3. Extrai entidades (datas, nomes, emails, etc).
4. Monta payload de automacao e envia para o Worker.
5. Retorna `{ response_text, action_triggered, action_details, components, status, session_title }`.

O campo `status` controla se a conversa parou para uma acao do usuario (`requires_action`) ou se foi concluida (`completed`).

---

## 3. Worker (Automacao)

**Uso:** Motor de execucao de automacoes (FastAPI). Recebe planos da API e executa modulos.

- **Endpoint:** `POST {WORKER_URL}/execute`
- **Modulos:** Google Calendar, Gmail, Sheets, Drive, Docs, HTTP requests, AI Transform.
- **Arquivos:** `backend/worker/runner.py`, `backend/worker/modules/`

O Worker executa cada passo do plano sequencialmente, com suporte a condicionais e resolucao de variaveis.

---

## 4. Stripe (Pagamentos)

**Uso:** Checkout e assinaturas.

### Endpoints

- **create-checkout-session:** Redireciona para Checkout do Stripe.
- **create-subscription:** Retorna `clientSecret` para usar com PaymentElement (formulario de pagamento embutido).

### Webhook Stripe

- **Endpoint:** `POST /api/webhooks/stripe`
- **Evento tratado:** `checkout.session.completed`  atualiza `profiles` para tier "pro".

**Variaveis:** `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`

---

## 5. Google Workspace (Selective Scopes)

**Uso:** Integracao com servicos especificos do Google Workspace (Calendar, Gmail, Drive, Docs).

- **Principio:** O sistema utiliza o principio de menor privilegio. Ao clicar em uma integracao especifica, o app solicita apenas os escopos necessarios para aquele servico.
- **Prefixos de Provedor:** Para diferenciar as integracoes, o backend e o app utilizam o padrao `google_<servico>` (ex: `google_calendar`, `google_gmail`).
- **Escopos por Servico:**
  - `google_calendar`, `google_meet`: `https://www.googleapis.com/auth/calendar`
  - `google_gmail`: `https://www.googleapis.com/auth/gmail.readonly`
  - `google_drive`, `google_docs`: `https://www.googleapis.com/auth/drive.readonly`
- **Flutter:** `google_sign_in` dinamico baseado no servico selecionado.
- **Seguranca:** O usuario concede permissao apenas ao que deseja integrar, sem necessidade de autorizar todo o Workspace de uma vez.

---

## Resumo de Variaveis por Integracao

| Integracao | Variaveis |
|---|---|
| Supabase | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_ANON_KEY` |
| IA | `GROQ_API_KEY`, `GOOGLE_API_KEY`, `OPENAI_API_KEY` |
| Worker | `WORKER_URL` |
| Stripe | `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET` |
| Google OAuth | `WEB_CLIENT_ID`, `ANDROID_CLIENT_ID`, `IOS_CLIENT_ID`, `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET` |

---

## 6. Gerenciamento de Integracoes

O sistema utiliza uma arquitetura modular para gerenciar as conexoes do usuario com servicos externos.

### Arquitetura de Armazenamento

As conexoes sao persistidas na tabela `integrations` do banco de dados:

- **`user_id`**: Identifica o dono da conexao.
- **`provider`**: Identifica o servico (ex: `google_calendar`, `notion`).
- **`access_token` / `refresh_token`**: Credenciais gravadas **criptografadas** (AES-256-GCM; leitura compativel com tokens antigos Fernet).
- **`token_expires_at`**: usado para **refresh lazy** de OAuth (Google) no backend quando o token esta perto de expirar.
- **`settings`**: JSON (escopos e metadados por integracao).

**Variaveis de ambiente (refresh Google):** `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`.

### Como a IA envia dados para as integracoes

O fluxo de automacao segue estas etapas:

1. **Deteccao de Intencao**: A IA identifica o que o usuario deseja fazer.
2. **Extracao de Entidades**: Parametros como datas, nomes e valores sao extraidos.
3. **Verificacao de Permissao**: O backend consulta a tabela `integrations` para verificar se o usuario ja conectou o servico necessario.
4. **Execucao**: O backend monta um plano e envia para o Worker, que executa os modulos com as credenciais do usuario.

### Interface de Gerenciamento

No app Flutter:

- **Listagem**: Tela principal de integracoes mostra todos os servicos disponiveis.
- **Detalhes**: Ao clicar em uma integracao, a `IntegrationDetailsScreen` exibe:
  - Permissoes detalhadas concedidas.
  - Botao **Configurar** para editar o que o sistema pode ou nao fazer.
  - Botao **Desconectar** para revogar o acesso e remover os tokens do banco.
  - Links para politica de privacidade e site original.
  - Canal de **Feedback** especifico para a integracao.
