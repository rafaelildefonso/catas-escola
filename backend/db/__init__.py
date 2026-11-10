import os
import psycopg2
from psycopg2 import pool, extras
from urllib.parse import urlparse
from dotenv import load_dotenv

load_dotenv()

# A URL centraliza os dados de conexão e deve ser fornecida pelo ambiente, nunca pelo código-fonte.
DATABASE_URL = os.getenv("DATABASE_URL")

if not DATABASE_URL:
    raise ValueError("DATABASE_URL não configurado")

parsed = urlparse(DATABASE_URL)

# Pool compartilhado: reutiliza conexões PostgreSQL entre requisições concorrentes.
_pool = psycopg2.pool.ThreadedConnectionPool(
    minconn=1,
    maxconn=20,
    database=parsed.path[1:],
    user=parsed.username,
    password=parsed.password,
    host=parsed.hostname,
    port=parsed.port
)

def get_connection():
    # Obtém uma conexão livre do pool. Quem a obtém deve liberá-la ao final.
    return _pool.getconn()

def release_connection(conn):
    # Devolve a conexão ao pool para que ela possa ser reutilizada.
    _pool.putconn(conn)

def execute(query, params=None):
    # Executa comandos de escrita; o contexto da conexão confirma ou desfaz a transação automaticamente.
    conn = get_connection()
    try:
        with conn:
            with conn.cursor() as cur:
                cur.execute(query, params)
    finally:
        release_connection(conn)

def fetch_one(query, params=None):
    # RealDictCursor permite devolver o registro como dicionário, adequado para a camada HTTP.
    conn = get_connection()
    try:
        with conn.cursor(cursor_factory=extras.RealDictCursor) as cur:
            cur.execute(query, params)
            return dict(cur.fetchone()) if cur.rowcount > 0 else None
    finally:
        release_connection(conn)

def fetch_all(query, params=None):
    # Busca todas as linhas e normaliza cada uma em dict antes de liberar a conexão.
    conn = get_connection()
    try:
        with conn.cursor(cursor_factory=extras.RealDictCursor) as cur:
            cur.execute(query, params)
            return [dict(row) for row in cur.fetchall()]
    finally:
        release_connection(conn)
