# Flutter Developer Guide

> 👨‍💻 **Você está em:** `app_flutter/`  
> 📱 **Stack:** Flutter 3.19+, Dart 3.3+, Provider

---

## 🎯 O que você precisa saber

O CATAS é um **app de chat com automação**. O usuário digita em linguagem natural ("marcar reunião amanhã às 14h"), e o sistema:

1. Entende a intenção (criar evento)
2. Extrai dados (data, hora, participantes)
3. Mostra um preview interativo
4. Executa a ação (cria no Google Calendar)

**Tudo em tempo real**, com streaming de status da automação.

---

## 🗺️ Mapa Mental da Arquitetura

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
│  ├── ChatProvider          ← Lógica do chat           │
│  ├── AuthProvider          ← Login, perfil, créditos  │
│  └── ThemeProvider         ← Tema claro/escuro          │
├─────────────────────────────────────────────────────────┤
│  Data Layer (Repositories)                              │
│  ├── ChatRepository        ← HTTP para API            │
│  └── Supabase realtime     ← Streaming status           │
└─────────────────────────────────────────────────────────┘
```

---

## 📂 Estrutura de Pastas

```
app_flutter/lib/
├── components/                    # 🧩 Widgets reutilizáveis
│   ├── ai_components/              # Componentes da IA
│   │   ├── action_approval.dart   # Botão aprovar/rejeitar
│   │   ├── contact_select.dart    # Seletor de contatos
│   │   ├── multiple_choice.dart   # Opções múltiplas
│   │   └── preview_*.dart         # Previews de ação
│   ├── chat_bubble.dart           # Balão de mensagem
│   ├── markdown_viewer.dart       # Render Markdown
│   └── typing_indicator.dart      # "IA está digitando"
│
├── core/                          # ⚙️ Configurações
│   ├── router.dart                # Rotas (GoRouter)
│   ├── theme.dart                 # Cores, tipografia
│   └── app_config.dart            # Variáveis de ambiente
│
├── data/                          # 📡 Acesso a dados
│   ├── chat_repository.dart       # API de chat
│   ├── chat_repository_interface.dart
│   └── demo_repository.dart       # Modo offline
│
├── l10n/                          # 🌍 Internacionalização
│   └── app_localizations_*.dart   # PT, EN, ES
│
├── models/                        # 📦 Classes de dados
│   ├── message.dart               # Mensagem do chat
│   ├── chat_session.dart          # Sessão
│   └── user_profile.dart          # Perfil + créditos
│
├── providers/                     # 🔄 State Management
│   ├── auth_provider.dart         # Autenticação
│   ├── chat_provider.dart         # Chat + automações
│   ├── theme_provider.dart        # Tema
│   └── navigation_provider.dart   # Navegação
│
├── screens/                       # 📱 Telas
│   ├── web/                       # Layout desktop
│   ├── mobile/                    # Layout mobile
│   └── chat_screen.dart           # Tela principal
│
└── main.dart                      # 🚀 Entrypoint
```

---

## 🚀 Primeiras Tarefas

Escolha por objetivo:

| Eu quero... | Guia |
|-------------|------|
| 🆕 Entender como funciona o chat | [Fluxo do Chat](./chat-flow.md) |
| ➕ Adicionar novo componente de UI | [AI Components](./ai-components.md) |
| 🎨 Modificar tema/cores | [Theming](./theming.md) |
| 🔄 Adicionar novo provider | [Providers](./providers.md) |
| 📱 Criar nova tela | [Screens](./screens.md) |
| 🧪 Escrever testes | [Testing](./testing.md) |

---

## 💡 Conceitos Chave

### 1. Componentes de IA

A IA retorna componentes dinâmicos no JSON:

```json
{
  "components": [
    {
      "type": "contact_select",
      "label": "Quem deve ser convidado?"
    },
    {
      "type": "action_approval",
      "label": "Agendar reunião?"
    }
  ]
}
```

O Flutter renderiza automaticamente baseado no `type`.

**Localização:** `components/ai_components/`

### 2. Realtime Status

Automações enviam status em tempo real via Supabase Realtime:

```dart
// ChatProvider
_supabase
  .channel('automation_steps')
  .onPostgresChanges(...)
  .subscribe();
```

Isso mostra "Criando evento...", "Concluído", etc.

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

## 🔧 Configurações Importantes

### Variáveis de Ambiente (.env)

```env
SUPABASE_URL=                    # URL do projeto Supabase
SUPABASE_ANON_KEY=               # Chave pública (safe para client)
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
| **Web** | `web/index.html` - Configuração de base href |
| **Windows** | `windows/runner/main.cpp` - Janela nativa |

---

## 📚 Tópicos Detalhados

### Fundamentos
- [Estrutura do Projeto](./estrutura.md) - Deep dive nas pastas
- [State Management](./providers.md) - Como usar Provider
- [Navegação](./navigation.md) - GoRouter e deep links
- [Dependências](./dependencies.md) - Packages principais

### UI/UX
- [Componentes de IA](./ai-components.md) - Biblioteca de componentes
- [Theming](./theming.md) - Cores, fontes, modo escuro
- [Responsividade](./responsive.md) - Web vs Mobile
- [Animações](./animations.md) - Transições e micro-interações

### Dados
- [Modelos](./models.md) - Classes de dados
- [Repositories](./repositories.md) - HTTP e cache
- [Realtime](./realtime.md) - Supabase streaming
- [Offline Mode](./offline.md) - Demo mode

### Avançado
- [Autenticação](./auth-flow.md) - Fluxo completo
- [Testes](./testing.md) - Unit, widget, integration
- [Performance](./performance.md) - Otimizações
- [Build & Deploy](./deploy.md) - Produção

---

## 🔗 Links Rápidos

| Recurso | Local |
|---------|-------|
| 📁 Código | `app_flutter/lib/` |
| 🧪 Testes | `app_flutter/test/` |
| 🎨 Assets | `app_flutter/assets/` |
| ⚙️ Config | `app_flutter/.env` |

---

## 🆘 Precisa de ajuda?

1. **Erro de build?** → `flutter doctor` e verifique dependências
2. **API não responde?** → Verifique `API_BASE_URL` no `.env`
3. **Componente não renderiza?** → [Debugging UI](./debugging-ui.md)

---

> ⬅️ [Voltar para Documentação](../index.md)  
> ➡️ [Próximo: Estrutura do Projeto →](./estrutura.md)
