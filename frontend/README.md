# CATAS Flutter App

Aplicativo cross-platform (iOS, Android, Web, Desktop) para automação de tarefas com IA.

## 📱 Funcionalidades

- 🤖 Chat com IA (Gemini, Claude, GPT-4)
- 📅 Automação de calendário (Google Calendar)
- 📧 Integração com Gmail
- 📊 Dashboard de impacto e créditos
- 📈 **Relatórios** — painel de estatísticas, relatório de execuções de automação (filtro/ordenação/paginação), relatório de conversas e busca de mensagens (`/app/relatorios`)
- 🔐 Autenticação (Google, Apple, Email, Magic Link)
- 🌍 Multi-idioma (PT, EN, ES)
- 🔔 Notificações push (Firebase)
- 📎 Anexos e contexto nativo

> O app consome a API Flask em `backend/`. As telas de relatório chamam `lib/data/relatorio_repository.dart` (rotas `GET /api/v1/relatorios/{dashboard,automacoes,chat,mensagens/busca}`) via `RelatorioProvider`.

## 🚀 Primeiros Passos

### Pré-requisitos

- Flutter 3.19+
- Dart 3.3+
- Android Studio / Xcode (para mobile)

### Instalação

```bash
# A partir da raiz do repositório
cd frontend

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
frontend/lib/
├── components/       # Widgets reutilizáveis e componentes de UI
├── core/              # Configurações, temas, rotas
├── data/              # Repositórios e datasources (API)
├── providers/         # State management (Provider)
├── screens/           # Telas da aplicação
│   └── relatorios/    # Tela de relatórios (3 abas)
└── services/          # Serviços externos
```

## ⚙️ Configuração

Crie um arquivo `.env` na raiz do `frontend/` (veja `.env.example`):

```env
# === API ===
API_BASE_URL=http://localhost:8000/api/v1  # ou URL de produção

# === TEST ===
DEMO_MODE=false

# === OAUTH GOOGLE ===
WEB_CLIENT_ID=seu_web_client_id
ANDROID_CLIENT_ID=seu_android_client_id
IOS_CLIENT_ID=seu_ios_client_id

# === CLOUDINARY (opcional) ===
CLOUDINARY_CLOUD_NAME=nome_do_cloud
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

- `provider` - State management
- `go_router` - Navegação
- `http` / `dio` - HTTP clients (chamadas à API)
- `google_fonts` - Tipografia
- `flutter_dotenv` - Variáveis de ambiente
- `firebase_core` / `firebase_messaging` - Autenticação e notificações

## 🔗 Links

- [Documentação completa](../PROJECT_CONTEXT.md)
- [Backend API](../backend/README.md)
- [Leia-me da raiz](../README.md)

## 📝 Licença

Projeto acadêmico - CATAS (Context Aware Task Automation System)
