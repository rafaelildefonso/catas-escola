import os
import psycopg2
from psycopg2 import pool, extras
from urllib.parse import urlparse
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")

if not DATABASE_URL:
    raise ValueError("DATABASE_URL não configurado")

parsed = urlparse(DATABASE_URL)

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
    return _pool.getconn()

def release_connection(conn):
    _pool.putconn(conn)

def execute(query, params=None):
    conn = get_connection()
    try:
        with conn:
            with conn.cursor() as cur:
                cur.execute(query, params)
    finally:
        release_connection(conn)

def fetch_one(query, params=None):
    conn = get_connection()
    try:
        with conn.cursor(cursor_factory=extras.RealDictCursor) as cur:
            cur.execute(query, params)
            return dict(cur.fetchone()) if cur.rowcount > 0 else None
    finally:
        release_connection(conn)

def fetch_all(query, params=None):
    conn = get_connection()
    try:
        with conn.cursor(cursor_factory=extras.RealDictCursor) as cur:
            cur.execute(query, params)
            return [dict(row) for row in cur.fetchall()]
    finally:
        release_connection(conn)
