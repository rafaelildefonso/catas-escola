# Guia: Debugging & Troubleshooting

> **Quando:** Algo nao funciona e voce precisa descobrir por que  
> **Onde:** Logs, traces, stack traces  
> **Tempo:** 5 min (simples) a 2h (complexo)

---

## Nivel 1: Problemas Comuns (5 min)

### App nao conecta no backend

**Sintoma:** "Erro de conexao" no Flutter

**Checklist:**
```bash
 Backend rodando?  curl http://localhost:8000/
 URL correta?  Ver .env do Flutter
 CORS permitido?  Ver backend/app.py
 Android?  Use 10.0.2.2, nao localhost
```

### Worker nao conecta

**Sintoma:** "Connection refused"

```bash
# Verificar se Worker esta rodando
curl http://localhost:8001/

# Se nao estiver:
cd backend
python -m worker.server
```

### Creditos nao atualizam

**Sintoma:** App mostra "25000/25000" mesmo usando

```bash
 Worker esta rodando? (debita creditos)
 Ver console do Flutter  debugPrint dos creditos
```

---

## Nivel 2: Debug Estruturado (15 min)

### Fluxo de Debug API

```python
# 1. Adicionar logs no endpoint
@chat_bp.route("/api/v1/chat/message", methods=["POST"])
def chat_message():
    print(f"[DEBUG] Received: {request.json}")
    
    # 2. Log apos classificacao
    intent = intent_classifier.classify(message)
    print(f"[DEBUG] Intent: {intent}")
    
    # 3. Log apos extracao
    entities = entity_extractor.extract(message, intent)
    print(f"[DEBUG] Entities: {entities}")
    
    # 4. Log antes de disparar
    print(f"[DEBUG] Triggering automation: {automation_id}")
```

### Fluxo de Debug Worker

```python
# No modulo
def execute(params: dict):
    print(f"[MODULE] execute called with: {params}")
    
    try:
        result = _execute_action(params)
        print(f"[MODULE] Success: {result}")
        return result
    except Exception as e:
        print(f"[MODULE] Error: {str(e)}")
        print(f"[MODULE] Traceback: {traceback.format_exc()}")
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

## Nivel 3: Ferramentas Avancadas

### 1. Supabase Dashboard

**URL:** https://app.supabase.io

**O que verificar:**
- **Table Editor:** Dados estao sendo salvos?
- **SQL Editor:** Queries estao funcionando?
- **Logs:** Erros de conexao

### 2. API Browser

**URL:** http://localhost:8000/

**Teste endpoints:**
- `/`  Informacoes da API
- `/health`  Status do servidor

### 3. Flutter DevTools

**Comando:** `flutter devtools`

**O que monitorar:**
- **Network:** Requests HTTP
- **Widget Tree:** Estado da UI
- **Performance:** Jank, memory leaks

---

## Nivel 4: Problemas Especificos

### "IA nao entende o comando"

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
from services.intent_classifier import IntentClassifier

def test():
    classifier = IntentClassifier()
    result = classifier.classify_intent(
        "Marcar reuniao amanha as 14h",
        []
    )
    print(result)
```

### "Automacao nao executa"

**Verificar:**
```
1. Intent foi classificado como acao (nao "conversation")?
2. automation_id foi gerado?
3. Worker esta rodando?
4. Modulo foi chamado?
```

**Logs para procurar:**
```bash
# No backend
"Triggering automation: xxx"

# No Worker
"Executing module: xxx"
"Module completed"
```

### "OAuth falha"

**Sintoma:** "Token invalido" ou "Acesso negado"

**Checklist:**
```bash
 Token expirado?  Ver data de expiracao
 Scopes corretos?  Ver config no Google Cloud
 Token criptografado?  Ver repositories/integrations.py
 Refresh token valido?  Tentar refresh manual
```

**Debug:**
```python
# No get_user_integration
print(f"[OAUTH] User: {user_id}")
print(f"[OAUTH] Provider: {provider}")
print(f"[OAUTH] Token found: {token is not None}")
print(f"[OAUTH] Token expires: {expires_at}")
```

### "Componente nao aparece no Flutter"

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
- Cada componente tem `type` valido?
- UI tem case para esse `type`?

---

## Decision Tree

```
Problema
    |
    - Conexao? ----+
    |   - API      |
    |     - curl /health
    |     - Ver .env
    |     - Ver CORS
    |
    |   - Worker   |
    |     - curl http://localhost:8001
    |     - Ver logs
    |
    - Logica? -----+
        - IA       |
        - Log classifier
        - Log extractor
        - Teste isolado
        |
        - Worker   |
        - Log modulo
        |
        - Flutter  |
        - DevTools
        - Log provider
        - Log response
```

---

## Comandos Uteis

### Ver logs em tempo real

```bash
# API
flask run --port 8000 --debug

# Worker
python -m worker.server
```

### Testar endpoints

```bash
# Health check
curl http://localhost:8000/health

# Chat message
curl -X POST http://localhost:8000/api/v1/chat/message \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer dev-token" \
  -d '{"message": "test"}'
```

### Inspecionar banco

```bash
# Conectar no PostgreSQL via Supabase
# Usar Supabase Dashboard SQL Editor
```

---

## Template de Bug Report

Quando abrir um issue, inclua:

```markdown
## Descricao
O que aconteceu vs o que deveria acontecer

## Como reproduzir
1. Va para '...'
2. Clique em '...'
3. Veja erro

## Logs relevantes
```
[cole logs aqui]
```

## Ambiente
- OS: Windows/Mac/Linux
- Branch: main/develop
- Commit: abc123
```

---

> [Voltar para Guias](../index.md)  
> [Nova Integracao ](../nova-integracao/index.md)
