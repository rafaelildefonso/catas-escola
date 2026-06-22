# Troubleshooting

> 🆘 Guia de problemas comuns e como resolver

---

## Docker / Temporal

### "Porta 8080 já está em uso"

```powershell
# Windows: Encontrar e matar processo
netstat -ano | findstr :8080
taskkill /PID <NUMERO> /F

# Ou mudar porta no docker-compose.yml
# ports:
#   - "8081:8080"  # Mapeia 8081 local para 8080 container
```

### "docker-compose command not found"

```bash
# Docker Desktop antigo usa docker-compose
# Novo usa: docker compose (sem hífen)

docker compose up -d
```

### "Container temporal não inicia"

```bash
# Ver logs
docker-compose logs temporal

# Problemas comuns:
# - Memória insuficiente (precisa 4GB+)
# - Portas em conflito
# - Elasticsearch precisa de VM max_map_count

# Aumentar memória para o Docker Desktop:
# Settings → Resources → Memory: 4GB+
```

---

## Backend API

### "ModuleNotFoundError: No module named 'app'"

```bash
# PYTHONPATH não definido
$env:PYTHONPATH = "."        # Windows
export PYTHONPATH="."      # Mac/Linux
```

### "uvicorn: command not found"

```bash
# Verificar se venv está ativado
venv\Scripts\activate       # Windows
source venv/bin/activate     # Mac/Linux

# Reinstalar dependências
pip install -r requirements.txt
```

### "SUPABASE_URL not set"

```bash
# Copiar .env.example para .env
cp .env.example .env

# Editar com suas credenciais
```

### "Port 8000 is already in use"

```bash
# Windows
netstat -ano | findstr :8000

# Matar processo ou mudar porta
uvicorn app.main:app --reload --port 8001
```

---

## Worker

### "Worker connection refused"

```bash
# 1. Verificar se Temporal está rodando
docker ps

# 2. Verificar TEMPORAL_HOST no .env
# Deve ser: localhost:7233 (local)

# 3. Verificar se porta 7233 está liberada
netstat -ano | findstr :7233
```

### "Module 'activities' not found"

```bash
# PYTHONPATH não definido no terminal do worker
$env:PYTHONPATH = "."        # Windows PowerShell
$env:PYTHONPATH="."          # Windows CMD (sem espaço)
export PYTHONPATH="."         # Mac/Linux
```

---

## Flutter

### "API_BASE_URL connection refused"

**Android Emulator:**
```env
# Use 10.0.2.2 em vez de localhost
API_BASE_URL=http://10.0.2.2:8000
```

**iOS Simulator:**
```env
# localhost funciona
API_BASE_URL=http://localhost:8000
```

**Web:**
```env
# Mesma origem ou CORS configurado
API_BASE_URL=http://localhost:8000
```

### "Invalid API key" ou "JWT expired"

```bash
# Verificar SUPABASE_ANON_KEY no .env do Flutter
# Deve ser a chave pública (anon), não service_role

# Se expirado: gerar novo token no Supabase Dashboard
# Authentication → Users → Gerar novo token
```

### "Flutter run stuck at "Running Gradle task..."

```bash
# Limpar cache
flutter clean
flutter pub get

# Ou usar modo offline
flutter run --offline
```

---

## Autenticação

### "Google Sign-In não abre"

```bash
# Verificar:
# 1. WEB_CLIENT_ID, ANDROID_CLIENT_ID, IOS_CLIENT_ID no .env
# 2. OAuth consent screen configurado no Google Cloud
# 3. App registrado no Google Cloud com SHA-1 (Android)
```

### "Magic link não chega"

```bash
# Verificar:
# 1. Email correto
# 2. Spam/promoções
# 3. Supabase Auth → Email templates configurados
```

---

## Integrações (Google Calendar/Gmail)

### "Token inválido"

```bash
# Token OAuth expirou
# Solução: Desconectar e reconectar integração no app

# Ou verificar refresh token no Supabase:
# SELECT * FROM user_integrations WHERE provider = 'google';
```

### "Access denied" ou "Insufficient permissions"

```bash
# Verificar scopes no Google Cloud:
# - https://www.googleapis.com/auth/calendar
# - https://www.googleapis.com/auth/gmail.send
# - etc

# Verificar se usuário concedeu permissões
```

---

## Créditos

### "Créditos não atualizam no app"

```bash
# 1. Verificar se Worker está rodando
# 2. Verificar Supabase Realtime ativo
# 3. Fazer pull-to-refresh no app
# 4. Verificar console do Flutter por erros
```

---

## Problemas Genéricos

### "Nada funciona"

Reset completo:
```bash
# 1. Parar tudo
# Ctrl+C nos terminais do API e Worker
docker-compose down

# 2. Limpar
flutter clean
cd server && pip cache purge

# 3. Recomeçar
docker-compose up -d
uvicorn app.main:app --reload
# (novo terminal) python worker/main.py
flutter pub get && flutter run
```

---

## Ainda não funcionou?

1. **Verifique os logs** - Sempre comece lendo a mensagem de erro completa
2. **Verifique variáveis de ambiente** - 80% dos erros são envs faltando
3. **Verifique portas** - Use `netstat` ou `lsof` para ver portas ocupadas
4. **Google/Stack Overflow** - Copie a mensagem de erro exata
5. **Documentação** - Volte para o [Quick Start](../quickstart.md)

