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


def create_app():
    app = Flask(__name__)

    app.config.from_prefixed_env()
    db_url = settings.DATABASE_URL or "sqlite:///catas_dev.db"
    app.config["SQLALCHEMY_DATABASE_URI"] = db_url
    app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

    CORS(app)
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
