# Roteiro da demonstração do CATAS

**Duração sugerida:** 6 a 8 minutos  
**Objetivo do vídeo:** mostrar que qualquer pessoa consegue criar, agendar, executar e alterar uma automação conversando com a IA, sem escrever JSON ou configurar módulos manualmente.

Este roteiro cobre as funcionalidades 11, 12, 13, 15, 16, 17 e 18 do `TODO.md`.

## Ideia principal da apresentação

Use uma única automação como fio condutor:

> Enviar um e-mail de demonstração a cada minuto.

Depois da primeira execução, altere a frequência para todos os dias às 9h. Isso demonstra criação, agendamento e alteração por linguagem natural, além de evitar vários e-mails depois do vídeo.

## Preparação antes de gravar

- Inicie a API, o worker e o scheduler.
- Confira se API e worker usam o mesmo `WORKER_SHARED_SECRET`.
- Entre com uma conta de demonstração.
- Conecte uma conta de teste do Gmail em **Integrações**.
- Use um endereço de e-mail seu como destinatário.
- Confirme que o sino de **Notificações** aparece no cabeçalho web.
- Faça um teste completo antes da gravação.
- Deixe pelo menos uma execução disponível em **Relatórios**.
- Se mostrar cobrança, use apenas o modo de teste do Stripe.
- Feche abas, notificações e janelas que possam revelar dados pessoais ou credenciais.

## Prompt principal

Substitua `SEU_EMAIL_DE_TESTE` antes de gravar:

```text
Crie uma automação chamada Demonstração CATAS que envie um e-mail para rafaelfurtado313@gmail.com com o assunto "Demonstração CATAS" e a mensagem "A automação do CATAS foi executada com sucesso" a cada 1 minuto.
```

Resultado esperado:

- A IA entende que a tarefa é recorrente.
- A IA escolhe a ação de envio de e-mail.
- A automação é salva como ativa.
- A resposta confirma o intervalo em linguagem simples.
- A página **Automações** mostra a próxima execução.

## Roteiro de gravação

### 0:00–0:30 — Apresentar o propósito

**Na tela:** abra o CATAS e mostre rapidamente o menu principal.

**Fale:**

> “Este é o CATAS, um sistema para criar automações de forma acessível. Em vez de preencher configurações técnicas ou escrever JSON, eu descrevo o resultado que quero. A IA escolhe os passos, define o agendamento e prepara a automação.”

### 0:30–1:00 — Mostrar o ponto de entrada

**Faça:**

1. Abra **Automações**.
2. Mostre que a página apresenta as automações ativas, a frequência e a próxima execução.
3. Clique em **Criar pelo chat**.

**Fale:**

> “A criação começa pelo chat. A pessoa não precisa conhecer módulos, campos internos ou formatos de configuração.”

### 1:00–2:10 — Criar a automação pelo chat

**Faça:**

1. Complete a frase iniciada no campo do chat usando o **Prompt principal**.
2. Envie a mensagem.
3. Aguarde a resposta da IA.
4. Leia a confirmação da criação e do agendamento.

**Fale enquanto aguarda:**

> “Eu informei somente o destinatário, o conteúdo e a frequência. A IA está interpretando o pedido, escolhendo as ações disponíveis e validando se possui todos os dados necessários.”

**Depois da resposta, fale:**

> “A automação foi criada e ativada. Como ela é recorrente, o sistema salvou o agendamento e aguardará o horário correto para executar.”

### 2:10–2:55 — Mostrar a automação ativa

**Faça:**

1. Volte para **Automações**.
2. Mostre o nome **Demonstração CATAS**.
3. Mostre a frequência e a próxima execução.
4. Clique em **Ver fluxo** e mostre os passos que a IA estruturou, na ordem em que serão executados.
5. Abra o menu novamente para mostrar **Executar agora**, **Pedir alteração à IA**, **Pausar** e **Excluir**.

**Fale:**

> “A interface apresenta o fluxo de trabalho em uma sequência compreensível: o que cada passo fará, quando a automação será executada e quais ações eu posso tomar. Os identificadores internos continuam escondidos.”

### 2:55–3:35 — Confirmar a execução e a notificação

**Faça:**

1. Aguarde a execução agendada. Enquanto espera, você pode mostrar rapidamente **Integrações**.
2. Confirme que o e-mail chegou na conta de teste.
3. Clique no sino **Notificações** no cabeçalho web.
4. Abra a notificação da automação concluída.

Se o scheduler demorar, use **Executar agora** e explique que o botão antecipa uma execução sem remover o agendamento.

**Fale:**

> “Quando a execução termina ou falha, o CATAS registra uma notificação. Se o Firebase estiver configurado, o aviso também pode chegar como notificação push.”

### 3:35–4:25 — Alterar a automação por linguagem natural

**Faça:**

1. Volte para **Automações**.
2. Abra o menu da automação.
3. Escolha **Pedir alteração à IA**.
4. Use este prompt:

```text
Altere a frequência para todos os dias às 9h e mantenha o destinatário, o assunto e a mensagem atuais.
```

5. Confirme a alteração.
6. Mostre que a frequência e a próxima execução foram atualizadas.

**Fale:**

> “Para alterar a automação, eu também uso uma frase. A IA preserva o que não pedi para mudar e atualiza somente o horário. Assim, não preciso editar estruturas técnicas.”

