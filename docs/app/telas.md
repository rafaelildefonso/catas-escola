# Telas do Aplicativo (Screens)

O aplicativo CATAS é construído com Flutter e segue os princípios do **Material Design 3**, com uma interface limpa e focada em produtividade.

## 1. Tela de Chat (`ChatScreen`)

A interface principal onde ocorre a interação com o agente.

- **Omnibox**: Campo de entrada inteligente que suporta texto e anexos.
- **Micro-interações**: Indicadores de estágio de pensamento (Raciocinando, Planejando, Executando).
- **Ações Rápidas (Popup Menus)**: Long-press em mensagens ou sessões abre menus de contexto (MenuAnchor) para copiar, excluir ou renomear, eliminando a poluição visual de botões fixos.
- **Action Cards (Validated Plans)**: Após o "Pensamento" da IA, um plano de automação (Maestro) é apresentado para revisão. O usuário valida os passos antes da execução no Worker.
- **Anexos**: Draggable e restauráveis entre sessões.

---

## 2. Histórico de Conversas (`HistoryScreen`)

Lista todas as sessões de chat salvas no Supabase.

- **Títulos Inteligentes**: Os títulos são gerados automaticamente pela IA com base na primeira mensagem.
- **Gestão**: Permite renomear ou excluir sessões antigas.
- **Sincronização**: Carregamento em tempo real do banco de dados.

---

- **`ImpactDashboard`**: Visualização central com métricas de uso:
  - **Tempo Economizado**: Estimativa de ganho de produtividade.
  - **Tarefas Concluídas**: Contador de automações executadas.
  - **Gráficos de Consumo**: Visualização de créditos (tokens) usados no período.
- **`IntegrationsScreen`**: Gerencia as conexões globais. Mostra o status de conexão em tempo real e permite revogar tokens.
- **`LoginScreen`**: Layout minimalista com suporte a **Google Sign-In** e **Apple ID**.
- **`SettingsScreen`**: Alternância de tema (Light/Dark), idioma e preferências de notificação.

---

## 4. Telas de Suporte

- **`AboutScreen`**: Informações sobre a versão do app e créditos.
- **`HelpScreen`**: Guia rápido de uso e perguntas frequentes.
- **`SubscriptionSuccessScreen`**: Tela de celebração e confirmação após um upgrade de plano bem-sucedido.

---

## 5. Contexto Nativo (Native Context)

Funcionalidade que permite ao agente capturar informações do ambiente do usuário para automatizações mais precisas:

- **Browser URL**: Captura a URL ativa do navegador (Chrome, Edge) se o app estiver rodando com permissões de acessibilidade.
- **App de Primeiro Plano**: Identifica qual aplicativo o usuário está utilizando no momento.
- **Detecção Automática**: Quando o usuário envia uma mensagem como "resuma esta página", o app injeta automaticamente o `currentPageUrl` no payload da mensagem.
