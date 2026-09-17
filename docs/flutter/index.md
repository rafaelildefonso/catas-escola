# Flutter Developer Guide

> **Voce esta em:** `frontend/`  
> **Stack:** Flutter 3.10.8+, Dart 3.3+, Provider

---

## O que voce precisa saber

O CATAS e um **app de chat com automacao**. O usuario digita em linguagem natural ("marcar reuniao amanha as 14h"), e o sistema:

1. Entende a intencao (criar evento)
2. Extrai dados (data, hora, participantes)
3. Mostra um preview interativo
4. Executa a acao (cria no Google Calendar)

**Tudo em tempo real**, com streaming de status da automacao.

---

## Mapa Mental da Arquitetura

```
┌─────────────────────────────────────────────────────────┐
│  UI Layer (Screens + Components)                        │
│  ├── screens/chat_screen.dart     ← Tela principal      │
│  ├── components/chat_bubble.dart  ← Mensagens           │
│  └── components/ai_components/    ← Componentes IA      │
│       ├── contact_select.dart                         │
│       ├── action_approval.dart                        │
│       └── preview_calendar_event.dart                 │
├─────────────────────────────────────────────────────────┤
│  State Layer (Providers)                                │
│  ├── ChatProvider          ← Logica do chat           │
│  ├── AuthProvider          ← Login, perfil, creditos  │
│  └── ThemeProvider         ← Tema claro/escuro          │
├─────────────────────────────────────────────────────────┤
│  Data Layer (Repositories)                              │
│  ├── ChatRepository        ← HTTP para API            │
│  └── Supabase realtime     ← Streaming status           │
└─────────────────────────────────────────────────────────┘
```

---

## Estrutura de Pastas

```
frontend/lib/
├── main.dart              # Entry point
├── components/            # 44 widgets reutilizaveis
│   ├── ai_components/     # 22 componentes IA
│   ├── dashboard/         # Metric cards, charts
│   └── ... (widgets gerais)
├── core/                  # Config, router, theme
│   ├── router.dart        # Rotas (GoRouter)
│   ├── theme.dart         # Cores, tipografia
│   └── app_config.dart    # Variaveis de ambiente
├── data/                  # Repositories e services
│   ├── chat_repository.dart
│   ├── automations_repository.dart
│   └── relatorio_repository.dart
├── l10n/                  # Internacionalizacao (PT/EN)
├── models/                # 6 modelos Dart
│   ├── chat_message.dart
│   ├── chat_session.dart
│   └── user_profile.dart
├── providers/             # 15 providers (state management)
│   ├── auth_provider.dart
│   ├── chat_provider.dart
│   ├── automations_provider.dart
│   └── theme_provider.dart
├── screens/               # 26 telas
│   ├── chat_screen.dart
│   ├── automations_screen.dart
│   ├── integrations_screen.dart
│   └── settings_screen.dart
└── services/              # Token holder
```

---

## Primeiras Tarefas

Escolha por objetivo:

| Eu quero... | Guia |
|-------------|------|
| Entender como funciona o chat | [Fluxo do Chat](./chat-flow.md) |
| Adicionar novo componente de UI | [AI Components](./ai-components.md) |
| Modificar tema/cores | [Theming](./theming.md) |
| Adicionar novo provider | [Providers](./providers.md) |
| Criar nova tela | [Screens](./screens.md) |
| Escrever testes | [Testing](./testing.md) |

---

## Conceitos Chave

### 1. Componentes de IA

A IA retorna componentes dinamicos no JSON:

```json
{
  "components": [
    {
      "type": "contact_select",
      "label": "Quem deve ser convidado?"
    },
    {
      "type": "action_approval",
      "label": "Agendar reuniao?"
    }
  ]
}
```

O Flutter renderiza automaticamente baseado no `type`.

**Localizacao:** `components/ai_components/`

### 2. Realtime Status

Automacoes enviam status em tempo real via Supabase Realtime:

```dart
// ChatProvider
_supabase
  .channel('automation_steps')
  .onPostgresChanges(...)
  .subscribe();
```

Isso mostra "Criando evento...", "Concluido", etc.

### 3. Fluxo de Mensagem

```
User Input → ChatProvider.sendMessage()
                ↓
           ChatRepository.sendMessage()
                ↓
           POST /api/v1/chat/message
                ↓
           Response com: text, components, action_details
                ↓
           UI renderiza mensagem + componentes
```

---

## Configuracoes Importantes

### Variaveis de Ambiente (.env)

```env
SUPABASE_URL=                    # URL do projeto Supabase
SUPABASE_ANON_KEY=               # Chave publica (safe para client)
API_BASE_URL=                    # http://localhost:8000
WEB_CLIENT_ID=                   # Google OAuth Web
ANDROID_CLIENT_ID=               # Google OAuth Android
IOS_CLIENT_ID=                   # Google OAuth iOS
```

### Platform-Specific

| Plataforma | Config especial |
|------------|-----------------|
| **Android** | `android/app/src/main/AndroidManifest.xml` - Adicionar scheme para deep links |
| **iOS** | `ios/Runner/Info.plist` - URL schemes |
| **Web** | `web/index.html` - Configuracao de base href |
| **Windows** | `windows/runner/main.cpp` - Janela nativa |

---

## Topicos Detalhados

### Fundamentos
- [Estrutura do Projeto](./estrutura.md) - Deep dive nas pastas
- [State Management](./providers.md) - Como usar Provider
- [Navegacao](./navigation.md) - GoRouter e deep links
- [Dependencias](./dependencies.md) - Packages principais

### UI/UX
- [Componentes de IA](./ai-components.md) - Biblioteca de componentes
- [Theming](./theming.md) - Cores, fontes, modo escuro
- [Responsividade](./responsive.md) - Web vs Mobile
- [Animacoes](./animations.md) - Transicoes e micro-interacoes

### Dados
- [Modelos](./models.md) - Classes de dados
- [Repositories](./repositories.md) - HTTP e cache
- [Realtime](./realtime.md) - Supabase streaming
- [Offline Mode](./offline.md) - Demo mode

### Avancado
- [Autenticacao](./auth-flow.md) - Fluxo completo
- [Testes](./testing.md) - Unit, widget, integration
- [Performance](./performance.md) - Otimizacoes
- [Build & Deploy](./deploy.md) - Producao

---

## Links Rapidos

| Recurso | Local |
|---------|-------|
| Codigo | `frontend/lib/` |
| Testes | `frontend/test/` |
| Assets | `frontend/assets/` |
| Config | `frontend/.env` |

---

## Precisa de ajuda?

1. **Erro de build?** → `flutter doctor` e verifique dependencias
2. **API nao responde?** → Verifique `API_BASE_URL` no `.env`
3. **Componente nao renderiza?** → [Debugging UI](./debugging-ui.md)

---

> [Voltar para Documentacao](../index.md)  
> [Proximo: Estrutura do Projeto →](./estrutura.md)
