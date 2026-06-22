# MCP Gmail Integration — Plano de Implementação

## Goal
Refatorar `send_gmail.py` e `create_draft.py` para usarem MCP Client, delegando a execução real ao `mcp_gmail_server.py` já existente, enquanto mantém 100% de compatibilidade com o Temporal Workflow.

## Arquitetura Final

```
Temporal Workflow
  └── send_email(params)          ← assinatura NÃO muda
        └── _call_mcp_tool()      ← NOVO: MCP Client helper
              └── mcp_gmail_server.py (subprocess stdio)
                    └── Gmail API (Google OAuth2)
```

## Arquivos Afetados

| Arquivo | Ação | Status |
|---------|------|--------|
| `server/worker/activities/gmail/mcp_client.py` | **CRIAR** — helper MCP Client reutilizável | ✅ |
| `server/worker/activities/gmail/send_gmail.py` | **REFATORAR** — trocar chamada direta por MCP Client | ✅ |
| `server/worker/activities/gmail/create_draft.py` | **REFATORAR** — trocar chamada direta por MCP Client | ✅ |
| `server/requirements.txt` | **EDITAR** — adicionar `mcp` | ✅ |

## Tasks

- [x] **Task 1**: Criar `mcp_client.py` — helper MCP Client reutilizável ✅
- [x] **Task 2**: Refatorar `send_gmail.py` — usar MCP Client ✅
- [x] **Task 3**: Refatorar `create_draft.py` — usar MCP Client ✅
- [x] **Task 4**: Adicionar `mcp` ao `requirements.txt` ✅
- [x] **Task 5**: Verificação de compatibilidade ✅
  - `mcp_client` import OK
  - `send_email` import OK
  - `create_draft` import OK
  - `get_unread_emails` import OK (não foi alterado, mantém Google API direta)
  - `mcp` v1.27.0 instalado com sucesso

## Done When
- [x] `send_gmail.py` usa MCP Client ao invés de Google API direta
- [x] `create_draft.py` usa MCP Client ao invés de Google API direta
- [x] `mcp_gmail_server.py` é o ÚNICO arquivo que toca a Google API (para send/draft)
- [x] Workflow existente continua funcionando sem nenhuma mudança
- [x] `mcp` está no `requirements.txt`

## Notes
- **Zero mudanças** em `automation_workflow.py` e `worker/main.py`
- O `oauth_token` continua sendo injetado pelo workflow via `get_user_integration()`
- O MCP Server recebe o token como argumento da tool, mantendo o fluxo SaaS
- Subprocess por chamada (simplicidade > performance neste estágio)
- `get_unread_emails` NÃO foi migrado para MCP (não está exposto no MCP Server)
