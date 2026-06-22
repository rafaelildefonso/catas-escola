# Modo Demo e Apresentação

O CATAS possui um "Modo Demo" projetado para permitir apresentações e testes sem a necessidade de APIs reais externas (n8n/Stripe) ou para simular comportamentos específicos.

## 1. Mocks de n8n

Caso você queira testar o fluxo de chat sem um servidor n8n real rodando:

1. Execute o script de mock: `python server/mock_n8n.py`.
2. No `.env` do backend, aponte `N8N_WEBHOOK_URL` para `http://localhost:5678/webhook`.

O mock simulará respostas de IA e detecção de ações de forma determinística.

## 2. Mock de Billing

Para testar as telas de assinatura sem cartões de crédito reais:

1. Ative o `STRIPE_TEST_MODE=true` no backend (se implementado) ou use as chaves de teste (`sk_test_...`) fornecidas pelo Stripe.
2. Use os cartões de teste padrão do Stripe (ex: `4242 4242 4242 4242`).

## 3. Flag de Demonstração no App

No arquivo `.env` do Flutter, você pode definir:

```env
DEMO_MODE=true
```

Isso pode ser usado no código para carregar dados mockados em telas de estatísticas ou para pular etapas de carregamento lento durante uma apresentação ao vivo.

## 4. Gerador de Títulos

A IA gera títulos inteligentes para os chats. Se quiser testar o layout da barra lateral, basta iniciar novas conversas com diferentes mensagens para ver a categorização em ação.
