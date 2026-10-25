from dotenv import load_dotenv
import os

load_dotenv()

class Settings:
    TOKENS_PER_CREDIT: int = 2000
    FLAT_RATE_COST: int = 1
    MAX_ROLLOVER_MULTIPLIER: int = 3

    JWT_SECRET_KEY: str = os.getenv("JWT_SECRET_KEY", "dev-secret-change-in-production")
    JWT_EXPIRATION_SECONDS: int = int(os.getenv("JWT_EXPIRATION_SECONDS", "86400"))
    DATABASE_URL: str = os.getenv("DATABASE_URL", "")
    SUPABASE_URL: str = os.getenv("SUPABASE_URL", "").rstrip("/")
    SUPABASE_SERVICE_ROLE_KEY: str = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")

    OPENAI_API_KEY: str = os.getenv("OPENAI_API_KEY", "")
    GOOGLE_API_KEY: str = os.getenv("GOOGLE_API_KEY", "")
    GROQ_API_KEY: str = os.getenv("GROQ_API_KEY", "")

    AGENT_INTERPRETER: str = os.getenv("AGENT_INTERPRETER", "groq|openai/gpt-oss-20b|https://api.groq.com/openai/v1/chat/completions|GROQ_API_KEY")
    AGENT_CLASSIFIER: str = os.getenv("AGENT_CLASSIFIER", "groq|openai/gpt-oss-20b|https://api.groq.com/openai/v1/chat/completions|GROQ_API_KEY")
    AGENT_SELECTOR: str = os.getenv("AGENT_SELECTOR", "groq|openai/gpt-oss-20b|https://api.groq.com/openai/v1/chat/completions|GROQ_API_KEY")
    AGENT_DEVELOPER: str = os.getenv("AGENT_DEVELOPER", "groq|openai/gpt-oss-120b|https://api.groq.com/openai/v1/chat/completions|GROQ_API_KEY")

    AGENT_INTENT_CLASSIFIER: str = os.getenv("AGENT_INTENT_CLASSIFIER", "groq|openai/gpt-oss-20b|https://api.groq.com/openai/v1/chat/completions|GROQ_API_KEY")
    AGENT_ENTITY_EXTRACTOR: str = os.getenv("AGENT_ENTITY_EXTRACTOR", "groq|openai/gpt-oss-20b|https://api.groq.com/openai/v1/chat/completions|GROQ_API_KEY")

    MODEL_TIER_BASIC: str = os.getenv("MODEL_TIER_BASIC", "groq|openai/gpt-oss-20b|https://api.groq.com/openai/v1/chat/completions|GROQ_API_KEY")
    MODEL_TIER_PRO: str = os.getenv("MODEL_TIER_PRO", "gemini|gemini-2.5-flash|https://generativelanguage.googleapis.com/v1beta|GOOGLE_API_KEY")
    MODEL_TIER_MAX: str = os.getenv("MODEL_TIER_MAX", "gemini|gemini-2.5-pro|https://generativelanguage.googleapis.com/v1beta|GOOGLE_API_KEY")

    STRIPE_SECRET_KEY: str = os.getenv("STRIPE_SECRET_KEY", "")
    STRIPE_WEBHOOK_SECRET: str = os.getenv("STRIPE_WEBHOOK_SECRET", "")

    BASIC_PLAN_ID: str = os.getenv("BASIC_PLAN_ID", "")
    PRO_PLAN_ID: str = os.getenv("PRO_PLAN_ID", "")
    MAX_PLAN_ID: str = os.getenv("MAX_PLAN_ID", "")
    FRONTEND_URL: str = os.getenv("FRONTEND_URL", "https://catas.app").rstrip("/")
    STRIPE_SUCCESS_URL: str = os.getenv(
        "STRIPE_SUCCESS_URL",
        f"{os.getenv('FRONTEND_URL', 'https://catas.app').rstrip('/')}/?billing=success",
    )
    STRIPE_CANCEL_URL: str = os.getenv(
        "STRIPE_CANCEL_URL",
        f"{os.getenv('FRONTEND_URL', 'https://catas.app').rstrip('/')}/?billing=cancelled",
    )

    APP_DEEP_LINK_SCHEME: str = os.getenv("APP_DEEP_LINK_SCHEME", "catas")
    ENCRYPTION_KEY: str = os.getenv("ENCRYPTION_KEY", "")
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "development")
    ATTACHMENTS_MAX_SIZE_BYTES: int = int(os.getenv("ATTACHMENTS_MAX_SIZE_BYTES", "10485760"))
    WORKER_URL: str = os.getenv("WORKER_URL", "http://localhost:8001")
    WORKER_SHARED_SECRET: str = os.getenv("WORKER_SHARED_SECRET", "")

    def validate(self):
        missing = []
        if not self.OPENAI_API_KEY:
            missing.append("OPENAI_API_KEY")
        if missing:
            raise RuntimeError(f"Variáveis de ambiente não configuradas: {', '.join(missing)}")

settings = Settings()
settings.validate()
