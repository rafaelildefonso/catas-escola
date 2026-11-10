# CATAS — Resumo Geral do Projeto

> Documento de referência para a equipe. Revisado contra o código-fonte em **6 de novembro de 2026**. Ele descreve o que está implementado no repositório; documentos antigos podem usar nomes e rotas que já foram substituídos.

## 1. Resposta curta: o que é o CATAS?

**CATAS**. É uma plataforma de automação inteligente em que a pessoa conversa em linguagem natural com uma IA. A IA interpreta o pedido, coleta informações necessárias, monta um plano de automação e, quando aplicável, executa ações em serviços externos.

Exemplo: a pessoa pede “envie um e-mail toda segunda-feira para a equipe”. O sistema entende a intenção, confirma dados que estiverem faltando, salva uma automação recorrente, agenda sua próxima execução e o worker envia o e-mail no momento certo.

O projeto é um SaaS acadêmico, com contas, planos, cotas de uso, automações, integrações Google, relatórios, anexos, notificações e modo de demonstração.

## 2. Visão arquitetural

```text
Pessoa usuária
      │
      ▼
Flutter (Web, Android, iOS e Windows)
  telas + estado + autenticação + chamadas HTTP
      │  Authorization: Bearer <JWT>
      ▼
API Flask (porta 8000)
  rotas → controllers → services → models/repositories
      │                         │
      │                         ├──────────────► Banco SQL
      │                         │                PostgreSQL em produção
      │                         │                SQLite no desenvolvimento local
      │                         │
      ├──► provedores de IA: Groq, Gemini e OpenAI
      ├──► Stripe: assinatura e cobrança
      ├──► Google OAuth: credenciais das integrações
      └──► Worker HTTP (porta 8001)
                         │
                         ▼
                  AutomationRunner
                  executa módulos sequenciais
                  Gmail, Calendar, Drive, Sheets, HTTP, IA e relatórios PDF

Scheduler separado (a cada 15 s) ──► dispara automações vencidas
```

### Componentes e responsabilidades

| Componente | Onde fica | Responsabilidade |
|---|---|---|
| Aplicativo | `frontend/` | Interface multiplataforma, estado local, navegação e consumo da API. |
| Landing e páginas institucionais | `frontend/web/` | Página pública, termos, privacidade, cookies, segurança e contato. |
| API principal | `backend/application.py`, `backend/routes.py` | Cria o Flask, configura CORS e banco, autentica, expõe a API e orquestra as regras de negócio. |
| Serviços | `backend/services/` | Casos de uso e regras: chat, IA, automação, relatórios, billing etc. |
| Dados | `backend/models/`, `backend/repositories/`, `backend/migrations/` | Modelos SQLAlchemy, consultas complexas e evolução do schema. |
| Worker | `backend/worker/` | Recebe e executa planos de automação em segundo plano. |
| Scheduler | `backend/services/automation/scheduler.py` | Encontra automações agendadas e as despacha ao worker. |
| Documentação existente | `docs/` | Site de documentação Mintlify; útil como apoio, mas algumas páginas estão defasadas. |

## 3. Tecnologias utilizadas

| Área | Tecnologias efetivamente presentes |
|---|---|
| Frontend | Flutter/Dart, Material 3, Provider, GoRouter, Dio e `http`. |
| Backend | Python 3.11, Flask, Flask-SQLAlchemy, Pydantic, Gunicorn. |
| Banco | SQLAlchemy; SQLite em desenvolvimento e PostgreSQL como destino de produção. |
| IA | Groq, Gemini e OpenAI, selecionados por plano/configuração. |
| Automação | `asyncio`, `httpx`, Jinja2 e registro de módulos Python. |
| Autenticação e push | JWT próprio; Firebase Admin/FCM é inicializado quando configurado. |
| Pagamentos | Stripe Checkout, Customer Portal e webhook assinado. |
| Arquivos | Serviço de anexos; frontend também contém integração Cloudinary. |
| Qualidade | Pytest, Ruff, testes Flutter e auditoria reproduzível de integrações. |

## 4. Mapa rápido do repositório

```text
CATAS - Escola/
├── frontend/                       # Aplicativo Flutter
│   ├── lib/
│   │   ├── main.dart                # Inicialização e injeção dos Providers
│   │   ├── core/                    # Router, tema, responsividade e configuração
│   │   ├── screens/                 # Páginas/telas
│   │   ├── components/              # Widgets reutilizáveis
│   │   ├── providers/               # Estado compartilhado
│   │   ├── data/                    # Repositórios HTTP e persistência local
│   │   ├── models/                  # Modelos Dart
│   │   └── l10n/                    # Português e inglês
│   ├── web/                         # Landing e documentos institucionais HTML
│   ├── android/, ios/, windows/     # Adaptadores nativos das plataformas
│   └── test/                        # Smoke, router e widget tests
├── backend/                         # API Flask + worker de automações
│   ├── application.py               # Fábrica Flask, CORS, DB, erros e Firebase
│   ├── run.py                       # Inicialização local, tabelas e API em 8000
│   ├── routes.py                    # As 131 rotas HTTP
│   ├── controllers/                 # Ponte HTTP para os serviços
│   ├── services/                    # Casos de uso e regras de negócio
│   ├── models/                      # 22 entidades SQLAlchemy + schema do plano
│   ├── repositories/                # Consultas e relatórios complexos
│   ├── core/                        # Configuração, JWT, criptografia e OAuth
│   ├── worker/                      # Executor de automações em 8001
│   ├── migrations/                  # SQL, RLS e procedimentos
│   ├── tests/                       # Testes de backend
│   └── worker/                      # Executor e módulos de automação
├── docs/                            # Site/documentação complementar
├── README.md                        # Visão geral e requisitos do trabalho
├── RUN_CATAS.md                     # Comandos de execução
├── ROTEIRO_DEMO.md                  # Roteiro para demonstrar o produto
├── auditoria_integracoes.py          # Auditoria reproduzível dos conectores
├── resultado_auditoria_integracoes.json # Último resultado da auditoria
└── resumo_geral.md                  # Este arquivo
```

