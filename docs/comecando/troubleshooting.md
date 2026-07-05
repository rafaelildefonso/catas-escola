# Troubleshooting

> Guia de problemas comuns e como resolver

---

## Backend API

### "ModuleNotFoundError: No module named ..."

```bash
# Verificar se venv esta ativado
.\.venv\Scripts\activate       # Windows
source .venv/bin/activate       # Mac/Linux

# Reinstalar dependencias
pip install -r requirements.txt
```

### "Flask command not found"

```bash
# Verificar se venv esta ativado
.\.venv\Scripts\activate       # Windows
source .venv/bin/activate       # Mac/Linux

# Reinstalar dependencias
pip install -r requirements.txt
```

### "SUPABASE_URL not set"

```bash
# Copiar .env.example para .env
cp .env.example .env

# Editar com suas credenciais
```

### "DATABASE_URL not set"

```bash
# Adicionar DATABASE_URL no .env
# Formato: postgresql://user:password@host:port/database
# Para Supabase: Dashboard > Project Settings > Database > Connection string
```

### "Port 8000 is already in use"

```bash
# Windows
netstat -ano | findstr :8000

# Matar processo
taskkill /PID <NUMERO> /F

# Ou mudar porta
flask run --port 8001 --debug
```

---

## Worker

### "Worker connection refused"

```bash
# 1. Verificar se Worker esta rodando
curl http://localhost:8001/

# 2. Se nao estiver, iniciar:
cd backend
.\.venv\Scripts\activate
python -m worker.server

# 3. Verificar WORKER_URL no .env
# Deve ser: http://localhost:8001
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
# Deve ser a chave publica (anon), nao service_role

# Se expirado: gerar novo token no Supabase Dashboard
# Authentication > Users > Gerar novo token
```

### "Flutter run stuck at 'Running Gradle task...'"

```bash
# Limpar cache
flutter clean
flutter pub get

# Ou usar modo offline
flutter run --offline
```

---

## Autenticacao

### "Google Sign-In nao abre"

```bash
# Verificar:
# 1. WEB_CLIENT_ID, ANDROID_CLIENT_ID, IOS_CLIENT_ID no .env
# 2. OAuth consent screen configurado no Google Cloud
# 3. App registrado no Google Cloud com SHA-1 (Android)
```

### "Magic link nao chega"

```bash
# Verificar:
# 1. Email correto
# 2. Spam/promocoes
# 3. Supabase Auth > Email templates configurados
```

---

## Integracoes (Google Calendar/Gmail)

### "Token invalido"

```bash
# Token OAuth expirou
# Solucao: Desconectar e reconectar integracao no app

# Ou verificar refresh token no banco:
# SELECT * FROM integrations WHERE provider = 'google';
```

### "Access denied" ou "Insufficient permissions"

```bash
# Verificar scopes no Google Cloud:
# - https://www.googleapis.com/auth/calendar
# - https://www.googleapis.com/auth/gmail.send
# - etc

# Verificar se usuario concedeu permissoes
```

---

## Creditos

### "Creditos nao atualizam no app"

```bash
# 1. Verificar se Worker esta rodando
# 2. Fazer pull-to-refresh no app
# 3. Verificar console do Flutter por erros
```

---

## Problemas Genericos

### "Nada funciona"

Reset completo:
```bash
# 1. Parar tudo
# Ctrl+C nos terminais do backend e Worker

# 2. Limpar
flutter clean
cd backend && pip cache purge

# 3. Recomecar
flask run --port 8000 --debug
# (novo terminal) python -m worker.server
flutter pub get && flutter run
```

---

## Ainda nao funcionou?

1. **Verifique os logs** - Sempre comece lendo a mensagem de erro completa
2. **Verifique variaveis de ambiente** - 80% dos erros sao envs faltando
3. **Verifique portas** - Use `netstat` ou `lsof` para ver portas ocupadas
4. **Google/Stack Overflow** - Copie a mensagem de erro exata
5. **Documentacao** - Volte para o [Quick Start](./quickstart.md)
