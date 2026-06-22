# Sistema de Componentes de UI da IA

O CATAS utiliza um sistema de componentes dinâmicos para permitir que a IA interaja com o usuário além de simples texto. Isso permite que a IA solicite informações específicas, mostre previews de dados e solicite aprovações antes de executar ações.

## Arquitetura

O fluxo de funcionamento dos componentes segue este padrão:

1. **Prompt de Sistema**: O backend injeta as definições JSON dos componentes disponíveis no sistema de prompt da IA (`ai_service.py` chama `get_components_schema()`).
2. **Resposta da IA**: A IA retorna um JSON contendo o texto da resposta e uma lista de `components`.
3. **Renderização (Flutter)**: O `AIComponentFactory` interpreta o tipo do componente e renderiza o widget correspondente.
4. **Callbacks Interativos**: Componentes interativos possuem um callback `onResponse` que envia uma resposta estruturada de volta para a IA de forma oculta (`isHidden: true`).

## Tipos de Componentes

### 1. Interativos (Solicitam Ação)

Componentes que requerem uma entrada do usuário para continuar o fluxo.

| Tipo                | Descrição                                                    | Dados (`data`)                         |
| :------------------ | :----------------------------------------------------------- | :------------------------------------- |
| `action_approval`   | Solicita aprovação para executar uma ação em uma integração. | `title`, `description`, `danger_level` |
| `contact_select`    | Permite selecionar um ou mais contatos (email ou nome).      | `purpose`, `multi_select`              |
| `multiple_choice`   | Apresenta opções de escolha para resolver ambiguidades.      | `question`, `options: [{id, label}]`   |
| `drive_file_select` | Abre um seletor para arquivos no Google Drive.               | `purpose`, `multi_select`              |

### 2. Previews (Visualização de Dados)

Componentes apenas de leitura para pré-visualização de conteúdos.

| Tipo                     | Descrição                                                      | Dados (`data`)                                |
| :----------------------- | :------------------------------------------------------------- | :-------------------------------------------- |
| `preview_whatsapp`       | Mostra um balãozinho com o texto que será enviado no WhatsApp. | `message`, `to`                               |
| `preview_email_draft`    | Mostra um rascunho de email (assunto e corpo).                 | `subject`, `body`, `to`                       |
| `preview_calendar_event` | Mostra um card com detalhes de um evento no calendário.        | `title`, `start_time`, `end_time`, `location` |
| `preview_docs`           | Mostra um bloco de texto formatado como documento.             | `title`, `content`                            |
| `sheets_table_preview`   | Mostra uma tabela compacta de dados.                           | `title`, `headers`, `rows`                    |

## Comunicação e Callbacks

Quando o usuário interage com um componente (ex: clica em "Aprovar"), o `ChatProvider` executa o método `sendComponentResponse`.

Este método:

1. Formata a resposta do usuário em um texto padrão compreensível pela IA (ex: `[APROVADO] O usuário aprovou a ação`).
2. Adiciona uma mensagem ao histórico visualmente oculta no chat (`isHidden: true`).
3. Envia a mensagem para o backend para continuar o fluxo conversacional.

## Exemplo de JSON de Resposta

```json
{
  "response_text": "Entendido. Para quem devo enviar o convite da reunião?",
  "status": "requires_action",
  "components": [
    {
      "type": "contact_select",
      "data": {
        "purpose": "Selecione os participantes da reunião",
        "multi_select": true
      }
    }
  ]
}
```
