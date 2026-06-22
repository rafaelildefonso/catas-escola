# Maestro AI Pipeline

O CATAS não utiliza mais um sistema rígido de "Slot Filling". Agora, as intenções do usuário são processadas por uma arquitetura de **Pipeline Agêntico (Maestro)**, que permite a criação de planos de automação complexos e multi-step com alta precisão e resiliência.

## Arquitetura do Pipeline

O fluxo de processamento é dividido em agentes especializados que trabalham de forma sequencial:

1. **Router (Intent Classification)**:
   - Identifica se a mensagem é uma conversa natural ou se requer uma ação.
   - Utiliza modelos rápidos (**Gemini 1.5 Flash**) para baixa latência.
   - Categorias: `Conversation`, `Action/Task`, `System/Help`.

2. **Planner (Automation Architect)**:
   - Se for uma ação, o Planner assume o controle.
   - Consulta o **Module Registry** (Catálogo de Módulos) para ver as capacidades disponíveis.
   - Gera um `AutomationPlan` (JSON) que descreve os passos (steps) necessários, os parâmetros e as dependências entre eles.
   - Utiliza modelos mais capazes (**Claude 3.5 Sonnet / Gemini 1.5 Pro**).

3. **Validator (QA Agent)**:
   - Revisa o JSON gerado pelo Planner.
   - Verifica se os `module_id` existem no catálogo e se os esquemas de entrada/saída são respeitados.
   - Garante que variáveis dinâmicas (ex: `{{user.name}}`) estão no formato correto.

4. **Retry Loop (Self-Healing)**:
   - Se o Validator encontrar erros, eles são enviados de volta ao Planner como feedback.
   - O Planner tenta corrigir o plano. Este ciclo ocorre até 3 vezes antes de reportar falha ao usuário.

---

## Componentes Chave

### Module Registry (Catálogo de Módulos)

O sistema possui um catálogo central que define todas as ações que a IA pode "chamar".
- `module_id`: Identificador único (ex: `google_calendar.create_event`).
- `input_schema`: Esquema Pydantic/JSON descrevendo os campos necessários.
- `output_schema`: O que o módulo retorna para os próximos passos.
- `required_integration`: Qual integração o usuário precisa ter ativa (ex: `google_auth`).

### IA Memory (RAG)

Utilizamos um sistema de busca semântica em `pgvector` para injetar contexto relevante no prompt:
- **Preferências**: "Sempre use tom formal em meus e-mails".
- **Histórico Recente**: "Aquele evento de ontem que mencionei".
- **Contexto de Navegação**: URL e título da página que o usuário está visualizando.

---

## Fluxo de Saída (Execution)

Após a validação, o plano é enviado para o backend:
1. O backend salva o plano no Supabase (`automation_runs`).
2. O **TemporalService** dispara o Workflow correspondente no **Temporal.io**.
3. O App Flutter recebe atualizações em tempo real (Streaming via SSE) de cada etapa do plano.

---

## Otimização: Context Caching

Para reduzir custos e latência em conversas longas, o pipeline separa:
- **System Prompt (Estático)**: Instruções de Persona e Regras do Maestro.
- **Dynamic Content**: Histórico da sessão e resultados de execução de módulos.
Esta separação permite o uso de **Gemini Context Caching**, resultando em uma economia de tokens de até 90% em sessões persistentes.