## 5. Frontend: onde está cada página

O ponto de entrada é `frontend/lib/main.dart`. Ele carrega `.env`, tenta inicializar Firebase, registra deep links e cria os Providers. A navegação está centralizada em `frontend/lib/core/router.dart`.

### Rotas, telas e arquivos

| URL | Tela | Arquivo | O que a pessoa faz nela |
|---|---|---|---|
| `/` | Landing | `frontend/web/landing.html` | Conhece o produto; no web o Flutter renderiza o HTML público. |
| `/app/login` | Login | `screens/auth/login_screen.dart` | Cria conta ou entra com e-mail e senha. |
| `/app/onboarding` | Onboarding | `screens/onboarding/onboarding_screen.dart` | Informa setor/cargo e conclui a preparação inicial. |
| `/app` | Chat | `screens/chat/chat_screen.dart` | Conversa com a IA, envia anexos e aprova ações. |
| `/app/chat/:sessionId` | Chat salvo | `screens/chat/chat_screen.dart` | Abre uma conversa específica. |
| `/app/history` | Histórico | `screens/chat/history_screen.dart` | Lista, abre, renomeia e remove conversas. |
| `/app/automations` | Automações ativas | `screens/automacoes/active_automations_screen.dart` | Cria, edita, executa, agenda e acompanha automações. |
| `/app/automations/:runId` | Detalhe da execução | `screens/automacoes/automation_detail_screen.dart` | Exibe a execução e seus passos/logs. |
| `/app/integrations` | Integrações | `screens/integracoes/integrations_screen.dart` | Conecta ou desconecta serviços externos. |
| `/app/dashboard` | Dashboard de impacto | `screens/dashboard/impact_dashboard_screen.dart` | Exibe métricas de uso e produtividade. |
| `/app/relatorios` | Biblioteca de relatórios | `screens/relatorios/reports_screen.dart` | Lista PDFs criados por automações e permite baixá-los. |
| `/app/pricing` | Planos | `screens/assinatura/pricing_screen.dart` | Compara planos e inicia Checkout Stripe. |
| `/app/settings/subscription` | Assinatura | `screens/assinatura/manage_subscription_screen.dart` | Abre o portal Stripe para gerenciar a assinatura. |
| `/app/payment-success` | Sucesso de pagamento | `screens/assinatura/subscription_success_screen.dart` | Confirma retorno após compra. |
| `/app/settings` | Configurações | `screens/configuracoes/settings_screen.dart` | Tema, idioma, preferências e atalhos. |
| `/app/settings/export` | Exportar dados | `screens/relatorios/relatorio_screen.dart` (`DataExportScreen`) | Consulta dados analíticos de chat/automações e os exporta em CSV, XLSX ou PDF. |
| `/app/settings/account` | Conta | `screens/configuracoes/account_settings_screen.dart` | Atualiza dados ou exclui a conta. |
| `/app/settings/about` | Sobre | `screens/configuracoes/settings_content.dart` | Informações do produto. |
| `/app/settings/help` | Ajuda | `screens/configuracoes/settings_content.dart` | Conteúdo de suporte. |
| `/app/notifications` | Notificações | `screens/notificacoes/notification_list_screen.dart` | Lista e marca notificações como lidas. |
| `/app/prompts` | Prompts sugeridos | `screens/suggested_prompts_screen.dart` | Atalhos para iniciar conversas. |
| `/app/crud` | Gestão CRUD | `screens/crud/crud_management_screen.dart` | Tela utilitária de administração de entidades. |
| `/app/report/demo` | Relatório demo | `screens/demo_report_screen.dart` | Disponível somente com `DEMO_MODE=true`. |
| `/terms`, `/privacy`, etc. | Institucional | `frontend/web/pages/institucional/` | Termos, consentimento, privacidade, segurança, contato, cookies, reembolso e sobre. |

### Layout e responsividade

- `screens/main_layout.dart` é o contêiner para mobile e apps nativos: AppBar, drawer e suporte a arrastar arquivo para o chat.
- `screens/web/web_main_layout.dart` é o contêiner para desktop web; usa `web_sidebar.dart`.
- `components/app_drawer.dart` concentra a navegação móvel.
- `core/responsive.dart` e `core/responsive_layout.dart` determinam os breakpoints.
- `core/theme.dart` e `providers/theme_provider.dart` configuram tema claro, escuro ou do sistema.

