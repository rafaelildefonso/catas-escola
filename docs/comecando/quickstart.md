# Quick Start - 15 Minutos ⏱️

> **Meta:** Ter o CATAS rodando localmente em 15 minutos ou menos.

---

## ✅ Pré-checklist

Antes de começar, verifique se tem:

```markdown
☐ Docker Desktop instalado e rodando
☐ Python 3.10+ instalado
☐ Flutter 3.19+ instalado (`flutter doctor`)
☐ Conta no [Supabase](https://supabase.com) (gratuita)
☐ Conta no [Google Cloud](https://console.cloud.google.com) (para OAuth)
```

> 💡 **Windows?** Use PowerShell. **Mac/Linux?** Use terminal bash/zsh.

---

## 🐳 Passo 1: Temporal Server (3 min)

O Temporal é o coração da orquestração de automações.

```bash
cd server/docker/temporal
docker-compose up -d
```

**Verifique se subiu:**
```bash
docker ps
```

Deve mostrar 4 containers: `temporal`, `temporal-ui`, `postgresql`, `elasticsearch`.

**Acesse a UI:** http://localhost:8080

> 🔴 **Erro comum:** Porta 8080 ocupada? Pare outros serviços ou mude a porta no `docker-compose.yml`.

---

## 🐍 Passo 2: Backend API (5 min)

```bash
cd server

# Criar ambiente virtual (primeira vez)
python -m venv venv

# Ativar
venv\Scripts\activate        # Windows
source venv/bin/activate     # Mac/Linux

# Instalar dependências
pip install -r requirements.txt
```

### Configurar .env

```bash
# Copiar template
cp .env.example .env
```

Edite `.env` e preencha **pelo menos**:

```env
# === SUPABASE (obrigatório) ===
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_SERVICE_ROLE_KEY=sua_chave_aqui

# === IA (para testes básicos) ===
GOOGLE_API_KEY=sua_chave_gemini

# === TEMPORAL (local) ===
TEMPORAL_HOST=localhost:7233
TEMPORAL_NAMESPACE=default
TEMPORAL_TASK_QUEUE=automation-queue
```

> 🔑 **Onde pegar:**
> - Supabase URL/Key: Dashboard → Settings → API
> - Google API Key: [Google AI Studio](https://aistudio.google.com/app/apikey)

### Rodar servidor

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

**Verifique:** http://localhost:8000/docs

Deve abrir o Swagger UI com todos os endpoints.

---

## ⚡ Passo 3: Temporal Worker (3 min)

Em **outro terminal** (mantenha o API rodando):

```bash
cd server
venv\Scripts\activate        # Windows
source venv/bin/activate     # Mac/Linux

$env:PYTHONPATH = "."       # Windows
export PYTHONPATH="."       # Mac/Linux

python worker/main.py
```

**Sucesso quando ver:**
```
🚀 Worker ativo — task_queue: 'automation-queue'
Conectado ao Temporal — host: localhost:7233
```

> 💡 O Worker é quem executa as automações (criar eventos, enviar emails, etc).

---

## 📱 Passo 4: App Flutter (4 min)

```bash
cd app_flutter

# Instalar dependências
flutter pub get

# Configurar .env
cp .env.example .env
```

Edite `.env`:

```env
# === SUPABASE ===
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_ANON_KEY=sua_anon_key_aqui

# === API ===
API_BASE_URL=http://localhost:8000

# === OAUTH GOOGLE (opcional para testes locais) ===
WEB_CLIENT_ID=seu_web_client_id.apps.googleusercontent.com
```

### Rodar

```bash
# Web (mais fácil para testar)
flutter run -d chrome

# Ou Windows
flutter run -d windows

# Ou Android (emulador deve estar rodando)
flutter run -d android
```

**Primeira tela:** Tela de login com Google.

---

## 🎉 Teste seu Setup

1. **Abra o app** e faça login
2. **Na tela de chat**, digite:
   ```
   Marcar reunião amanhã às 14h com test@email.com
   ```
3. **Veja a mágica:**
   - IA classifica a intenção
   - Extrai data, hora, email
   - Mostra preview do evento
   - Pede confirmação
   - Cria no Google Calendar (se tiver integração)

---

## 🔍 Verificando se Tudo Funciona

| Componente | Como verificar | Status |
|------------|----------------|--------|
| Temporal | http://localhost:8080 | ☐ |
| API | http://localhost:8000/docs | ☐ |
| Worker | Terminal mostra "Worker ativo" | ☐ |
| Flutter | App abre sem erros | ☐ |
| Integração | Chat responde com componentes | ☐ |

---

## 🆘 Deu erro?

### "Porta já em uso"
```bash
# Descobrir processo na porta 8000
netstat -ano | findstr :8000    # Windows
lsof -i :8000                     # Mac/Linux

# Matar processo
kill -9 <PID>
```

### "Worker não conecta"
- Verifique se Temporal está rodando: `docker ps`
- Verifique `TEMPORAL_HOST` no `.env`

### "Flutter não encontra API"
- Android Emulator: use `10.0.2.2:8000` em vez de `localhost`
- iOS Simulator: use `localhost`
- Web: CORS deve estar configurado no backend (padrão: permitido)

### Mais problemas
→ [Troubleshooting Completo](./troubleshooting.md)

---

## 📚 Próximos Passos

Escolha seu caminho:

- **[👨‍💻 Quero mexer no Flutter →](../flutter/index.md)**
- **[🐍 Quero mexer no Backend →](../backend/index.md)**
- **[🔧 Quero configurar Infra →](../infra/index.md)**

---

> 💬 **Dica:** Anote seus comandos de startup favoritos em um script `.bat` ou `.sh`!
