import traceback
import os
import json
import logging

from flask import Flask, jsonify, request
from flask_cors import CORS
from dotenv import load_dotenv

from core.config import settings
from core.errors import sanitize_error
from core.security import get_current_user

import firebase_admin
from firebase_admin import credentials

load_dotenv()

logger = logging.getLogger(__name__)


def create_app():
    app = Flask(__name__)

    app.config.from_prefixed_env()

    CORS(app, resources={r"/api/*": {"origins": "*"}})

    @app.errorhandler(Exception)
    def global_exception_handler(exc):
        logger.error(f"Unhandled error: {traceback.format_exc()}")
        return jsonify({"detail": sanitize_error(exc)}), 500

    @app.errorhandler(404)
    def not_found(e):
        return jsonify({"detail": "Not found"}), 404

    @app.errorhandler(403)
    def forbidden(e):
        return jsonify({"detail": str(e.descriptor or "Acesso negado")}), 403

    @app.errorhandler(401)
    def unauthorized(e):
        return jsonify({"detail": str(e.descriptor or "Não autorizado")}), 401

    from controllers.user import user_bp
    from controllers.chat import chat_bp
    from controllers.chatbot import chatbot_bp
    from controllers.automations import automations_bp
    from controllers.integrations import integrations_bp
    from controllers.payments import payments_bp
    from controllers.feedback import feedback_bp
    from controllers.webhooks import webhooks_bp
    from controllers.webhook_receiver import webhook_receiver_bp
    from controllers.prompt_improve import prompt_bp

    app.register_blueprint(user_bp)
    app.register_blueprint(chat_bp)
    app.register_blueprint(chatbot_bp, url_prefix="/api/v1/chat")
    app.register_blueprint(automations_bp)
    app.register_blueprint(integrations_bp)
    app.register_blueprint(payments_bp)
    app.register_blueprint(feedback_bp)
    app.register_blueprint(webhooks_bp)
    app.register_blueprint(webhook_receiver_bp)
    app.register_blueprint(prompt_bp)

    @app.route("/health")
    def health_check():
        return jsonify({"status": "ok"})

    @app.route("/")
    def root():
        return jsonify({
            "message": "CATAS API",
            "version": "0.1.0",
            "docs": "/"
        })

    return app


app = create_app()

try:
    if not firebase_admin._apps:
        json_content = os.environ.get("FIREBASE_ADMIN_CREDENTIALS_JSON")
        cred_path = os.environ.get("FIREBASE_ADMIN_SDK_JSON_PATH")

        if json_content:
            try:
                cert_dict = json.loads(json_content)
                cred = credentials.Certificate(cert_dict)
                firebase_admin.initialize_app(cred)
                logger.info("Firebase Admin inicializado via FIREBASE_ADMIN_CREDENTIALS_JSON.")
            except Exception as json_e:
                logger.error(f"Erro ao parsear JSON das credenciais Firebase: {json_e}")
        elif cred_path and os.path.exists(cred_path):
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
            logger.info("Firebase Admin inicializado via FIREBASE_ADMIN_SDK_JSON_PATH.")
        else:
            firebase_admin.initialize_app()
            logger.info("Firebase Admin inicializado via Application Default Credentials.")
except Exception as e:
    logger.warning(f"Aviso: Não foi possível inicializar o Firebase Admin: {e}")

if not os.getenv("GROQ_API_KEY"):
    logger.warning("GROQ_API_KEY não configurada. Pipeline de meta-automação estará indisponível.")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000, debug=True)
