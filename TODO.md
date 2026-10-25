# TODO — Funcionalidades

## 7 — Anexar e enviar imagens

- [x] Implementar upload autenticado em `/api/v1/attachments`, com validação de tipo, tamanho e cota do plano.
- [x] Armazenar arquivos em bucket privado do Supabase Storage.
- [x] Integrar `StorageRepository` ao endpoint e permitir anexar imagens no chat.

## 8 — Anexar e gerenciar documentos PDF/DOCX

- [x] Reusar o endpoint de anexos, preservando o MIME e os metadados do arquivo.
- [x] Adicionar listagem, exclusão e URLs assinadas temporárias para acesso aos arquivos.
- [x] Criar tela de gerenciamento com visualização de PDF e prévia de texto DOCX.

## 11 — Agendamento automático de tarefas

- [x] Definir modelo de gatilho recorrente nas automações.
- [x] Implementar scheduler que dispara automações nos horários definidos.
- [x] Expor API `POST /automations/:id/schedule` para definir ou alterar o agendamento.

## 12 — Enviar e-mails automáticos por gatilho

- [x] Criar ação de envio de e-mail com destinatário, assunto, corpo e anexos.
- [x] Permitir que a IA inclua o envio de e-mail no plano da automação.
- [x] Testar o fluxo completo: agendamento → execução → e-mail.

## 13 — Configurar novas automações personalizadas

- [x] Criar automações pelo chat, em linguagem natural, com passos e horários definidos pela IA.
- [x] Persistir nas tabelas `automations` e `automation_runs`.
- [x] Permitir alteração em linguagem natural, pausa, ativação e exclusão.
- [x] Exibir o fluxo de trabalho em ordem, com nomes e descrições acessíveis, sem permitir edição técnica dos passos.

## 15 — Página de automações ativas

- [x] Criar tela que lista apenas automações ativas.
- [x] Expor filtro `/automations?status=active`.
- [x] Adicionar ações para executar, pausar, ativar, alterar, excluir e visualizar detalhes.

## 16 — Relatórios automáticos e exportação

- [x] Gerar CSV, Excel (XLSX) e PDF a partir dos relatórios.
- [x] Criar endpoint autenticado `/api/v1/relatorios/export` com seleção de formato.
- [x] Adicionar opção de exportação na tela de relatórios.

## 17 — Notificações e alertas de automação

- [x] Integrar Firebase Cloud Messaging (FCM) para notificações push.
- [x] Criar serviço que registra e envia notificações ao concluir ou falhar uma automação.
- [x] Criar lista de notificações conectada ao backend e acesso pelo cabeçalho web.

## 18 — Gerenciar assinatura de planos de uso

- [x] Integrar Stripe Checkout, portal de cobrança e webhook com validação de assinatura.
- [x] Conectar a tela de preços aos fluxos de assinatura e gerenciamento.
- [x] Criar endpoints de checkout, portal e status; sincronizar plano e créditos pelos eventos de cobrança.
- [x] Proteger os campos de plano e créditos contra alteração direta pelo CRUD de perfil.

## Pendências para executar a demonstração em ambiente real

- [ ] Aplicar as migrações `019_billing_and_attachments.sql` e `020_automation_scheduler.sql` no banco usado na demonstração.
- [ ] Configurar as credenciais de Supabase Storage, Firebase, Stripe, Google OAuth, IA e o segredo compartilhado do worker.
- [ ] Cadastrar os preços e o webhook no painel do Stripe e autorizar as integrações Google da conta de demonstração.
- [ ] Fazer um teste final no ambiente da apresentação com uma automação agendada e outra executada imediatamente.

---

As integrações ainda indisponíveis, como Notion, WhatsApp e Slack, continuam marcadas como “Chega em breve” na interface.
