# Migrations do Banco de Dados

Este diretório contém as migrations SQL para o banco de dados PostgreSQL (Supabase).

## 📋 Como Executar

### Opção 1: Via Supabase Dashboard (Recomendado)

1. Acesse o [Supabase Dashboard](https://app.supabase.com)
2. Selecione seu projeto
3. Vá em **SQL Editor**
4. Copie e cole o conteúdo do arquivo de migration
5. Clique em **Run**

### Opção 2: Via CLI do Supabase

```bash
# Instalar Supabase CLI (se ainda não tiver)
npm install -g supabase

# Fazer login
supabase login

# Linkar ao projeto
supabase link --project-ref seu-project-ref

# Executar migration
supabase db push
```

## 📁 Ordem de Execução

Execute as migrations na ordem numérica:

1. `001_create_page_analysis_cache.sql` - Cache de análises de página
2. `002_create_chat_schema.sql` - Schema completo de chat (sessões, mensagens, logs)

## ✅ Verificação

Após executar as migrations, verifique se as tabelas foram criadas:

```sql
-- Verificar tabelas criadas
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('chat_sessions', 'messages', 'automation_logs');

-- Verificar políticas RLS
SELECT tablename, policyname 
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN ('chat_sessions', 'messages', 'automation_logs');
```

## 🔒 Row Level Security (RLS)

Todas as tabelas têm RLS habilitado. As políticas garantem que:
- Usuários só podem ver/criar/editar/deletar suas próprias sessões
- Usuários só podem ver/criar mensagens em suas próprias sessões
- Usuários só podem ver/criar seus próprios logs de automação

## 📝 Notas

- As migrations usam `CREATE TABLE IF NOT EXISTS` para serem idempotentes
- Os índices são criados com `CREATE INDEX IF NOT EXISTS`
- Os triggers são criados com `CREATE OR REPLACE FUNCTION`
- As políticas RLS são criadas sem `IF NOT EXISTS` (se já existirem, dará erro - delete manualmente se necessário)
