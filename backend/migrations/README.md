# Migrations do Banco de Dados

Este diretório contém as migrations SQL para o banco de dados **MySQL 8.0+**.

## 📋 Como Executar

### Opção 1: MySQL Workbench (Recomendado)

1. Abra o [MySQL Workbench](https://dev.mysql.com/downloads/workbench/)
2. Conecte ao seu banco (localhost:3306, banco `catas_db`)
3. Clique em **File → Open SQL Script** e selecione o arquivo de migration
4. Clique no ícone **Execute** (⚡) para rodar o script
5. Confirme que a execução terminou sem erros

### Opção 2: Docker Compose (automático no primeiro boot)

```bash
cd backend
docker compose up -d
```

O Compose monta somente `DATABASE.sql` em `/docker-entrypoint-initdb.d`
do contêiner `catas_mysql`. O MySQL executa esse arquivo apenas ao criar
um volume de dados novo. Bancos já existentes exigem as migrations
incrementais aplicáveis manualmente.

### Opção 3: CLI (mysql client)

```bash
mysql -h localhost -P 3306 -u root -p catas_db < DATABASE.sql
mysql -h localhost -P 3306 -u root -p catas_db < 002_create_chat_schema.sql
```

## 📁 Ordem de Execução

Use o arquivo consolidado **`DATABASE.sql`** que já cria todo o schema
(tabelas, índices, triggers, procedures e seeds) em ordem de dependência.
Para aplicar as migrations individualmente, siga a ordem numérica:

1. `001_create_users.sql` - Usuários/perfis
2. `002_create_chat_schema.sql` - Chat (sessões, mensagens, logs)
3. `006_create_notifications.sql` - Notificações
4. `009_automation_core_schema.sql` - Definições/runs/feedback de automações
5. `009_create_message_feedback.sql` - Feedback de mensagens
6. `014_create_handle_credit_debit.sql` - Função de débito de créditos
7. `018_procedures_relatorios.sql` - Functions/Procedures de relatórios
8. `20260330_create_user_devices.sql` - Dispositivos FCM (push)
9. `019_billing_and_attachments.sql` - Dados de assinatura Stripe e tabela de anexos (schema existente)

As demais migrations (003–008, 010–017) são atualizações incrementais.
Se você usou o `DATABASE.sql`, elas são **opcionais** — o schema já
inclui essas colunas. Reexecutá-las é seguro (usam `if não existe`).

Para bancos existentes, aplique uma vez a migration `019_billing_and_attachments.sql` antes de
iniciar a versão atualizada do backend. Instalações novas podem usar o `DATABASE.sql`, que já
contém as colunas e a tabela; não execute `019` depois dele. O bucket privado `attachments` é
provisionado automaticamente na primeira utilização do endpoint de upload.

Para bancos existentes, aplique também `020_automation_scheduler.sql` uma vez,
antes de iniciar o scheduler. Instalações novas com `DATABASE.sql` já têm
`next_run_at`, seu índice e a tabela de notificações; não execute `020` nelas.

## ✅ Verificação

Após executar as migrations, verifique se as tabelas foram criadas:

```sql
-- Listar tabelas criadas
SHOW TABLES;

-- Verificar tabelas essenciais
SELECT TABLE_NAME
FROM information_schema.tables
WHERE table_schema = DATABASE()
AND TABLE_NAME IN ('users', 'profiles', 'chat_sessions', 'messages', 'automation_runs');
```

## 🔒 Controle de Acesso

O MySQL não possui Row Level Security (RLS) como o PostgreSQL/Supabase.
O controle de acesso é feito **na camada de aplicação (backend)**:
todas as queries de filtro por dono usam `WHERE user_id = ?`, validado
pelo token de autenticação do usuário logado.

## 📝 Notas

- Todas as tabelas usam `ENGINE=InnoDB` e `utf8mb4_unicode_ci` (emojis suportados)
- UUIDs são armazenados como `VARCHAR(36)` com `DEFAULT (UUID())`
- `timestamptz`/`jsonb`/`uuid` e `gen_random_uuid()` do PostgreSQL viraram
  `DATETIME`, `JSON`, `VARCHAR(36)` e `UUID()` no MySQL
- O MySQL não tem `ADD COLUMN IF NOT EXISTS`; migrations incrementais usam
  o padrão `information_schema` + `PREPARE/EXECUTE`
- Triggers `BEFORE UPDATE` substituem o `onupdate` (com `DELIMITER $$`)
- Relatórios JSON (`fn_dashboard_estatisticas`, `fn_relatorio_chat`) são
  MySQL FUNCTIONS chamadas via `SELECT fn(...)`
- Relatórios de conjunto de linhas (`fn_relatorio_automacoes`,
  `fn_buscar_mensagens`) são MySQL PROCEDUREs chamadas via `CALL`
