"""
Entrypoint do container Worker CATAS.
Valida o carregamento dos módulos e inicia o HTTP server para
receber tarefas de execução do catas_server.
"""
import logging
import os
import sys

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s — %(message)s",
)
logger = logging.getLogger("worker.entrypoint")

WORKER_PORT = int(os.getenv("WORKER_PORT", "8001"))


def validate_modules():
    try:
        import worker.modules  # noqa: F401
        from worker.modules.registry import _MODULE_REGISTRY
        logger.info(f"Módulos registrados ({len(_MODULE_REGISTRY)}): {list(_MODULE_REGISTRY.keys())}")

        if not _MODULE_REGISTRY:
            logger.error("Nenhum módulo registrado! O worker não funcionará.")
            return False

        logger.info("Worker validado com sucesso. Pronto para execução.")
        return True
    except Exception as e:
        logger.error(f"Falha ao carregar módulos do worker: {e}")
        return False


def main():
    logger.info("Iniciando Worker CATAS...")

    if not validate_modules():
        logger.error("Worker não pode iniciar devido a erros de validação.")
        sys.exit(1)

    from worker.server import worker_app

    logger.info(f"Worker CATAS inicializado. Servidor HTTP na porta {WORKER_PORT}.")
    worker_app.run(host="127.0.0.1", port=WORKER_PORT, debug=False)


if __name__ == "__main__":
    main()
