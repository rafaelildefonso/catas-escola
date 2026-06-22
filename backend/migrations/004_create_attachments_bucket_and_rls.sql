-- 1. Criar o bucket de anexos se não existir
INSERT INTO storage.buckets (id, name, public)
VALUES ('attachments', 'attachments', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Permitir que usuários autenticados façam upload de arquivos para sua própria pasta
-- O caminho esperado é {user_id}/{filename}
CREATE POLICY "Permitir upload de anexos próprios"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'attachments' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- 3. Permitir que usuários autenticados visualizem/listem seus próprios arquivos (Metadata)
CREATE POLICY "Permitir visualização de anexos próprios"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'attachments' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- 4. Permitir que usuários autenticados deletem seus próprios arquivos
CREATE POLICY "Permitir deleção de anexos próprios"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'attachments' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- 5. Permitir acesso público para LEITURA (SELECT) do conteúdo dos arquivos
-- Isso é necessário para que as URLs públicas (getPublicUrl) funcionem no Chat 
-- para o destinatário ou se o link for compartilhado.
CREATE POLICY "Acesso público para leitura de anexos"
ON storage.objects FOR SELECT
TO public
USING ( bucket_id = 'attachments' );