### 4:25–5:20 — Mostrar relatórios e exportação

**Faça:**

1. Abra **Relatórios**.
2. Mostre os dados de automações e conversas.
3. Clique em **Exportar**.
4. Mostre as opções **CSV**, **Excel (.xlsx)** e **PDF**.
5. Exporte um dos formatos e mostre que o arquivo foi gerado.

**Fale:**

> “As execuções ficam disponíveis nos relatórios. Os dados podem ser exportados em CSV, Excel ou PDF, dependendo de como serão analisados ou compartilhados.”

### 5:20–6:10 — Mostrar planos e assinatura

**Faça:**

1. Abra **Planos**.
2. Mostre os planos e seus limites.
3. Se o Stripe estiver configurado em modo de teste, inicie o checkout.
4. Se já existir uma assinatura de teste, mostre o acesso ao portal de cobrança.

**Fale:**

> “Os planos controlam os limites de uso. O checkout e o gerenciamento da assinatura usam o Stripe. A atualização do plano acontece pelos eventos de cobrança e não pode ser alterada manualmente no perfil.”

### 6:10–6:35 — Encerrar

**Na tela:** volte para **Automações** e deixe a automação com o horário diário visível.

**Fale:**

> “Neste fluxo, eu criei uma automação apenas descrevendo o resultado, acompanhei a execução, recebi uma notificação e alterei o horário usando outra frase. O CATAS cuida da parte técnica e deixa para a pessoa apenas as decisões que ela entende.”

## Prompts alternativos para a demonstração

Troque os valores em letras maiúsculas pelos dados da sua conta de teste.

### Enviar um e-mail imediatamente

Requer Gmail conectado.

```text
Crie uma automação para enviar agora um e-mail para SEU_EMAIL_DE_TESTE com o assunto "Teste imediato do CATAS" e a mensagem "Esta ação foi criada pelo chat".
```

### Criar um rascunho de e-mail

Requer Gmail conectado.

```text
Crie agora um rascunho de e-mail para SEU_EMAIL_DE_TESTE com o assunto "Reunião do projeto" e a mensagem "Olá, podemos conversar amanhã às 14h?".
```

### Enviar um lembrete diário

Requer Gmail conectado.

```text
Crie uma automação chamada Lembrete diário que envie um e-mail para SEU_EMAIL_DE_TESTE todos os dias às 9h com o assunto "Lembrete diário" e a mensagem "Confira as tarefas prioritárias de hoje".
```

### Criar uma pasta no Google Drive

Requer Google Drive conectado.

```text
Crie uma automação para criar agora uma pasta no meu Google Drive chamada Documentos da demonstração CATAS.
```

### Criar uma planilha

Requer Google Sheets conectado.

```text
Crie uma automação para criar agora uma planilha chamada Controle da demonstração CATAS.
```

### Adicionar dados a uma planilha existente

Requer Google Sheets conectado. Use o ID real da planilha.

```text
Crie uma automação para adicionar agora uma linha na planilha PLANILHA_ID, no intervalo Página1!A:C, com os valores "Demonstração", "Concluída" e "Hoje".
```

### Criar um evento no calendário

Requer Google Calendar conectado. Informe uma data futura completa.

```text
Crie uma automação para adicionar ao meu Google Calendar o evento "Apresentação do CATAS" no dia 30 de outubro de 2026, das 14h às 15h.
```

### Consultar eventos do calendário

Requer Google Calendar conectado.

```text
Crie uma automação para consultar agora os eventos do meu Google Calendar dos próximos sete dias.
```

## Prompts para alterar uma automação existente

Use estas frases em **Pedir alteração à IA**:

```text
Altere a frequência para a cada 30 minutos e mantenha o restante igual.
```

```text
Troque o destinatário para NOVO_EMAIL e mantenha o assunto, a mensagem e o horário.
```

```text
Mude o assunto do e-mail para "Relatório automático do CATAS" e não altere mais nada.
```

```text
Passe a executar somente nos dias úteis às 8h.
```

## Prompt para mostrar que a IA pede informações

Este exemplo está incompleto de propósito:

```text
Crie uma automação para enviar um e-mail todos os dias.
```

Resultado esperado: a IA deve pedir o destinatário, o horário, o assunto ou a mensagem antes de criar a automação. Isso demonstra que o sistema não inventa dados importantes.

## Plano B para a gravação

Se uma integração externa falhar:

1. Mostre a mensagem do CATAS indicando qual integração precisa ser conectada.
2. Abra **Integrações** e mostre onde a conexão é feita.
3. Use uma gravação real feita anteriormente apenas para mostrar o resultado final.
4. Explique claramente quando uma credencial externa não estiver disponível.

Se o scheduler demorar:

1. Use **Executar agora**.
2. Mostre que o agendamento continua salvo.
3. Volte à lista e mostre a próxima execução.

## Checklist final

- [ ] O prompt contém um endereço de teste válido.
- [ ] Gmail está conectado.
- [ ] API, worker e scheduler estão rodando.
- [ ] O e-mail chegou no ensaio.
- [ ] A notificação apareceu na lista.
- [ ] Existe pelo menos um relatório para exportar.
- [ ] O Stripe está em modo de teste ou essa parte será apenas explicada.
- [ ] Nenhuma chave, token ou dado pessoal aparece no vídeo.
- [ ] A automação deixou de executar a cada minuto depois da demonstração.
