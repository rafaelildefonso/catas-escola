# Guia: Debugging & Troubleshooting

> 🐛 **Quando:** Algo não funciona e você precisa descobrir porquê  
> 🔍 **Onde:** Logs, traces, stack traces  
> ⏱️ **Tempo:** 5 min (simples) a 2h (complexo)

---

## 🔴 Nível 1: Problemas Comuns (5 min)

### App não conecta no backend

**Sintoma:** "Erro de conexão" no Flutter

**Checklist:**
```bash
☐ Backend rodando? → curl http://localhost:8000/health
☐ URL correta? → Ver .env do Flutter
☐ CORS permitido? → Ver server/app/main.py
☐ Android? → Use 10.0.2.2, não localhost
```

### Worker não conecta no Temporal

**Sintoma:** "Worker connection failed"

```bash
# Verificar se Temporal está rodando
docker ps

# Deve mostcar:
# temporal, temporal-ui, postgresql, elasticsearch

# Se não estiver:
cd server/docker/temporal
docker-compose up -d
```

### Créditos não atualizam

**Sintoma:** App mostra "25000/25000" mesmo usando

```bash
☐ Worker está rodando? (debita créditos)
☐ Supabase Realtime ativo?
☐ Ver console do Flutter → debugPrint dos créditos
```

---

## 🟡 Nível 2: Debug Estruturado (15 min)

### Fluxo de Debug API

```python
# 1. Adicionar logs no endpoint
@router.post("/chat/message")
async def chat_message(request: ChatRequest):
    print(f"[DEBUG] Received: {request.message}")
    
    # 2. Log após classificação
    intent = await intent_classifier.classify(request.message)
    print(f"[DEBUG] Intent: {intent}")
    
    # 3. Log após extração
    entities = await entity_extractor.extract(...)
    print(f"[DEBUG] Entities: {entities}")
    
    # 4. Log antes de disparar
    print(f"[DEBUG] Triggering automation: {automation_id}")
```

### Fluxo de Debug Worker

```python
# Na activity
@activity.defn
async def create_event(params: dict):
    print(f"[ACTIVITY] create_event called with: {params}")
    
    try:
        result = await _create_calendar_event(params)
        print(f"[ACTIVITY] Success: {result}")
        return result
    except Exception as e:
        print(f"[ACTIVITY] Error: {str(e)}")
        print(f"[ACTIVITY] Traceback: {traceback.format_exc()}")
        raise
```

### Fluxo de Debug Flutter

```dart
// No Provider
Future<void> sendMessage(String text) async {
  debugPrint('[CHAT] Sending: $text');
  
  try {
    final response = await _repository.sendMessage(text);
    debugPrint('[CHAT] Response: $response');
    
    // Log detalhado
    debugPrint('[CHAT] actionTriggered: ${response['actionTriggered']}');
    debugPrint('[CHAT] components: ${response['components']}');
    
  } catch (e) {
    debugPrint('[CHAT] Error: $e');
  }
}
```

---

## 🟠 Nível 3: Ferramentas Avançadas

### 1. Temporal Web UI

**URL:** http://localhost:8080

**O que ver:**
- Workflows em execução
- Histórico de execuções
- Erros e retries
- Detalhes de cada activity

**Dica:** Filtre por `Workflow ID` ou `Workflow Type`

### 2. Supabase Dashboard

**URL:** https://app.supabase.io

**O que verificar:**
- **Table Editor:** Dados estão sendo salvos?
- **SQL Editor:** Queries estão funcionando?
- **Logs:** Erros de RLS ou conexão
- **Realtime:** Canais estão ativos?

### 3. API Swagger

**URL:** http://localhost:8000/docs

**Teste endpoints:**
- `/health` → Status do servidor
- `/chat/message` → Pipeline de IA
- `/integrations` → OAuth tokens

### 4. Flutter DevTools

**Comando:** `flutter devtools`

**O que monitorar:**
- **Network:** Requests HTTP
- **Widget Tree:** Estado da UI
- **Performance:** Jank, memory leaks

---

## 🔵 Nível 4: Problemas Específicos

### "IA não entende o comando"

