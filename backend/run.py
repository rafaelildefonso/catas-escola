import os
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

from app import create_app, init_firebase

app = create_app()

init_firebase()

if not os.getenv("GROQ_API_KEY"):
    logger.warning("GROQ_API_KEY nao configurada. Pipeline de meta-automacao estara indisponivel.")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000, debug=True)
