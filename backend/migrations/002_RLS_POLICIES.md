# Controle de Acesso (RLS) - Chat Schema

> **NOTA IMPORTANTE**: Este documento descreve o esquema **antigo** de Row Level
> Security do PostgreSQL/Supabase. O projeto foi migrado para **MySQL 8.0+**,
> que **não possui RLS**. O controle de acesso agora é feito **na camada de
> aplicação (backend)**: toda query filtra por `WHERE user_id = ?` usando o
> usuário autenticado. Mantemos este documento apenas como registro histórico
> do que as políticas RLS faziam.

## Visão Geral (contexto histórico)

As políticas RLS garantiam que os usuários só pudessem acessar seus próprios dados. Todas as três tabelas (`chat_sessions`, `messages`, `automation_logs`) tinham RLS habilitado.

## Tabela: `chat_sessions` (políticas antigas)

1. **SELECT**: Usuários podiam ver apenas suas próprias sessões
   - Condição: `auth.uid() = user_id`
2. **INSERT**: Usuários podiam criar suas próprias sessões
   - Condição: `auth.uid() = user_id`
3. **UPDATE**: Usuários podiam atualizar suas próprias sessões
   - Condição: `auth.uid() = user_id` (USING e WITH CHECK)
4. **DELETE**: Usuários podiam deletar suas próprias sessões
   - Condição: `auth.uid() = user_id`

## Tabela: `messages` (políticas antigas)

1. **SELECT**: Usuários viam mensagens apenas de suas próprias sessões (JOIN com `chat_sessions`)
2. **INSERT**: Usuários criavam mensagens em suas próprias sessões
3. **UPDATE/DELETE**: Não implementado (mensagens imutáveis para manter histórico íntegro)

## Tabela: `automation_logs` (políticas antigas)

1. **SELECT/INSERT**: Apenas próprios logs (`auth.uid() = user_id`)
2. **UPDATE**: Apenas próprios logs (USING e WITH CHECK)

## No MySQL

Em vez de políticas RLS, o backend aplica as mesmas regras em código:

- Todos os controllers/repositories filtram por `user_id` do token autenticado.
- As FKs usam `ON DELETE CASCADE` (sessão deletada → mensagens deletadas).
- Mensagens continuam imutáveis via regra de aplicação (sem rotas de update/delete).

## Testando o Controle de Acesso

```sql
-- Como usuário autenticado, você só deve ver suas próprias sessões
SELECT * FROM chat_sessions WHERE user_id = '<seu-user-id>';

-- (Equivalente MySQL do teste de política)
SELECT tablename FROM information_schema.tables
WHERE table_schema = DATABASE() AND table_name IN ('chat_sessions', 'messages', 'automation_logs');
```

## Notas Importantes

1. **Autenticação**: O backend valida o token (JWT/Firebase) e usa o `user_id` extraído
   para filtrar todas as consultas. Não existe bypass por service role no MySQL.
2. **Cascading Deletes**: As FKs com `ON DELETE CASCADE` garantem integridade
   (sessão deletada remove mensagens associadas).
3. **Imutabilidade de Mensagens**: Mensagens não podem ser editadas ou deletadas
   diretamente — regra mantida no backend.