**Debug:**
```python
# No ai_service.py
print(f"[AI] Raw AI response: {raw_response}")
print(f"[AI] Parsed intent: {intent}")
print(f"[AI] Parsed entities: {entities}")
```

**Teste isolado:**
```python
# Criar script de teste
from app.services.intent_classifier import IntentClassifier

async def test():
    classifier = IntentClassifier()
    result = await classifier.classify_intent(
        "Marcar reunião amanhã às 14h",
        []
    )
    print(result)

import asyncio
asyncio.run(test())
```

### "Automação não executa"

**Verificar:**
```
1. Intent foi classificado como ação (não "conversation")?
2. automation_id foi gerado?
3. Worker está rodando?
4. Temporal recebeu o workflow?
5. Activity foi chamada?
```

**Logs para procurar:**
```bash
# No servidor API
"Triggering automation: xxx"

# No Worker
"Workflow started"
"Executing activity: xxx"
"Activity completed"
```

### "OAuth falha"

**Sintoma:** "Token inválido" ou "Acesso negado"

**Checklist:**
```bash
☐ Token expirado? → Ver data de expiração
☐ Scopes corretos? → Ver config no Google Cloud
☐ Token criptografado? → Ver repositories/integrations.py
☐ Refresh token válido? → Tentar refresh manual
```

**Debug:**
```python
# No get_user_integration.py
print(f"[OAUTH] User: {user_id}")
print(f"[OAUTH] Provider: {provider}")
print(f"[OAUTH] Token found: {token is not None}")
print(f"[OAUTH] Token expires: {expires_at}")
```

### "Componente não aparece no Flutter"

**Debug:**
```dart
// Log da resposta completa
debugPrint('[UI] Full response: ${jsonEncode(response)}');

// Verificar components
final components = response['components'] as List?;
debugPrint('[UI] Components count: ${components?.length}');
components?.forEach((c) {
  debugPrint('[UI] Component type: ${c['type']}');
});
```

**Verificar:**
- Response inclui `components` array?
- Cada componente tem `type` válido?
- UI tem case para esse `type`?

---

## 📊 Decision Tree

```
Problema
    ↓
┌─── Conexão? ────┐
│  ├─ API ↓       │
│  │   └─ curl /health
│  │   └─ Ver .env
│  │   └─ Ver CORS
│  │
│  └─ Worker ↓
│      └─ docker ps
│      └─ Ver TEMPORAL_HOST
│      └─ Ver logs
│
└─── Lógica? ─────┐
    ├─ IA ↓       │
    │   └─ Log classifier
    │   └─ Log extractor
    │   └─ Teste isolado
    │
    ├─ Temporal ↓ │
    │   └─ Temporal UI
    │   └─ Log workflow
    │   └─ Log activities
    │
    └─ Flutter ↓  │
        └─ DevTools
        └─ Log provider
        └─ Log response
```

---

## 🛠️ Comandos Úteis

### Ver logs em tempo real

```bash
# API
uvicorn app.main:app --reload --log-level debug

# Worker
python worker/main.py 2>&1 | tee worker.log

# Docker
docker-compose logs -f temporal
docker-compose logs -f postgresql
```

### Testar endpoints

```bash
# Health check
curl http://localhost:8000/health

# Chat message
curl -X POST http://localhost:8000/api/v1/chat/message \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{"message": "test"}'
```

### Inspecionar banco

```bash
# Conectar no PostgreSQL local
docker exec -it temporal-postgresql psql -U temporal

# Ou usar Supabase Dashboard SQL Editor
```

---

## 📝 Template de Bug Report

Quando abrir um issue, inclua:

```markdown
## Descrição
O que aconteceu vs o que deveria acontecer

## Como reproduzir
1. Vá para '...'
2. Clique em '...'
3. Veja erro

## Logs relevantes
```
[paste logs aqui]
```

## Ambiente
- OS: Windows/Mac/Linux
- Branch: main/develop
- Commit: abc123
```

---

> ⬅️ [Voltar para Guias](../index.md)  
> ➡️ [Nova Integração →](../nova-integracao/index.md)
