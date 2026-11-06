# Rodar o CATAS

## Pré-requisitos

- Python 3.11+
- Flutter SDK (`flutter doctor` sem erros)
- Android SDK + emulador criado (`flutter emulators` lista os disponíveis)
- Docker (opcional, para containerização)

---

## 1. Backend (API Flask)

```powershell
cd backend
.\venv\Scripts\activate
python run.py
```

Validar: http://localhost:8000/health → `{"status": "ok"}`

> O `.env` do backend já deve existir em `backend/.env` (ver `enviroments_setup.txt` na raiz para gerar).

## 2. Worker

O Worker é necessário para executar automações.

```powershell
cd backend
.\venv\Scripts\activate
python -m worker.entrypoint
```

Validar: http://localhost:8001/health → `{"status": "ok"}`

---

## 3. Agendador de automações

O agendador é obrigatório para automações recorrentes, como "todo dia às 11:38". Ele consulta as execuções vencidas a cada 15 segundos e as encaminha ao worker.

Em um terceiro terminal:

```powershell
cd backend
.\venv\Scripts\activate
python -m services.automation.scheduler
```

O processo permanece em execução e não expõe uma porta HTTP. Mantenha este terminal aberto enquanto quiser que os agendamentos sejam executados.

---

## 4. Frontend

```powershell
cd frontend
flutter run -d chrome --web-port 52159
```

No Chrome o backend é alcançado por `localhost:8000` (ou a porta definida em `frontend/.env`).

---

## Testes

```bash
cd backend
.\venv\Scripts\activate
python -m pytest tests/ -v
```

---

## Comandos Úteis

### Lint (Python)

```bash
cd backend
ruff check .
ruff format .
```

### Testes (Flutter)

```bash
cd frontend
flutter test
```

---

## Encerrar tudo

```powershell
# backend (encontre o PID na porta)
Get-NetTCPConnection -LocalPort 8000 -State Listen | Select-Object -ExpandProperty OwningProcess | ForEach-Object { Stop-Process -Id $_ }

# worker (porta 8001)
Get-NetTCPConnection -LocalPort 8001 -State Listen | Select-Object -ExpandProperty OwningProcess | ForEach-Object { Stop-Process -Id $_ }

# scheduler não usa porta: no terminal dele, pressione Ctrl+C
```

## Troubleshooting

| Problema | Causa/Solução |
|----------|---------------|
| `OSError: [Errno 10013]` ao subir o backend | Porta ocupada (ex.: `sirius-backend.exe`). Use `$env:PORT = "8001"` |
| Build falha com `dart:html is not available on this platform` | Import direto de `dart:html` fora de arquivos `_web.dart`. Use o helper condicional `core/web_page_renderer.dart` (`navigateTo`) |
| App não abre após `Installing...` | `flutter run` travado em janela oculta. Use o fallback `am start` + `flutter attach` acima |
| Erro de conexão do app no emulador | Confira se o backend está na mesma porta do `--dart-define` e se `/health` responde |
| Worker não conecta | Verifique se `WORKER_URL` está configurado corretamente no `.env` |
| A automação recorrente não dispara | Inicie `python -m services.automation.scheduler` em um terceiro terminal. API e worker, sozinhos, não executam agendamentos. |
| Erro de porta no Docker | Verifique se as portas 8000 e 8001 não estão em uso |

---

## Fluxo de Execução

```
1. Iniciar Backend (port 8000)
2. Iniciar Worker (port 8001)
3. Iniciar Scheduler (automações recorrentes)
4. Iniciar Flutter (emulador ou Chrome)
5. Fazer login no app
6. Enviar mensagem no chat
7. IA processa e gera plano
8. Worker executa automação
9. Resultado exibido no app
```
