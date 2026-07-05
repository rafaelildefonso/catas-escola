# Modo Demo e Apresentação

O CATAS possui um "Modo Demo" projetado para permitir apresentações e testes sem a necessidade de APIs reais externas ou para simular comportamentos específicos.

## 1. Mocks de IA

Caso você queira testar o fluxo de chat sem uma API de IA real:

1. No `.env` do backend, use `ENVIRONMENT=development` e configure chaves de teste.
2. Use `DEMO_MODE=true` no Flutter para dados mockados na UI.

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
