import os
import json
import logging

from flask import Flask, jsonify
from flask_cors import CORS
from dotenv import load_dotenv

from extensions import db
from core.config import settings
from core.errors import sanitize_error

import firebase_admin
from firebase_admin import credentials

load_dotenv()

logger = logging.getLogger(__name__)


def resolver_database_url() -> str:
    """Resolve a URI do banco de dados.

    Prioridade:
    1. DATABASE_URL do ambiente (MySQL/PostgreSQL em producao).
    2. SQLite local (backend/instance/catas_dev.db) quando em desenvolvimento.
    """
    if settings.DATABASE_URL:
        return settings.DATABASE_URL

    if os.getenv("ENVIRONMENT", "development") != "development":
        raise RuntimeError(
            "DATABASE_URL nao configurada. Defina a connection string do banco "
            "(ex.: mysql+pymysql://user:senha@host:3306/catas_db) fora do ambiente de desenvolvimento."
        )

    instance_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "instance")
    os.makedirs(instance_dir, exist_ok=True)
    caminho_sqlite = os.path.join(instance_dir, "catas_dev.db")
    logger.info("DATABASE_URL vazia: usando SQLite local em %s", caminho_sqlite)
    return "sqlite:///" + caminho_sqlite.replace("\\", "/")


def create_app():
    app = Flask(__name__)

    app.config.from_prefixed_env()
    app.config["SQLALCHEMY_DATABASE_URI"] = resolver_database_url()
    app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
    app.config["SQLALCHEMY_ENGINE_OPTIONS"] = {
        "pool_pre_ping": True,
        "pool_recycle": 280,
    }

    is_dev = os.getenv("ENVIRONMENT", "development") == "development"
    if is_dev:
        CORS(app, supports_credentials=True, allow_headers=["Content-Type", "Authorization"], methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"])
    else:
        CORS(app, origins=["https://catas-ai.vercel.app", "https://www.catas-ai.vercel.app"], supports_credentials=True, allow_headers=["Content-Type", "Authorization"], methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"])
    db.init_app(app)

    from routes import registrar_rotas
    registrar_rotas(app)

    @app.errorhandler(Exception)
    def global_exception_handler(exc):
        logger.error(f"Unhandled error: {exc}", exc_info=True)
        return jsonify({"detail": sanitize_error(exc)}), 500

    @app.errorhandler(404)
    def not_found(e):
        return jsonify({"detail": "Not found"}), 404

    @app.errorhandler(403)
    def forbidden(e):
        return jsonify({"detail": str(e.descriptor or "Acesso negado")}), 403

    @app.errorhandler(401)
    def unauthorized(e):
        return jsonify({"detail": str(e.descriptor or "Nao autorizado")}), 401

    @app.route("/health")
    def health_check():
        return jsonify({"status": "ok"})

    @app.route("/")
    def root():
        return jsonify({
            "message": "CATAS API",
            "version": "0.2.0",
            "docs": "/"
        })

    return app


def init_firebase():
    try:
        if not firebase_admin._apps:
            json_content = os.environ.get("FIREBASE_ADMIN_CREDENTIALS_JSON")
            cred_path = os.environ.get("FIREBASE_ADMIN_SDK_JSON_PATH")

            if json_content:
                cert_dict = json.loads(json_content)
                cred = credentials.Certificate(cert_dict)
                firebase_admin.initialize_app(cred)
                logger.info("Firebase Admin inicializado via FIREBASE_ADMIN_CREDENTIALS_JSON.")
            elif cred_path and os.path.exists(cred_path):
                cred = credentials.Certificate(cred_path)
                firebase_admin.initialize_app(cred)
                logger.info("Firebase Admin inicializado via FIREBASE_ADMIN_SDK_JSON_PATH.")
            else:
                firebase_admin.initialize_app()
                logger.info("Firebase Admin inicializado via Application Default Credentials.")
    except Exception as e:
        logger.warning(f"Aviso: Nao foi possivel inicializar o Firebase Admin: {e}")