### Estado do aplicativo: Providers

| Provider | Arquivo | Mantém/controla |
|---|---|---|
| `AuthProvider` | `providers/auth_provider.dart` | Sessão JWT, perfil, plano, cotas, onboarding, atualização e remoção de conta. |
| `ChatProvider` | `providers/chat_provider.dart` | Sessões, histórico, mensagens, rascunho, anexos, feedback, modelo escolhido e progresso da automação. |
| `AutomationsProvider` | `providers/automations_provider.dart` | Lista de automações, runs e logs de cada etapa. |
| `IntegrationsProvider` | `providers/integrations_provider.dart` | Estado das conexões externas. |
| `RelatorioProvider` | `providers/relatorio_provider.dart` | Filtros e dados de dashboard/relatórios. |
| `GeneratedReportsProvider` | `providers/generated_reports_provider.dart` | Biblioteca de relatórios automáticos gerados em PDF. |
| `NotificationsProvider` | `providers/notifications_provider.dart` | Busca e leitura de notificações. |
| `TermoAceiteProvider` | `providers/termo_aceite_provider.dart` | Aceite de termos e consentimento. |
| `LocaleProvider` | `providers/locale_provider.dart` | Idioma português/inglês. |
| `ThemeProvider` | `providers/theme_provider.dart` | Tema visual. |
| `NavigationProvider` | `providers/navigation_provider.dart` | Página atualmente selecionada. |
| `NativeContextProvider` | `providers/native_context_provider.dart` | Contexto do navegador/aplicativo nativo, quando disponível. |
| `CloudinaryProvider` | `providers/cloudinary_provider.dart` | Estado do envio via Cloudinary. |
| `ServerStatusProvider` | `providers/server_status_provider.dart` | Estado de disponibilidade do servidor. |
| Providers `Demo*` | `providers/demo_*.dart` | Dados simulados e reprodução guiada para demonstração. |

### Repositórios de dados no Flutter

O frontend não acessa o banco diretamente. `frontend/lib/data/` encapsula as chamadas HTTP.

`frontend/lib/core/api_client.dart` é o cliente Dio compartilhado para chamadas que o adotam, incluindo o chat. Ele injeta o JWT de `TokenHolder` e converte erros da API em `ApiException`, preservando a mensagem `detail` do backend para a interface.

| Arquivo | API consumida | Finalidade |
|---|---|---|
| `chat_repository.dart` | `/chat/*` | Sessões, histórico, mensagens, continuação do fluxo e feedback. |
| `automations_repository.dart` | `/automations`, `/automation-runs`, `/automation-step-logs` | CRUD, execução, revisão e acompanhamento. |
| `relatorio_repository.dart` | `/relatorios/*` | Dashboard, consultas, busca e exportação. |
| `generated_reports_repository.dart` | `/relatorios/gerados/*` | Lista e baixa PDFs criados pelas automações. |
| `billing_repository.dart` | `/billing/*` | Checkout, portal e status da assinatura. |
| `storage_repository.dart` | `/attachments/*` | Envio, listagem, exclusão e preview de arquivos. |
| `notifications_repository.dart` | `/notifications/*` | Leitura e confirmação de notificações. |
| `termo_aceite_repository.dart` | `/termos/aceite` | Consulta e registro de aceite. |
| `crud_api_service.dart` | Recursos CRUD genéricos | Apoia a tela administrativa. |

## 6. Backend: camadas e caminho de uma requisição

O padrão esperado é:

```text
HTTP → routes.py → Controller → Service → Model/Repository → Banco
```

| Camada | Pasta/arquivo | Papel | Regra importante |
|---|---|---|---|
| Route | `backend/routes.py` | Associa URL, método e função. | Não deve conter regra de negócio. |
| Controller | `backend/controllers/` | Lê request, verifica autenticação e devolve JSON/status HTTP. | Não deve consultar banco diretamente. |
| Service | `backend/services/` | Valida entrada, aplica regras e orquestra modelos/integrações. | Um serviço por caso de uso. |
| Repository | `backend/repositories/` | Consultas complexas, filtros e relatórios. | É usado sobretudo para leitura. |
| Model | `backend/models/` | Schema, relações e CRUD básico (`salvar`, `atualizar`, `deletar`, `to_dict`). | É a camada que persiste dados. |

### Arquivos de entrada

- `backend/application.py`: `create_app()`, URL do banco, CORS, SQLAlchemy, rotas, handlers globais e Firebase Admin.
- `backend/run.py`: modo local. Cria tabelas, aplica pequenos ajustes de compatibilidade SQLite, inicializa Firebase e sobe Flask em `127.0.0.1:8000`.
- `backend/routes.py`: fonte de verdade de todas as **131 rotas**.
- `backend/core/config.py`: lê variáveis de ambiente e define modelos IA, limites e URLs externas.

### Autenticação e autorização

1. O Flutter chama `POST /api/v1/auth/signup` ou `POST /api/v1/auth/login`.
2. A API retorna um JWT próprio, assinado com `JWT_SECRET_KEY`.
3. O app guarda o token em `flutter_secure_storage` e o reutiliza no cabeçalho `Authorization: Bearer <token>`.
4. Rotas protegidas usam `@login_required`, de `backend/core/security.py`.
5. Em desenvolvimento existe o token `dev-token`, que representa um usuário de desenvolvimento.
6. Controllers e serviços escopam os recursos pelo `user_id`; por isso uma pessoa não deve consultar automações ou registros de outra.

