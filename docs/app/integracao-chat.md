# Integração do Chat

O fluxo de comunicação entre o App Flutter e o Backend é centralizado no `ChatRepository` e gerenciado pelo `ChatProvider` para estado reativo.

## Fluxo de Mensagem

1. **Envio**: O usuário digita a mensagem e o app chama `chatProvider.sendMessage(text)`.
2. **Repositório**: O `ChatRepository` faz um `POST` para o backend com o JWT do Supabase no cabeçalho `Authorization`.
3. **Espera Ativa**: Enquanto o backend processa (IA), o app exibe o estágio de "pensamento".
4. **Processamento de Ação**:
   - Se o backend retornar `actionTriggered: true`, o app renderiza um card específico (ex: `ActionCardCalendar`).
   - O usuário revisa os dados extraídos pela IA.
5. **Execução**: Ao confirmar no card, o app dispara a execução final para o endpoint de execução do backend.

## Gerenciamento de Sessão

- Se não houver um `conversation_id` ativo, o backend cria uma nova sessão automaticamente no primeiro envio.
- O app recebe o novo `session_id` e o `session_title` gerado pela IA e atualiza a interface local.

## Níveis de Modelo

O app envia o parâmetro `model` na requisição (ex: "CATAS Pro") baseado no nível de assinatura detectado no perfil do usuário. Isso define qual modelo do Gemini será usado no backend para processar a solicitação.

## Persistência e Estado

Para garantir uma experiência fluida no mobile, o `ChatProvider` gerencia a persistência local:
- **Rascunho**: Salvo em tempo real no `SharedPreferences` via ID `chat_message_draft`.
- **Busca na Web**: O estado do toggle de web search é persistido via `chat_web_search_enabled`.
- **Anexos**: O caminho do último arquivo selecionado é salvo para que o usuário não precise selecionar novamente se o app for reiniciado.

## Busca na Web

Quando ativado, o app envia o parâmetro `web_search: true` no payload da mensagem. Isso sinaliza ao backend para realizar pesquisas externas (via ferramenta de busca da IA) antes de formular a resposta final.
