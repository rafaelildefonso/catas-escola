# Sistema de Créditos

O CATAS utiliza um sistema de **créditos baseados em consumo de tokens** para controlar o uso da IA de forma justa e transparente. Diferentemente de sistemas que cobram por "tarefa fixa", o CATAS reflete o custo real de processamento de cada mensagem.

## Conceito: Token → Crédito

A unidade base de consumo é o **token** de Linguagem Natural — a menor unidade de texto que os modelos de IA processam.

> **Taxa de Conversão:** `2000 tokens = 1 crédito`
>
> Configurável via variável de ambiente: `TOKENS_PER_CREDIT=2000`

### Exemplos de Consumo

| Tipo de Mensagem                       | Tokens Estimados | Créditos Debitados |
| :------------------------------------- | :--------------: | :----------------: |
| Conversa simples ("Oi, tudo bem?")     |       ~300       |         1          |
| Agendamento no calendário              |      ~1.500      |         1          |
| Criação de tarefa no Notion            |      ~2.200      |         2          |
| Email com contexto longo               |      ~5.000      |         3          |

> [!NOTE]
> O consumo mínimo é sempre 1 crédito por mensagem, mesmo com poucas tokens.

---

## Limites por Plano

| Plano   | Créditos/Mês | Equivalente (aprox.)            |
| :------ | :----------: | :------------------------------ |
| Free    |      50      | ~25 automações simples          |
| Pro     |  Ilimitado*   | Uso Profissional (Fair Use)     |
| Max     |  Ilimitado*   | Escala Industrial (Fair Use)    |

*Sujeito a Fair Use Policy para evitar abusos de API.

---

## Arquitetura de Rastreamento

O sistema foi projetado para funcionar de forma transparente, sem alterações nos modelos de IA.

### Fluxo de Débito

```
Frontend → POST /chat/message
    └──> chatbot.py
            └──> AIService.analyze_message(user_id, message, ...)
                    ├──> ai_base.call_ai(provider, model, messages)
                    │        └── Retorna: (response_text, usage_stats)
                    │                        └── usage_stats.total_tokens = N
                    ├──> credits = ceil(total_tokens / TOKENS_PER_CREDIT)
                    └──> profiles.increment_quota_usage(user_id, credits)
```

### Provedores Suportados

| Provedor | Atributo de Tokens Lidos      |
| :------- | :---------------------------- |
| Gemini   | `response.usage_metadata`     |
| OpenAI   | `response.usage`              |
| Groq     | `response.usage`              |

> [!TIP]
> Se um provedor não retornar dados de uso, o sistema debita **1 crédito** como fallback seguro.

---

## Chave `.env` Relevante

```env
# Taxa de conversão Tokens → Crédito (padrão: 2000)
TOKENS_PER_CREDIT=2000
```

---

## Reset Mensal

Os créditos são renovados mensalmente. O campo `last_quota_reset` na tabela `profiles` registra a data do último reset.

O reset é acionado automaticamente quando:
1. O Stripe emite um evento `invoice.payment_succeeded` (via webhook em `webhooks.py`).
2. O usuário muda de plano (`payments.py` chama `profiles.update_subscription_tier()`).

---

## Verificações de Limite

Antes de processar qualquer mensagem, o backend verifica se o usuário tem créditos disponíveis via `profiles.check_quota(user_id)`. Se o limite for atingido, a API retorna `HTTP 402 Payment Required` e o app Flutter exibe o `UpgradeModal`.

> [!WARNING]
> O reset automático por data também pode ser acionado pelo `check_quota()` se o campo `last_quota_reset` indicar que o mês virou.