`core/security.py` também possui uma filtragem simples de padrões de prompt injection antes do processamento da mensagem.

## 7. API: grupos de endpoints atuais

Todas as rotas abaixo têm prefixo `/api/v1`, salvo `/` e `/health`.

| Grupo | Rotas principais | Controller | Uso |
|---|---|---|---|
| Saúde | `GET /health`, `GET /` | `application.py` | Verifica disponibilidade e identifica a API. |
| Autenticação | `POST /auth/signup`, `/auth/login`; `GET /auth/me` | `AuthController` | Conta, login e perfil da sessão. |
| Chat | `/chat/sessions`, `/chat/history/<id>`, `/chat/message`, `/chat/message/continue` | `ChatController`, `ChatbotController` | Conversas, histórico, resposta da IA e continuação de formulários. |
| Feedback | `POST /chat/messages/<id>/feedback`, `GET /chat/sessions/<id>/feedback` | `FeedbackController` | Avaliação de respostas. |
| Perfil/usuários/termos | `/profiles`, `/users`, `/termos/aceite` | Controllers correspondentes | Dados de conta, perfil, cotas e LGPD. |
| Automações | `/automations`, `/<id>/schedule`, `/<id>/run`, `/<id>/revise` | `AutomationController` | Criar, editar, agendar, executar e revisar automações. |
| Execuções | `/automation-runs`, `/automation-step-logs` | Controllers seguros | Consultar ou apagar runs/logs próprios; criação/edição por API é bloqueada. |
| Integrações | `/integrations`, `/integrations/google/auth-url`, `/integrations/google/callback` | `IntegrationController`, `GoogleIntegrationController` | OAuth Google e conexões armazenadas. |
| Dados auxiliares | `/messages`, `/chat-sessions`, `/ai-suggestions`, `/page-contexts`, `/browser-sessions`, `/page-analysis-cache`, `/ia-memories`, `/user-devices`, `/user-webhook-configs` | Controllers CRUD | Recursos internos e administrativos. |
| Relatórios analíticos | `/relatorios/dashboard`, `/automacoes`, `/chat`, `/mensagens/busca`, `/export` | `RelatorioController` | Dados agregados, filtros, busca e exportação CSV/XLSX/PDF. |
| Relatórios gerados | `GET /relatorios/gerados`, `GET /relatorios/gerados/<id>/download` | `RelatoriosGeradosController` | Biblioteca e download de PDFs produzidos por automações. |
| Cobrança | `POST /billing/checkout`, `/billing/portal`, `GET /billing/status`, `GET /billing/checkout-session/<id>`, `POST /billing/webhook` | `BillingController` | Stripe, confirmação segura do retorno do Checkout e sincronização do plano. |
| Anexos | `POST/GET /attachments`, `DELETE /attachments/<id>`, `GET /attachments/<id>/preview` | `AttachmentController` | Arquivos privados e preview de DOCX. |
| Notificações | `GET /notifications`, `PATCH /notifications/<id>/read` | `NotificationController` | Listar e marcar como lida. |

### CRUD padronizado

Muitas entidades internas têm o padrão abaixo: `GET /recurso`, `GET /recurso/<id>`, `POST /recurso`, `PUT /recurso/<id>`, `DELETE /recurso/<id>`. A fonte definitiva é `backend/routes.py`; nem todo CRUD é exposto ao usuário final.

## 8. Fluxo principal: conversa com IA

```text
1. ChatScreen → ChatProvider → ChatRepository
2. POST /api/v1/chat/message
3. ChatbotController → EnviarMensagemChatService.executar()
4. Valida mensagem, sessão, plano/cota, anexos e proteção de prompt
5. Salva a mensagem da pessoa em messages
6. Obtém as últimas mensagens da sessão
7. AIService classifica intenção e, se for ação, extrai entidades
8. Retorna conversa comum, componentes interativos ou plano de automação
9. Salva a mensagem do assistente em messages
10. Flutter renderiza texto, cards e componentes dinâmicos
```

### Onde cada parte desse fluxo está

| Ação | Arquivos principais |
|---|---|
| Tela e envio | `frontend/lib/screens/chat/chat_screen.dart`, `providers/chat_provider.dart` |
| HTTP | `frontend/lib/data/chat_repository.dart` |
| Endpoint | `backend/controllers/chatbot_controller.py` |
| Orquestração | `backend/services/chat/enviar_mensagem_chat_service.py` |
| Sessões e histórico | `backend/services/chat/*`, `models/chat_session.py`, `models/message.py` |
| IA | `backend/services/ia/ai_service.py` |
| Classificação | `services/ia/intent_classifier.py` |
| Extração de dados | `services/ia/entity_extractor.py` |
| Payload/plano | `services/ia/payload_builder.py`, `services/automation/pipeline_service.py` |
| Componentes que a IA pode solicitar | `services/ia/ui_components_library.py`, `frontend/lib/components/ai_components/` |

