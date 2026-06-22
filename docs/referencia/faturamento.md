# Faturamento e Assinaturas (Stripe)

O CATAS utiliza o Stripe para gerenciar pagamentos e assinaturas recorrentes.

## Fluxo de Compra

1. O usuário escolhe um plano na tela `PricingScreen` do app.
2. O app solicita a criação de uma `Checkout Session` ao backend.
3. O usuário é redirecionado para o Stripe Checkout.
4. Após o pagamento, o Stripe envia um webhook para o backend.

## Webhook do Stripe

O backend escuta eventos do Stripe no endpoint `/api/v1/payments/webhook`.

### Eventos Processados:

- `checkout.session.completed`: Disparado quando um usuário assina um plano pela primeira vez ou faz um upgrade.
- `customer.subscription.updated`: Disparado quando há mudanças na assinatura (ex: alteração de plano).
- `customer.subscription.deleted`: Disparado quando a assinatura é cancelada ou expira.

### Atualização no Banco de Dados

Ao receber um evento de sucesso, o backend atualiza a tabela `profiles` do usuário:

- Altera o `subscription_tier` (Basic, Pro, Max).
- Sincroniza o `monthly_quota_limit`.

## Configuração do Produto

Para que a integração funcione, os IDs dos produtos/preços criados no Stripe Dashboard devem ser configurados no arquivo `.env` do backend:

- `BASIC_PLAN_ID`
- `PRO_PLAN_ID`
- `MAX_PLAN_ID`
