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
python run.py                # porta padrão 8000
```

Para usar outra porta (ex.: se a 8000 estiver ocupada):

```powershell
$env:PORT = "8001"
python run.py
```

Validar: http://localhost:8000/health → `{"status": "ok"}`

> O `.env` do backend já deve existir em `backend/.env` (ver `enviroments_setup.txt` na raiz para gerar).

## 2. Worker (FastAPI)

O Worker é necessário para executar automações.

```powershell
cd backend
.\venv\Scripts\activate
python -m worker.server      # porta 8001
```

Validar: http://localhost:8001/health → `{"status": "ok"}`

---

## 3. Emulador Android

```powershell
# listar emuladores disponíveis
flutter emulators

# iniciar (se ainda não estiver rodando)
flutter emulators --launch Medium_Phone_API_36.1

# conferir se está online (deve aparecer como "device")
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" devices
```

Se `--launch` falhar com "Running multiple emulators with the same AVD", o emulador **já está aberto** — só use.

## 4. Frontend (Flutter) no emulador

```powershell
cd frontend
flutter pub get

# build + install + launch com a API apontando para o backend local
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

- `10.0.2.2` = localhost da máquina host visto de dentro do emulador Android.
- Se o backend estiver na porta padrão, use `http://10.0.2.2:8000/api/v1`.
- O `.env` do frontend (`frontend/.env`) usa `localhost:8000`; o app converte para `10.0.2.2` automaticamente (`lib/core/app_config.dart`), mas o `--dart-define` tem prioridade.

### Fallback: app não sobe após o install

Em janela sem console, o `flutter run` pode travar depois de `Installing...`. Nesse caso:

```powershell
# lançar a activity direto (o APK já foi compilado com o dart-define)
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" shell am start -n com.catas.catas/.MainActivity

# reconectar hot reload
flutter attach -d emulator-5554
```

### Hot reload

Com `flutter run` ou `flutter attach` conectado, basta salvar um arquivo `.dart`.

## 5. Frontend (Flutter) no Chrome

```powershell
cd frontend
flutter pub get
flutter run -d chrome --web-port 52159
```

No Chrome o backend é alcançado por `localhost:8000` (ou a porta definida em `frontend/.env`).

---

## 6. Docker (Alternativa)

Para rodar backend + worker com Docker:

```powershell
cd backend
docker-compose up -d
```

Serviços:
- `catas_server`: API Flask (port 8000)
- `catas_worker`: FastAPI Worker (port 8001)

Para verificar se os containers estão rodando:

```powershell
docker-compose ps
```

Para ver logs:

```powershell
docker-compose logs -f
```

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

# app no emulador
adb shell am force-stop com.catas.catas

# Docker
cd backend
docker-compose down
```

## Troubleshooting

| Problema | Causa/Solução |
|----------|---------------|
| `OSError: [Errno 10013]` ao subir o backend | Porta ocupada (ex.: `sirius-backend.exe`). Use `$env:PORT = "8001"` |
| Build falha com `dart:html is not available on this platform` | Import direto de `dart:html` fora de arquivos `_web.dart`. Use o helper condicional `core/web_page_renderer.dart` (`navigateTo`) |
| App não abre após `Installing...` | `flutter run` travado em janela oculta. Use o fallback `am start` + `flutter attach` acima |
| Erro de conexão do app no emulador | Confira se o backend está na mesma porta do `--dart-define` e se `/health` responde |
| Worker não conecta | Verifique se `WORKER_URL` está configurado corretamente no `.env` |
| Erro de porta no Docker | Verifique se as portas 8000 e 8001 não estão em uso |

---

## Fluxo de Execução

```
1. Iniciar Backend (port 8000)
2. Iniciar Worker (port 8001)
3. Iniciar Flutter (emulador ou Chrome)
4. Fazer login no app
5. Enviar mensagem no chat
6. IA processa e gera plano
7. Worker executa automação
8. Resultado exibido no app
```