### Intenções, componentes e continuação

`AIService` primeiro distingue conversa simples de ações. Quando faltam dados ou a ação exige confirmação, a resposta pode voltar com `status: "requires_action"` e uma lista `components`. O Flutter usa `component_factory.dart` para renderizar itens como seleção de contatos, data/hora, edição de preview, aprovação, checklist ou escolha de arquivo.

Após a interação, o app envia `POST /chat/message/continue`. O backend reaproveita o histórico/metadados para não perder a intenção original. Quando o status chega a `completed`, a UI trata o fluxo como concluído.

### Cotas e planos

Antes de conversar, `VerificarQuotaService` consulta o perfil. O perfil registra `subscription_tier`, limite mensal, créditos usados e créditos acumulados. A IA seleciona, por padrão:

| Plano | Configuração de modelo | Limite mensal em `BillingService` |
|---|---|---:|
| Basic | `MODEL_TIER_BASIC` (padrão Groq) | 500 |
| Pro | `MODEL_TIER_PRO` (padrão Gemini Flash) | 7.500 |
| Max | `MODEL_TIER_MAX` (padrão Gemini Pro) | 25.000 |

## 9. Fluxo de automações

Há dois caminhos: uma automação criada diretamente na tela de automações, ou uma automação criada a partir da linguagem natural no chat.

```text
Pedido em linguagem natural
  → AutomationPipelineService gera/valida o plano
  → CriarAutomationService salva a definição em automations
  → dispatch_automation cria uma AutomationRun durável
  → POST WORKER_URL/execute com X-Worker-Secret
  → worker/server.py aceita (202) e cria thread
  → AutomationRunner resolve variáveis e executa os steps
  → worker/repositorio_dados.py atualiza status e AutomationStepLog
  → frontend consulta runs/logs e apresenta o progresso
```

### Entidades de automação

| Entidade | Para que serve |
|---|---|
| `Automation` | Receita reutilizável: nome, descrição, gatilho, passos, status, versão e próxima execução. |
| `AutomationRun` | Uma tentativa concreta de executar a receita: status, tipo, entrada, saída, erro e tempos. |
| `AutomationStepLog` | Log por passo: módulo, índice, status e resultado. |
| `AutomationGenerationLog` | Auditoria da IA que gerou um plano: intenção, tentativas, erros, plano final, modelo e tokens. |
| `ExecutionLog` | Registro legado/auxiliar para ações executadas pelo chat. |
| `UserWebhookConfig` | Configuração de recebimento por webhook, com slug, segredo HMAC e mapeamento de payload. |

### Formato de um plano

`backend/models/automation_plan_schema.py` valida um `AutomationPlan` com nome, descrição, contexto, gatilho e lista ordenada de passos. Cada passo possui `step_id`, `module_id`, `params` e descrição. IDs duplicados são rejeitados.

Gatilhos possíveis no schema: `manual`, `cron`, `webhook` e `schedule`.

Os valores de um passo podem usar variáveis como `{{trigger.email}}` ou `{{step_1.response}}`. `worker/utils/resolver.py` resolve essas expressões antes da execução.

### Módulos registrados no worker

| Categoria | IDs implementados |
|---|---|
| IA | `ai.transform_data` |
| Fluxo | `flow.wait` |
| Gmail | `gmail.send_email`, `gmail.create_draft`, `gmail.get_unread_emails` |
| Google Calendar | `google_calendar.create_event`, `list_events`, `update_event`, `delete_event` |
| Google Drive | `google_drive.list_files`, `upload_file`, `get_file_content`, `create_folder` |
| Google Sheets | `google_sheets.append_row`, `get_values`, `update_values`, `create_spreadsheet` |
| HTTP | `http.request` |
| Relatórios | `report.generate_pdf` |

O registro é feito por `@register_module(...)` em `backend/worker/modules/`. Para adicionar um conector, criar um módulo assíncrono, decorá-lo, importá-lo em `modules/__init__.py` e atualizar a IA/catálogo se necessário.

### Automação de relatório em PDF

Para um pedido como “gere um relatório semanal das vendas da minha planilha”, o pipeline pode ordenar os módulos `google_sheets.get_values` → `ai.transform_data` → `report.generate_pdf`. O último passo analisa até 200 linhas, calcula total e média, cria um gráfico de barras, monta o PDF com ReportLab e o salva na biblioteca do usuário. O PDF não é enviado na resposta do chat: ele fica persistido para download na tela **Relatórios**.

### Execução manual, agendada e recorrente

- **Manual:** `POST /automations/<id>/run` valida propriedade, cria a run e chama o worker.
- **Agendada/cron:** `POST /automations/<id>/schedule` atualiza o gatilho; o processo `scheduler.py` roda a cada 15 segundos e dispara automações `active` com `next_run_at` vencido.
- **Webhook:** a infraestrutura de configuração está em `UserWebhookConfig` e o runner possui `trigger_automation_from_webhook`; a rota pública específica de recebimento não aparece registrada em `routes.py` neste estado do código.
- **Revisão por linguagem natural:** `POST /automations/<id>/revise` chama `RevisarAutomationService` e preserva o escopo do dono.

## 10. Banco de dados: entidades e relações

