<!-- #### Subir o Temporal Server

```bash
# Na raiz do projeto
docker-compose -f server/docker/temporal/docker-compose.yml up -d

# Parar Temporal
docker-compose -f server/docker/temporal/docker-compose.yml down
```

Acesse a UI: http://localhost:8080 -->

#### Subir o Server e Worker

```bash
# Na raiz do projeto
# 1° vez
docker-compose -f server/docker-compose.yml up -d --build

docker-compose -f server/docker-compose.yml up -d

# Verificar logs
docker-compose -f server/docker-compose.yml logs -f server
docker-compose -f server/docker-compose.yml logs -f worker

# Parar Server + Worker + DB
docker-compose -f server/docker-compose.yml down
```

Acesse a API: http://localhost:8000

---

### Rodando o Cliente (Flutter)

```bash
cd app_flutter

flutter run -d chrome --web-port 52159

flutter pub get

```

---

### Rodando localmente (sem Docker)

#### Backend (Python)

```bash
cd server

venv\Scripts\activate

python -m uvicorn app.main:app --reload

```
Acesse a API: http://localhost:8000

### Worker:

```bash
cd server/worker
python main.py

```

### Configurando a documentação (Mintlify)

```bash
mintlify dev
```

Acesse a documentação: http://localhost:3000