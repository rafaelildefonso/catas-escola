# Pipeline de IA (Multi-Agente)

O CATAS utiliza uma arquitetura de **Pipeline Multi-Agente** para processar mensagens do usuário e gerar planos de automação.

## Arquitetura do Pipeline

O fluxo de processamento é dividido em agentes especializados que trabalham de forma sequencial:

```
Mensagem do Usuário
    ↓
┌─────────────────────────────────────┐
│  AGENT_INTENT_CLASSIFIER            │
│  (Groq llama-3.1-8b-instant)       │
│  Classifica: CHAT ou ACTION         │
└─────────────────────────────────────┘
    ↓ (se ACTION)
┌─────────────────────────────────────┐
│  AGENT_ENTITY_EXTRACTOR             │
│  (Groq llama-3.1-8b-instant)       │
│  Extrai: nomes, datas, emails       │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│  AGENT_INTERPRETER                  │
│  (Groq llama-3.1-8b-instant)       │
│  Interpreta: ideia do usuário       │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│  AGENT_SELECTOR                     │
│  (Groq llama-3.1-8b-instant)       │
│  Seleciona: módulos disponíveis     │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│  AGENT_DEVELOPER                    │
│  (Groq llama-3.3-70b-versatile)    │
│  Gera: JSON do plano de automação   │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│  AutomationValidator                │
│  Valida: module_ids, params, tipos  │
└─────────────────────────────────────┘
    ↓
Plano Válido → Worker para Execução
```

## Componentes do Pipeline

### 1. Intent Classifier (Router)

- **Função**: Identifica se a mensagem é uma conversa ou uma ação
- **Modelo**: Groq llama-3.1-8b-instant
- **Saída**: `{"route": "chat" | "automation"}`

### 2. Entity Extractor

- **Função**: Extrai entidades relevantes da mensagem
- **Modelo**: Groq llama-3.1-8b-instant
- **Entidades**: nomes, datas, emails, valores, etc.

### 3. Interpreter (Planner)

- **Função**: Interpreta a ideia do usuário e planeja a automação
- **Modelo**: Groq llama-3.1-8b-instant
- **Saída**: Descrição da automação desejada

### 4. Selector

- **Função**: Seleciona os módulos disponíveis no registry
- **Modelo**: Groq llama-3.1-8b-instant
- **Saída**: Lista de módulos a serem utilizados

### 5. Developer (Coder)

- **Função**: Gera o JSON do plano de automação
- **Modelo**: Groq llama-3.3-70b-versatile
- **Saída**: JSON válido com steps e parâmetros

### 6. Validator (QA Agent)

- **Função**: Valida o JSON gerado
- **Verificações**:
  - module_ids existem no registry
  - parâmetros obrigatórios estão presentes
  - tipos de dados estão corretos
  - variáveis dinâmicas estão no formato correto

### 7. Retry Loop (Self-Healing)

- **Função**: Corrige erros automaticamente
- **Limite**: 3 tentativas
- **Fluxo**: Se validator encontrar erros, volta para o planner com feedback

---

## Configuração de Modelos

### Tiered Models

| Modelo | Provider | Uso |
|--------|----------|-----|
| `MODEL_TIER_BASIC` | Groq llama-3.1-8b-instant | Chat básico |
| `MODEL_TIER_PRO` | Gemini 2.5 Flash | Chat intermediário |
| `MODEL_TIER_MAX` | Gemini 2.5 Pro | Chat avançado |

### Agent Models

| Agente | Modelo Default | Função |
|--------|---------------|--------|
| `AGENT_INTENT_CLASSIFIER` | Groq llama-3.1-8b-instant | Classifica intenção |
| `AGENT_ENTITY_EXTRACTOR` | Groq llama-3.1-8b-instant | Extrai entidades |
| `AGENT_INTERPRETER` | Groq llama-3.1-8b-instant | Interpreta ideia |
| `AGENT_SELECTOR` | Groq llama-3.1-8b-instant | Seleciona módulos |
| `AGENT_DEVELOPER` | Groq llama-3.3-70b-versatile | Gera plano |

---

## Module Registry

O sistema possui um catálogo central que define todas as ações que a IA pode "chamar":

| Módulo | Descrição | Integração |
|--------|-----------|------------|
| `gmail.send_email` | Enviar email | Google OAuth |
| `gmail.create_draft` | Criar rascunho | Google OAuth |
| `google_calendar.create_event` | Criar evento | Google OAuth |
| `google_calendar.check_availability` | Verificar disponibilidade | Google OAuth |
| `google_sheets.append_row` | Adicionar linha | Google OAuth |
| `google_sheets.read_range` | Ler intervalo | Google OAuth |
| `flow.wait` | Aguardar tempo | Nenhuma |
| `flow.condition` | Condicional | Nenhuma |
| `flow.loop` | Loop | Nenhuma |

---

## Variable Resolver

O Variable Resolver é responsável por substituir variáveis dinâmicas nos parâmetros dos módulos:

**Sintaxe:** `{{step_id.campo}}`

**Exemplos:**
- `{{trigger.email}}` → Email do evento que disparou a automação
- `{{step_1.response}}` → Resposta do step 1
- `{{user.email}}` → Email do usuário

**Fluxo:**

```
1. Worker recebe plano com variáveis
2. Para cada step:
   a. Extrai params do step
   b. VariableResolver.resolve(params, context)
   c. context[step_id] = resultado da execução
3. Params resolvidos são passados para o módulo
```

---

## IA Memory (RAG)

Utilizamos um sistema de busca semântica em `pgvector` para injetar contexto relevante no prompt:

- **Preferências**: "Sempre use tom formal em meus e-mails".
- **Histórico Recente**: "Aquele evento de ontem que mencionei".
- **Contexto de Navegação**: URL e título da página que o usuário está visualizando.

---

## Fluxo de Saída (Execution)

Após a validação, o plano é enviado para o Worker:

1. O backend salva o plano no banco (`automation_runs`).
2. O **AutomationRunner** executa os módulos correspondentes no **Worker**.
3. O App Flutter recebe atualizações em tempo real de cada etapa do plano.

---

## Otimização: Context Caching

Para reduzir custos e latência em conversas longas, o pipeline separa:

- **System Prompt (Estático)**: Instruções de Persona e Regras.
- **Dynamic Content**: Histórico da sessão e resultados de execução de módulos.

Esta separação permite o uso de **Context Caching**, resultando em economia de tokens.

---

## Documentação Relacionada

- [Backend](./index.md) - Estrutura do backend
- [API Reference](./api-referencia.md) - Endpoints da API
- [Module Registry](./worker/modules-list.md) - Lista de módulos