O desenvolvimento local usa `backend/instance/catas_dev.db` quando `DATABASE_URL` não é definido. A produção é orientada a PostgreSQL. As migrations e procedimentos ficam em `backend/migrations/`; use o conjunto compatível com o banco escolhido.

| Tabela/modelo | Papel e relações principais |
|---|---|
| `users` / `User` | Credenciais locais: e-mail único e hash de senha. |
| `profiles` / `Profile` | Plano, cota, idioma, onboarding e dados Stripe; é a identidade usada pela maioria das relações. |
| `chat_sessions` / `ChatSession` | Conversa de uma pessoa; possui título e flag de onboarding. |
| `messages` / `Message` | Mensagens de uma sessão; `role`, conteúdo e metadados JSON. |
| `automations` / `Automation` | Definições dos fluxos do usuário. |
| `automation_runs` / `AutomationRun` | Execuções vinculadas à automação e ao usuário. |
| `automation_step_logs` / `AutomationStepLog` | Resultado de cada etapa de uma run. |
| `automation_generation_logs` / `AutomationGenerationLog` | Auditoria do planejamento com IA. |
| `execution_logs` / `ExecutionLog` | Histórico auxiliar de execução e sugestões. |
| `integrations` / `Integration` | Provider, conexão, tokens OAuth, expiração e configurações. |
| `attachments` / `Attachment` | Nome original, caminho, tipo, tamanho e dono do arquivo. |
| `notifications` / `Notification` | Avisos, ação opcional, metadados e leitura. |
| `message_feedback` / `MessageFeedback` | Curtida/não curtida e justificativa de mensagens. |
| `ia_suggestions` / `AiSuggestion` | Sugestões geradas a partir de contexto de página. |
| `ia_memory` / `IaMemory` | Memória do usuário, conteúdo, embedding e metadados. |
| `page_contexts` / `PageContext` | URL, domínio, título e resumo da página observada. |
| `browser_sessions` / `BrowserSession` | Sessão de navegador e atividade recente. |
| `page_analysis_cache` / `PageAnalysisCache` | Cache por hash de URL, resultado e expiração. |
| `user_devices` / `UserDevice` | Token FCM, plataforma e último acesso. |
| `user_webhook_configs` / `UserWebhookConfig` | Webhooks associados opcionalmente a uma automação. |
| `termos_aceite` / `TermoAceite` | Evidência de aceite, versão, origem e data. |
| `generated_reports` / `GeneratedReport` | PDF de automação, resumo, origem, métricas e ligações com automação/run; o binário é omitido nas listagens e baixado apenas pelo dono. |

## 11. Integrações externas

### IA

- As chaves ficam em `OPENAI_API_KEY`, `GOOGLE_API_KEY` e `GROQ_API_KEY`.
- A seleção do provedor/modelo é configurada em `backend/core/config.py`.
- `AIService` classifica, extrai entidades, gera resposta e define componentes de UI.
- `AutomationPipelineService` transforma pedidos de automação em um workflow validado.

### Google Workspace

- O início do OAuth é `GET /integrations/google/auth-url?provider=<provider>`.
- O retorno é `GET /integrations/google/callback`.
- Tokens ficam em `integrations` e são criptografados por `core/crypto.py`.
- `core/oauth_token_service.py` e `worker/utils/google_auth.py` apoiam refresh e uso das credenciais.
- Os módulos atuais cobrem Gmail, Calendar, Drive e Sheets.
- Google Sheets aceita URL ou ID válido da planilha, rejeita identificadores fictícios e consegue criar uma planilha com cabeçalhos coloridos.
- Antes de apresentar ou executar uma ação externa, `IntegrationAccessService` verifica se o provider necessário está conectado e ativo no chat. Caso contrário, o frontend recebe um componente para conectar/ativar a integração; nenhuma ação é executada.

### Stripe

1. A tela de preços pede `POST /billing/checkout`.
2. O backend cria uma Stripe Checkout Session e devolve a URL.
3. O retorno para `/app/payment-success?session_id=...` chama `GET /billing/checkout-session/<id>` autenticado; a API confere se a sessão pertence ao perfil atual antes de sincronizar o plano.
4. Depois do pagamento, o Stripe também chama `POST /billing/webhook`.
5. A assinatura do evento é validada e o webhook reconcilia status, plano e cota em `profiles`.
6. `POST /billing/portal` abre o Customer Portal para troca ou cancelamento.

### Firebase

- `application.py` inicializa Firebase Admin se as credenciais estiverem disponíveis.
- `main.dart` inicializa Firebase no app nativo e registra o handler de mensagens em background.
- `user_devices` armazena tokens FCM; `notifications` preserva os avisos no banco.

## 12. Arquivos, anexos e contexto nativo

- O envio/listagem/remoção está no `AttachmentController` e em `services/storage/attachment_service.py`.
- O frontend usa `PickedAttachment`, `attachment_bottom_sheet.dart` e `attachments_screen.dart` para selecionar e visualizar documentos/imagens.
- O layout principal também aceita arrastar arquivos no desktop.
- `core/context/` e `NativeContextProvider` organizam informações do ambiente, como página atual. Esse contexto pode acompanhar a mensagem como URL e título atuais.
- `page_contexts`, `browser_sessions` e `page_analysis_cache` são a infraestrutura persistida desse recurso.

