# server/worker/modules/__init__.py
from worker.modules.registry import register_module, get_module_function  # noqa: F401

# Importação dos arquivos de módulos para executar seus decoradores @register_module
import worker.modules.http_modules  # noqa: F401
import worker.modules.ai_modules  # noqa: F401
import worker.modules.flow_modules  # noqa: F401
import worker.modules.gmail_modules  # noqa: F401
import worker.modules.google_calendar_modules  # noqa: F401
import worker.modules.google_sheets_modules  # noqa: F401
import worker.modules.google_drive_modules  # noqa: F401
import worker.modules.report_modules  # noqa: F401
