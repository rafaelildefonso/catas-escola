# Serviços do Backend

O backend do CATAS, desenvolvido em **FastAPI**, atua como um orquestrador central integrando o Banco de Dados (Supabase), a IA (Gemini) e o motor de automação (n8n).

## 1. Persistência e Dados (Supabase)

O acesso ao banco de dados é desacoplado através de **Repositórios** localizados em `server/app/repositories/`.

- **`profiles`**: Gerencia limites de uso e níveis de assinatura.
- **`chat`**: Salva sessões de chat e o histórico de mensagens.
- **`automation_logs`**: Registra cada execução de automação para auditoria e feedback.

---

## 2. Integração com Stripe (Billing)

O processamento de pagamentos e a gestão de planos são realizados via Stripe.

- **Webhooks**: O endpoint `/api/v1/payments/webhook` recebe notificações do Stripe para atualizar o `subscription_tier` no banco de dados automaticamente após uma compra ou cancelamento.
- **Checkout**: Rotas para criar sessões de pagamento seguras.

---

## 3. Segurança e Autenticação

- **Supabase Auth**: O backend valida o JWT (JSON Web Token) enviado pelo app Flutter em cada requisição.
- **RLS (Row Level Security)**: Além da validação no backend, as tabelas do Supabase possuem políticas RLS que garantem que um usuário só possa acessar seus próprios dados.
- **Middleware**: Filtros globais para CORS e validação de tokens.

---

## 4. Orquestração de Execução (Temporal.io)

O CATAS utiliza o **Temporal.io** como o motor de workflows de produção para garantir que as automações sejam executadas de forma confiável e resiliente.

- **`TemporalService`**: Localizado em `server/app/services/temporal_service.py`, gerencia a conexão com o Cluster Temporal e inicia os Workflows.
- **`Workflow ID`**: Cada execução recebe um ID único (ex: `automation-<id>`) para rastreamento e auditoria em tempo real.
- **Workers e Activities**: O backend possui Workers especializados que executam "Activities" (ações individuais como enviar e-mail, criar evento, etc.) com políticas de retry automático e backoff exponencial.
- **n8n (Prototipagem)**: Mantido como uma ferramenta interna para a equipe CATAS criar e testar rapidamente novos conectores antes de transformá-los em Activities nativas no Temporal.
