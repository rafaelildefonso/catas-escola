# Controle de Acesso por Tabela (pós-migração MySQL)

> **NOTA**: O projeto migrou de PostgreSQL para **MySQL 8.0+**.
> O MySQL não possui Row Level Security (RLS). A matriz abaixo registra o
> comportamento **equivalente implementado na camada de aplicação (backend)**.

| Tabela | Regra de acesso (backend) |
|--------|---------------------------|
| `profiles` | SELECT/UPDATE apenas do próprio `id` (usuário autenticado) |
| `chat_sessions`, `messages` | SELECT/INSERT apenas onde `user_id` (sessão) pertence ao usuário |
| `integrations` | ALL filtrado por `user_id = <usuário>` (tokens criptografados) |
| `automations` (definições) | ALL filtrado por `user_id` |
| `automation_runs` | SELECT/INSERT/UPDATE filtrado por `user_id` |
| `automation_step_logs` | SELECT se `user_id = <usuário>` e `user_id` preenchido |
| `automation_feedback` | ALL filtrado por `user_id` |
| `automation_generation_logs` | apenas leitura administrativa (INSERT do worker) |
| `ia_memory` | ALL filtrado por `user_id` |
| `notifications` | SELECT/UPDATE filtrado por `user_id` |
| `user_devices` | ALL filtrado por `user_id` |

**Notas**

- O worker FastAPI/automations escreve em `automation_step_logs` e `automation_runs`
  usando o `user_id` da execução (não há bypass de segurança no MySQL).
- O app Flutter lê dados sempre com filtro `user_id` do usuário autenticado.
- Toda query de leitura/escrita do backend deve incluir `WHERE user_id = <autenticado>`.