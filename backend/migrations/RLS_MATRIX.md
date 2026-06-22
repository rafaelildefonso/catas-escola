# Matriz RLS (resumo pós-migrações 009–010)

| Tabela | Cliente (anon/authenticated) | Service role / backend |
|--------|------------------------------|-------------------------|
| `profiles` | SELECT/UPDATE próprio `id` | bypass |
| `chat_sessions`, `messages` | políticas `chat_manage` / `messages_manage` | bypass |
| `integrations` | ALL onde `user_id = auth.uid()` (tokens criptografados) | bypass |
| `automations` (definições) | ALL próprio `user_id` | bypass |
| `automation_runs` | SELECT próprio `user_id` | bypass (INSERT/UPDATE) |
| `automation_step_logs` | SELECT se `user_id = auth.uid()` e `user_id` preenchido | bypass (worker) |
| `automation_feedback` | ALL próprio `user_id` | bypass |
| `automation_generation_logs` | SELECT negado (`false`) | bypass (INSERT leitura admin) |
| `ia_memory` | ALL próprio `user_id` | bypass |
| `notifications` | SELECT/UPDATE próprio | bypass |
| `user_devices` | ALL próprio | bypass |

**Notas**

- O worker Temporal e o FastAPI devem usar `SUPABASE_SERVICE_ROLE_KEY` para escrita em `automation_step_logs` e `automation_runs`.
- O app Flutter assina Realtime em `automation_step_logs` filtrando por `automation_id`; com RLS, cada linha precisa de `user_id` preenchido pelo worker (`report_status`).
