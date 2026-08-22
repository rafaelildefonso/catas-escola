import os
import sys
import logging

# Garantir UTF-8 no Windows para evitar erros de encoding com emoji
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    sys.stderr.reconfigure(encoding='utf-8', errors='replace')

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

from application import create_app, init_firebase
from extensions import db

app = create_app()

with app.app_context():
    db.create_all()
    logger.info("Tabelas do banco verificadas/criadas.")

init_firebase()

if not os.getenv("GROQ_API_KEY"):
    logger.warning("GROQ_API_KEY nao configurada. Pipeline de meta-automacao estara indisponivel.")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", 8000)), debug=True)
