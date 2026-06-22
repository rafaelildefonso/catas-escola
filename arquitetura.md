# 🧠 AI Strategic Analysis - Arquitetura de Execução e Fluxo de Dados (CATAS)
**Data:** Maio de 2026
**Foco:** Transição de AI Wrapper para Infraestrutura Industrial (Build-Time vs Run-Time)

---

## 📖 1. Contexto: Por que estamos mudando a arquitetura?
Durante o desenvolvimento do MVP, percebemos que invocar um agente de IA (via MCP ou chamadas diretas) a cada vez que um gatilho é ativado (Run-Time) gera três problemas fatais para um SaaS B2B:
1. **Custo Inviável:** Pagar pelo raciocínio do LLM a cada execução de tarefa corrói a margem de lucro.
2. **Latência Alta:** A IA adiciona de 5 a 15 segundos por passo, o que é inaceitável para quem precisa de respostas instantâneas (ex: capturar um lead).
3. **Falta de Confiabilidade (Alucinação):** A IA pode alterar o comportamento esperado de forma imprevisível, arriscando a integridade dos dados do cliente.

**A Solução:** Separar a "Mente" (Inteligência) dos "Músculos" (Execução). A IA deve trabalhar apenas na criação da "receita" (Build-Time), enquanto a execução diária fica a cargo de funções determinísticas, rápidas e burras orquestradas pelo Temporal.io (Run-Time).

---

## 🏗️ 2. A Nova Arquitetura (O Padrão Fábrica)

O sistema agora opera em dois momentos distintos e isolados:

### A. Momento de Criação (Build-Time)
* **Ator Principal:** Agente Arquiteto (Claude/Gemini).
* **Papel do MCP:** Usado *apenas* aqui, para que a IA leia o catálogo interno de integrações e saiba quais parâmetros cada módulo exige.
* **Saída:** Um JSON estático, validado e imutável (A Receita).

### B. Momento de Execução (Run-Time)
* **Ator Principal:** Temporal.io Worker + Backend Python.
* **Módulos:** Funções Python determinísticas que fazem chamadas REST diretas (ex: `requests.post` para a API do WhatsApp). Nenhuma IA decide o fluxo aqui.
* **Data Flow (A Magia):** Utilização de um `VariableResolver` para injetar dados voláteis dinamicamente nos parâmetros, usando a sintaxe `{{step_id.campo}}`.

---

## 📋 3. Checklist de Implementação: O Motor de Variáveis

### Fase 1: Padronização do JSON (A Receita)
- [ ] **Esquema Rígido:** Definir um modelo Pydantic para o JSON da automação contendo obrigatoriamente `step_id`, `module_name` e `params`.
- [ ] **Regra de Output:** Garantir que o Agente Arquiteto sempre gere referências a passos anteriores usando a sintaxe de chaves duplas (ex: `{{trigger.email}}`).

### Fase 2: O Contexto de Execução (A Lousa)
- [ ] **State Manager:** Criar um dicionário `workflow_context = {}` dentro do Workflow principal do Temporal.
- [ ] **Gravação de Estado:** Após cada Activity (módulo) terminar com sucesso, salvar o JSON de resposta no contexto usando o `step_id` como chave (ex: `workflow_context["step_1"] = result`).

### Fase 3: O Variable Resolver (O Motor)
- [ ] **Serviço de Resolução:** Criar uma função utilitária `resolve_variables(params_dict, context_dict)`.
- [ ] **Integração Jinja2:** Implementar a lógica interna do Resolver usando a biblioteca `Jinja2` do Python para suportar substituições avançadas (ou usar Regex simples para o MVP).
- [ ] **Tratamento de Falhas:** Adicionar try/except no Resolver para estourar um erro claro caso o JSON peça uma variável que não existe no contexto (ex: "KeyError: 'lead_name' not found in step_1 output").

### Fase 4: O Worker (A Linha de Montagem)
- [ ] **Filtro Pré-Execução:** Configurar o Worker para, antes de chamar qualquer Activity, passar os `params` do passo atual pelo `VariableResolver`.
- [ ] **Execução Limpa:** Garantir que a Activity Python (ex: `whatsapp_send`) receba o dicionário de parâmetros já limpo e com os valores reais injetados, sem saber que havia um placeholder ali.
- [ ] **Módulo de IA Especial (Opcional):** Criar uma Activity específica chamada `ai.transform_data` (para resumir textos ou extrair dados em run-time) que recebe um prompt estático e retorna texto limpo para o próximo passo.