## 13. Relatórios e métricas

| Recurso | Backend | Interface |
|---|---|---|
| Dashboard | `GerarEstatisticasDashboardService`, `DashboardRepository` | `ImpactDashboardScreen`, cards e `productivity_chart.dart` |
| Biblioteca de PDFs | `RelatoriosGeradosService`, `GeneratedReport` | `ReportsScreen` em `/app/relatorios` |
| Relatório de automações | `GerarRelatorioAutomacoesService`, `AutomacaoRepository` | `DataExportScreen` em `/app/settings/export` |
| Relatório de chat | `GerarRelatorioChatService`, `ChatRepository` | `DataExportScreen` em `/app/settings/export` |
| Busca de mensagens | `BuscarMensagensService` | Filtros de `DataExportScreen` |
| Exportação analítica | `ExportarRelatorioService` | `report_export_menu.dart` e entrega web |

Existem dois conceitos diferentes que não devem ser confundidos:

- **Relatório analítico/exportado:** consulta dados já persistidos de chat ou automações e exporta CSV, XLSX ou PDF. A tela fica em **Configurações > Exportar dados**.
- **Relatório gerado por automação:** o worker lê dados, calcula indicadores, desenha gráfico e cria um PDF. Ele é salvo em `generated_reports` e aparece em **Relatórios** (`/app/relatorios`).

Os formatos suportados e a geração são testados em `backend/tests/test_export_billing_attachments.py`; há testes para CSV, Excel e PDF.

## 14. Variáveis de ambiente essenciais

Nunca colocar valores reais ou chaves no repositório.

| Grupo | Variáveis |
|---|---|
| Ambiente e banco | `ENVIRONMENT`, `DATABASE_URL`, `JWT_SECRET_KEY`, `JWT_EXPIRATION_SECONDS` |
| IA | `OPENAI_API_KEY`, `GOOGLE_API_KEY`, `GROQ_API_KEY`, `AGENT_*`, `MODEL_TIER_*` |
| Worker | `WORKER_URL`, `WORKER_SHARED_SECRET` |
| Google | `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `WEB_CLIENT_ID`, `ANDROID_CLIENT_ID`, `IOS_CLIENT_ID` |
| Stripe | `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `BASIC_PLAN_ID`, `PRO_PLAN_ID`, `MAX_PLAN_ID`, `FRONTEND_URL` |
| Firebase | `FIREBASE_ADMIN_CREDENTIALS_JSON` ou `FIREBASE_ADMIN_SDK_JSON_PATH` |
| Upload | `ATTACHMENTS_MAX_SIZE_BYTES`, credenciais Cloudinary no frontend, quando usado |
| Flutter | `API_BASE_URL`, `DEMO_MODE` e os client IDs Google |

## 15. Como executar e testar

### Desenvolvimento local

```powershell
# Terminal 1 — API
cd backend
python -m venv venv
.\venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
python run.py

# Terminal 2 — worker
cd backend
.\venv\Scripts\Activate.ps1
python -m worker.server

# Terminal 3 — Flutter web
cd frontend
flutter pub get
flutter run -d chrome --web-port 52159
```

### Verificações

```powershell
# Backend
cd backend
python -m pytest tests/ -v
ruff check .
ruff format .

# Frontend
cd frontend
flutter test
```

Os testes backend cobrem autenticação, entidades, chat, IA, créditos, relatórios, anexos, billing, termos, scheduler, OAuth Google e worker. Arquivos relevantes: `backend/tests/test_automation_todo.py`, `test_export_billing_attachments.py`, `test_chat_flow.py`, `test_google_integration_redirect.py` e `test_worker_runner.py`.

O repositório **não contém mais Dockerfile ou Docker Compose**. Se a equipe precisar demonstrar com containers, deverá recriar e validar esses arquivos antes de usar esse caminho.

## 16. Como explicar o projeto na apresentação

### Roteiro de 60 segundos

1. “O CATAS é um assistente de automação por linguagem natural.”
2. “O usuário conversa pelo app Flutter, que funciona em web e plataformas nativas.”
3. “A API Flask autentica, controla plano e cotas, guarda dados e usa IA para entender a intenção.”
4. “Quando existe uma ação, a API gera uma receita de passos e manda para um worker independente.”
5. “O worker executa módulos como Gmail, Google Calendar, Drive e Sheets, registra cada etapa e o app mostra o resultado.”
6. “Também temos agendamento, relatórios, anexos, integrações OAuth, notificações e pagamento via Stripe.”

### Perguntas frequentes e respostas objetivas

