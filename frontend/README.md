# CATAS Flutter App

Aplicativo cross-platform (iOS, Android, Web, Desktop) para automação de tarefas com IA.

## 📱 Funcionalidades

- 🤖 Chat com IA (Gemini, Claude, GPT-4)
- 📅 Automação de calendário (Google Calendar)
- 📧 Integração com Gmail
- 📊 Dashboard de impacto e créditos
- 🔐 Autenticação (Google, Apple, Email, Magic Link)
- 🌍 Multi-idioma (PT, EN, ES)
- 🔔 Notificações push (Firebase)
- 📎 Anexos e contexto nativo

## 🚀 Primeiros Passos

### Pré-requisitos

- Flutter 3.19+ 
- Dart 3.3+
- Android Studio / Xcode (para mobile)
- Conta no [Supabase](https://supabase.com)

### Instalação

```bash
cd app_flutter

# Instalar dependências
flutter pub get

# Configurar variáveis de ambiente
cp .env.example .env
# Editar .env com suas credenciais

# Rodar o app
flutter run
```

### Estrutura do Projeto

```
lib/
├── components/       # Widgets reutilizáveis e componentes de UI
├── core/              # Configurações, temas, rotas
├── data/              # Repositórios e datasources
├── models/            # Classes de dados
├── providers/         # State management (Provider)
├── screens/           # Telas da aplicação
├── services/          # Serviços externos
└── utils/             # Helpers e utilitários
```

## ⚙️ Configuração

Crie um arquivo `.env` na raiz do `app_flutter/`:

```env
# === SUPABASE ===
SUPABASE_URL=sua_url_do_supabase
SUPABASE_ANON_KEY=sua_anon_key

# === OAUTH GOOGLE ===
WEB_CLIENT_ID=seu_web_client_id
ANDROID_CLIENT_ID=seu_android_client_id
IOS_CLIENT_ID=seu_ios_client_id

# === API ===
API_BASE_URL=http://localhost:8000  # ou URL de produção

# === CLOUDINARY (opcional) ===
CLOUDINARY_CLOUD_NAME=nome_do_cloud

# === MODO DEMO ===
DEMO_MODE=false
```

## 🛠️ Comandos Úteis

```bash
# Rodar em modo debug
flutter run --debug

# Rodar em modo release
flutter run --release

# Build para produção
flutter build web      # Web
flutter build apk      # Android
flutter build ios      # iOS
flutter build windows  # Windows
flutter build macos    # macOS

# Testes
flutter test

# Análise de código
flutter analyze

# Formatar código
flutter pub run import_sorter:main
flutter format .
```

## 📦 Dependências Principais

- `supabase_flutter` - Backend e autenticação
- `provider` - State management
- `go_router` - Navegação
- `dio` - HTTP client
- `google_fonts` - Tipografia
- `flutter_dotenv` - Variáveis de ambiente
- `firebase_core` / `firebase_messaging` - Notificações

## 🔗 Links

- [Documentação completa](../PROJECT_CONTEXT.md)
- [Backend API](../server/README.md)
- [Setup Temporal](../server/docker/temporal/)

## 📝 Licença

Projeto acadêmico - CATAS (Context Aware Task Automation System)
