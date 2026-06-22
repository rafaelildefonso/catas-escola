# Row Level Security (RLS) Policies - Chat Schema

## Visão Geral

As políticas RLS garantem que os usuários só possam acessar seus próprios dados. Todas as três tabelas (`chat_sessions`, `messages`, `automation_logs`) têm RLS habilitado.

## Tabela: `chat_sessions`

### Políticas Implementadas:

1. **SELECT**: Usuários podem ver apenas suas próprias sessões
   - Condição: `auth.uid() = user_id`

2. **INSERT**: Usuários podem criar suas próprias sessões
   - Condição: `auth.uid() = user_id`

3. **UPDATE**: Usuários podem atualizar suas próprias sessões
   - Condição: `auth.uid() = user_id` (tanto no USING quanto no WITH CHECK)

4. **DELETE**: Usuários podem deletar suas próprias sessões
   - Condição: `auth.uid() = user_id`

## Tabela: `messages`

### Políticas Implementadas:

1. **SELECT**: Usuários podem ver mensagens apenas de suas próprias sessões
   - Condição: Verifica se a sessão pertence ao usuário através de um JOIN com `chat_sessions`

2. **INSERT**: Usuários podem criar mensagens em suas próprias sessões
   - Condição: Verifica se a sessão pertence ao usuário antes de inserir

3. **UPDATE/DELETE**: Não implementado (mensagens são imutáveis para manter histórico íntegro)

## Tabela: `automation_logs`

### Políticas Implementadas:

1. **SELECT**: Usuários podem ver apenas seus próprios logs
   - Condição: `auth.uid() = user_id`

2. **INSERT**: Usuários podem criar seus próprios logs
   - Condição: `auth.uid() = user_id`

3. **UPDATE**: Usuários podem atualizar seus próprios logs
   - Condição: `auth.uid() = user_id` (tanto no USING quanto no WITH CHECK)

## Testando as Políticas

Para testar se as políticas estão funcionando corretamente:

```sql
-- Como usuário autenticado, você só deve ver suas próprias sessões
SELECT * FROM chat_sessions;

-- Tentar inserir uma sessão com user_id diferente deve falhar
INSERT INTO chat_sessions (user_id, title) 
VALUES ('outro-user-id', 'Tentativa de Hack'); -- Deve falhar

-- Verificar se as políticas estão ativas
SELECT tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN ('chat_sessions', 'messages', 'automation_logs');
```

## Notas Importantes

1. **Service Role Key**: O backend Python usa `SUPABASE_SERVICE_ROLE_KEY`, que **bypassa** as políticas RLS. Isso é necessário para operações administrativas, mas deve ser usado com cuidado.

2. **Anon Key**: O frontend Flutter usa `SUPABASE_ANON_KEY`, que **respeita** as políticas RLS. Isso garante segurança no cliente.

3. **Cascading Deletes**: Quando uma sessão é deletada, todas as mensagens associadas são automaticamente deletadas devido ao `ON DELETE CASCADE`.

4. **Imutabilidade de Mensagens**: Mensagens não podem ser editadas ou deletadas diretamente pelos usuários para manter a integridade do histórico de conversas.