| Pergunta | Resposta |
|---|---|
| Por que separar API e worker? | Para a resposta HTTP não ficar presa em tarefas demoradas. A API orquestra e registra; o worker executa em segundo plano. |
| Onde a IA está? | Principalmente em `backend/services/ia/`. Ela classifica a intenção, extrai dados e produz a resposta/plano. |
| Como a automação sabe a saída do passo anterior? | O `VariableResolver` troca referências como `{{step_1.response}}` pelo valor presente no contexto da execução. |
| Como impedem que uma pessoa acesse dados de outra? | JWT, decorator `login_required` e filtros por `g.current_user['id']` nos controllers/services. |
| Como acompanham a execução? | `AutomationRun` registra a tentativa; `AutomationStepLog` registra cada etapa. A interface consulta esses recursos. |
| Como funciona automação recorrente? | A definição salva `trigger` e `next_run_at`; o scheduler verifica a cada 15 segundos o que venceu e despacha uma run. |
| Como a pessoa conecta Google? | Pelo fluxo OAuth. Tokens de acesso e refresh são criptografados e associados ao provider/usuário. |
| Como cobram? | Stripe Checkout cria a assinatura; o retorno confirma a sessão para o mesmo perfil e o webhook validado reconcilia plano e cota. |
| Onde ficam os PDFs gerados? | Em `generated_reports`, associados ao usuário, à automação e à execução; a biblioteca em `/app/relatorios` lista e baixa apenas os relatórios do dono. |
| O sistema guarda conversa? | Sim. `chat_sessions` organiza a conversa e `messages` preserva mensagens e metadados. |
| O que acontece se o worker cair? | A execução é marcada como `failed`, com erro persistido; a interface pode informar o problema e permitir nova tentativa. |

## 17. Atenções técnicas antes da entrega

Estas observações são importantes para a equipe responder com precisão e priorizar uma revisão final:

1. **O código atual do worker usa Flask, não FastAPI.** `backend/worker/server.py` importa e cria `Flask`. README e documentos antigos ainda o chamam de FastAPI/uvicorn.
2. **A fonte de verdade das rotas é `backend/routes.py`.** Alguns arquivos em `docs/` citam rotas antigas, como `/payments/*`, `/execute/action` e endpoints de webhook diferentes. As rotas atuais de cobrança são `/api/v1/billing/*`.
3. **O caminho real do frontend é `frontend/`.** Algumas documentações antigas chamam a pasta de `app_flutter/`.
4. **Banco:** SQLite é o fallback local da API; a produção é orientada a PostgreSQL. A equipe deve escolher e documentar uma configuração oficial para a banca, especialmente nas migrations.
5. **Infraestrutura de containers foi removida.** Não há `Dockerfile`, `Dockerfile.worker` ou `docker-compose.yml` no estado atual. A demonstração deve seguir a execução local, salvo se a equipe recriar e testar a infraestrutura.
6. **`core/config.py` exige `OPENAI_API_KEY` na inicialização**, mesmo que os defaults de modelos usem Groq/Gemini. Para iniciar sem erro, a chave precisa estar definida ou essa validação precisa ser alinhada à estratégia escolhida.
7. **Webhook de usuário:** existe modelo/configuração e suporte no runner, mas não há rota pública de recebimento registrada no estado atual. Não apresentem como fluxo totalmente disponível sem validar/implementar esse endpoint.
8. **Há uma auditoria de integrações em `auditoria_integracoes.py`.** Ela combina uma chamada HTTP pública com simulações dos conectores Google; é útil para regressão, mas não substitui teste real com conta Google e chave de IA configuradas.
9. **Segredos não devem ser versionados nem projetados.** Confiram `.gitignore`, usem `.env.example` sem valores reais e rotacionem qualquer credencial que tenha sido compartilhada fora do ambiente seguro.
10. **Documentação precisa ser atualizada depois de mudanças.** Use este arquivo e `routes.py` como referência de defesa; depois, alinhem `docs/` para evitar divergências.

## 18. Onde alterar cada tipo de funcionalidade

| Se precisar alterar... | Comece por... | Depois confira... |
|---|---|---|
| Uma rota/endpoint | `backend/routes.py` | Controller, service e testes. |
| Regra de negócio | `backend/services/<domínio>/` | Model e controller correspondente. |
| Tabela/campo novo | `backend/models/` | Migration SQL, `models/__init__.py`, service/controller/rota. |
| Tela ou URL | `frontend/lib/core/router.dart` | Screen, layouts e `NavigationProvider`. |
| Estado de uma tela | `frontend/lib/providers/` | Repositório em `frontend/lib/data/`. |
| Aparência reutilizável | `frontend/lib/components/` | Tema e responsividade. |
| Mensagem e comportamento da IA | `backend/services/ia/` | `EnviarMensagemChatService` e componentes de UI. |
| Novo conector/ação externa | `backend/worker/modules/` | Registro, OAuth, catálogo/pipeline e teste do worker. |
| Plano/preço/cota | `services/billing/billing_service.py`, `models/profile.py` | Tela de preços e webhook Stripe. |
| Biblioteca de PDFs automáticos | `worker/modules/report_modules.py` | `GeneratedReport`, `RelatoriosGeradosService`, `ReportsScreen` e `GeneratedReportsProvider`. |
| Dados analíticos/exportação | `services/relatorio/` e `repositories/` | `DataExportScreen`, `RelatorioProvider` e `report_export_menu.dart`. |

---

## Conclusão

O CATAS é estruturado para separar interface, inteligência, regras de negócio e execução externa. O Flutter concentra a experiência; Flask concentra a API, segurança e orquestração; o worker executa tarefas potencialmente lentas; e o banco fornece rastreabilidade de conversas, planos e automações. Essa separação é a principal justificativa arquitetural do projeto.
