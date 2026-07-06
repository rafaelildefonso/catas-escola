# Rodar o CATAS

## Backend (API Flask)

```bash
cd backend
.\venv\Scripts\activate
python run.py
```

Acessar: http://localhost:8000/health

## Worker (Automações Temporal)

```bash
cd backend
.\venv\Scripts\activate
python -m worker.entrypoint
$env:PYTHONPATH = "."
```

## Frontend (Flutter)

```bash
cd frontend
flutter run -d chrome --web-port 52159
flutter pub get
```

## Testes

```bash
cd backend
.\venv\Scripts\activate
python -m pytest tests/ -v
```
