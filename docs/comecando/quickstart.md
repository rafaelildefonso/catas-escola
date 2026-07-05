# Quick Start - 15 Minutos

> **Meta:** Ter o CATAS rodando localmente em 15 minutos ou menos.

---

## Pre-checklist

Antes de comecar, verifique se tem:

```markdown
 Python 3.10+ instalado
 Flutter 3.19+ instalado (`flutter doctor`)
 Conta no Supabase (gratuita)
 Conta no Google Cloud (para OAuth)
```

> **Windows?** Use PowerShell. **Mac/Linux?** Use terminal bash/zsh.

---

## Passo 1: Backend API (5 min)

```bash
cd backend

# Criar ambiente virtual (primeira vez)
python -m venv .venv

# Ativar
.\.venv\Scripts\activate        # Windows
source .venv/bin/activate        # Mac/Linux

# Instalar dependencias
pip install -r requirements.txt
```

### Configurar .env

```bash
# Copiar template
cp .env.example .env
```

Edite `.env` e preencha **pelo menos**:

```env
# === SUPABASE ===
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_SERVICE_ROLE_KEY=sua_chave_aqui

# === DATABASE (SQLAlchemy) ===
DATABASE_URL=postgresql://postgres.[PROJECT_REF]:[DB_PASSWORD]@aws-0-[REGION].pooler.supabase.com:6543/postgres

# === IA ===
GROQ_API_KEY=sua_chave_groq
```

> **Onde pegar:**
> - Supabase URL/Key: Dashboard → Settings → API
> - DATABASE_URL: Dashboard → Project Settings → Database → Connection string
> - Groq API Key: [Groq Console](https://console.groq.com)

### Rodar servidor

```bash
flask run --port 8000 --debug
```

**Verifique:** http://localhost:8000/

---

## Passo 2: Worker (3 min)

Em **outro terminal** (mantenha o API rodando):

```bash
cd backend
.\.venv\Scripts\activate        # Windows
source .venv/bin/activate        # Mac/Linux

python -m worker.server
```

**Sucesso quando ver:**
```
Worker rodando em http://0.0.0.0:8001
```

> O Worker e quem executa as automacoes (criar eventos, enviar emails, etc).

---

## Passo 3: App Flutter (4 min)

```bash
cd app_flutter

# Instalar dependencias
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
# Web (mais facil para testar)
flutter run -d chrome

# Ou Windows
flutter run -d windows

# Ou Android (emulador deve estar rodando)
flutter run -d android
```

**Primeira tela:** Tela de login com Google.

---

## Teste seu Setup

1. **Abra o app** e faca login
2. **Na tela de chat**, digite:
   ```
   Marcar reuniao amanha as 14h com test@email.com
   ```
3. **Veja a magica:**
   - IA classifica a intencao
   - Extrai data, hora, email
   - Mostra preview do evento
   - Pede confirmacao
   - Cria no Google Calendar (se tiver integracao)

---

## Verificando se Tudo Funciona

| Componente | Como verificar | Status |
|------------|----------------|--------|
| API | http://localhost:8000/ |  |
| Worker | Terminal mostra "Worker rodando" |  |
| Flutter | App abre sem erros |  |
| Integracao | Chat responde com componentes |  |

---

## Deu erro?

### "Porta ja em uso"
```bash
# Descobrir processo na porta 8000
netstat -ano | findstr :8000    # Windows
lsof -i :8000                     # Mac/Linux

# Matar processo
kill -9 <PID>
```

### "Worker nao conecta"
- Verifique `WORKER_URL` no `.env`
- Certifique-se de que o worker esta rodando

### "Flutter nao encontra API"
- Android Emulator: use `10.0.2.2:8000` em vez de `localhost`
- iOS Simulator: use `localhost`
- Web: CORS deve estar configurado no backend (padrao: permitido)

### Mais problemas
[Troubleshooting Completo](./troubleshooting.md)

---

## Proximos Passos

Escolha seu caminho:

- **[Quero mexer no Flutter →](../flutter/index.md)**
- **[Quero mexer no Backend →](../backend/index.md)**
- **[Quero configurar Infra →](../infra/index.md)**

---

> **Dica:** Anote seus comandos de startup favoritos em um script `.bat` ou `.sh`!
