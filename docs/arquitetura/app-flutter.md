# Estrutura do App Flutter

O cliente CATAS é um aplicativo **Flutter** multiplataforma (Android, iOS, Windows, Web), localizado em `app_flutter/`.

## Diretórios e Arquivos

```
app_flutter/
├── lib/
│   ├── main.dart              # Ponto de entrada, providers, AuthWrapper
│   ├── core/
│   │   └── theme.dart         # Tema Material 3 (Zinc/Slate)
│   ├── data/
│   │   └── repositories/      # chat_repository, billing_repository, etc.
│   ├── providers/
│   │   ├── auth_provider.dart     # Google/Apple Sign-In + Supabase
│   │   ├── chat_provider.dart     # Estado do chat, streaming de mensagens
│   │   └── notification_provider.dart # Sistema de notificações interno
│   ├── screens/
│   │   ├── auth/
│   │   │   └── login_screen.dart  # Login (Google + Apple)
│   │   ├── chat/
│   │   │   └── chat_screen.dart   # Chat principal
│   │   ├── dashboard/
│   │   │   └── impact_dashboard.dart # Dashboard de impacto (Stats)
│   │   ├── settings/
│   │   │   └── settings_screen.dart
│   │   └── integrations/
│   │       └── integrations_list.dart
│   └── components/            # Componentes reutilizáveis (UI)
├── assets/
│   └── logos/
├── .env / .env.production      # Variáveis de ambiente
└── pubspec.yaml
```

## Providers

| Provider          | Responsabilidade                                                                            |
| ----------------- | ------------------------------------------------------------------------------------------- |
| **AuthProvider**       | Sessão Supabase, `loginWithGoogle()`, `logout()`, estado `isAuthenticated`                  |
| **ChatProvider**       | Lista de mensagens, `sendMessage()`, rascunhos, anexos, persistência local                  |
| **NavigationProvider** | Gerencia a página atual (`AppPage`) e persiste a última navegação no mobile               |
| **ThemeProvider**      | `themeMode` (light/dark/system)                                                             |

## Fluxo de Autenticação

1. **AuthWrapper**: Decide entre `MainLayout` ou `LoginScreen`.
2. **LoginScreen**: Suporte a **Google OAuth** (Android/iOS/Web) e **Apple Sign-In** (iOS/macOS).
3. **AuthProvider**: Gerencia o `Session` do Supabase e vincula metadados do perfil (Avatar, Nome).
4. O token `JWT` é injetado automaticamente em todas as requisições via interceptor no `ChatRepository`.

## ChatRepository

- **sendMessage(sessionId, text)**: POST para `{API_BASE_URL}/chat/message` com payload `{ message, conversation_id }`.
- Base URL: `API_BASE_URL` do `.env` ou `http://10.0.2.2:8000/api/v1` (Android Emulator).
- Token: `Supabase.instance.client.auth.currentSession?.accessToken ?? "dev-token"`.

## Telas

| Tela                   | Descrição                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------- |
| **LoginScreen**        | Login com Google, layout centralizado com gradiente                                         |
| **MainLayout**         | Drawer lateral, atalhos (Automações, Integrações), lista de chats (mock), footer com perfil |
| **ChatScreen**         | Lista de mensagens, input estilo omnibox, Action Cards para `actionTriggered`               |
| **AutomationsScreen**  | Placeholder para automações ativas                                                          |
| **IntegrationsScreen** | Listagem de serviços conectáveis (Google, Notion, etc)                                      |
| **IntegrationDetails** | Detalhes de permissões, configuração e desconexão de um serviço específico                  |
| **SettingsScreen**     | Configurações do app                                                                        |
| **HistoryScreen**      | Histórico de conversas (placeholder)                                                        |

## Modelo de Mensagem (ChatProvider)

```dart
class Message {
  final String text;
  final bool isUser;
  final bool isHidden; // Oculta mensagem visualmente
  final bool actionTriggered;
  final Map<String, dynamic>? actionDetails;
  final List<dynamic>? components; // Componentes dinâmicos da IA
  final String status; // 'idle', 'requires_action', 'completed'
  final DateTime timestamp;
}
```

As mensagens com `status: 'requires_action'` não exibem botões de feedback ou ações de cópia/compartilhamento até que o fluxo seja completado.

## Variáveis de Ambiente (.env)

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `API_BASE_URL` (ex: `http://10.0.2.2:8000/api/v1` para Android Emulator)
- `WEB_CLIENT_ID` (Google OAuth Web)
- `ANDROID_CLIENT_ID` (Google OAuth Android)
- `IOS_CLIENT_ID` (Google OAuth iOS)

## Padrões de Interface e UX

O app utiliza Material 3 com foco em design **Glassmorphism** e **Dark Mode** nativo:

- **MenuAnchor (Popup Menus)**: Substituímos o uso excessivo de `BottomSheets` por menus de contexto rápidos (MenuAnchor) acionados por clique ou long-press (ex: histórico de chat, ações de mensagem).
- **Streaming UI**: O chat utiliza `StreamBuilder` ou `StateNotifier` para processar respostas parciais da IA (Streaming de tokens), oferecendo uma experiência similar ao ChatGPT.
- **Impact Dashboard**: Uma visualização rica em gráficos (`fl_chart`) que mostra ao usuário o impacto das suas automações (tempo economizado, tarefas executadas, etc.).
- **Impacto Retroativo**: Animações suaves (`flutter_animate`) ao carregar novos cards de automação.
- **Skeletonizer**: Shimmer em todas as listas enquanto os dados são buscados no Supabase.

## Dependências Principais

- `supabase_flutter` — Auth e banco
- `google_sign_in` — Login com Google
- `provider` — Estado global
- `http` — Requisições à API
- `flutter_dotenv` — Carregar `.env`
- `google_fonts` — Tipografia
- `flutter_animate` — Animações
- `skeletonizer` — Estados de carregamento shimmer
- `intl` — Formatação de datas e moedas

## Como Rodar

```powershell
cd app_flutter
flutter pub get
flutter run -d windows   # ou chrome, android
```

Para Android Emulator, certifique-se de que `API_BASE_URL` aponte para `http://10.0.2.2:8000/api/v1` (localhost do host).
