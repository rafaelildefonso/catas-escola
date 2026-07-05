from dotenv import load_dotenv
import os

load_dotenv()

class Settings:
    TOKENS_PER_CREDIT: int = 2000
    FLAT_RATE_COST: int = 1
    MAX_ROLLOVER_MULTIPLIER: int = 3

    SUPABASE_URL: str = os.getenv("SUPABASE_URL", "")
    SUPABASE_SERVICE_ROLE_KEY: str = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")
    DATABASE_URL: str = os.getenv("DATABASE_URL", "")

    OPENAI_API_KEY: str = os.getenv("OPENAI_API_KEY", "")
    GOOGLE_API_KEY: str = os.getenv("GOOGLE_API_KEY", "")
    GROQ_API_KEY: str = os.getenv("GROQ_API_KEY", "")

    AGENT_INTERPRETER: str = os.getenv("AGENT_INTERPRETER", "groq|llama-3.1-8b-instant|https://api.groq.com/openai/v1/chat/completions|GROQ_API_KEY")
    AGENT_CLASSIFIER: str = os.getenv("AGENT_CLASSIFIER", "groq|llama-3.1-8b-instant|https://api.groq.com/openai/v1/chat/completions|GROQ_API_KEY")
    AGENT_SELECTOR: str = os.getenv("AGENT_SELECTOR", "groq|llama-3.1-8b-instant|https://api.groq.com/openai/v1/chat/completions|GROQ_API_KEY")
    AGENT_DEVELOPER: str = os.getenv("AGENT_DEVELOPER", "groq|llama-3.3-70b-versatile|https://api.groq.com/openai/v1/chat/completions|GROQ_API_KEY")

    AGENT_INTENT_CLASSIFIER: str = os.getenv("AGENT_INTENT_CLASSIFIER", "groq|llama-3.1-8b-instant|https://api.groq.com/openai/v1/chat/completions|GROQ_API_KEY")
    AGENT_ENTITY_EXTRACTOR: str = os.getenv("AGENT_ENTITY_EXTRACTOR", "groq|llama-3.1-8b-instant|https://api.groq.com/openai/v1/chat/completions|GROQ_API_KEY")

    MODEL_TIER_BASIC: str = os.getenv("MODEL_TIER_BASIC", "groq|llama-3.1-8b-instant|https://api.groq.com/openai/v1/chat/completions|GROQ_API_KEY")
    MODEL_TIER_PRO: str = os.getenv("MODEL_TIER_PRO", "gemini|gemini-2.5-flash|https://generativelanguage.googleapis.com/v1beta|GOOGLE_API_KEY")
    MODEL_TIER_MAX: str = os.getenv("MODEL_TIER_MAX", "gemini|gemini-2.5-pro|https://generativelanguage.googleapis.com/v1beta|GOOGLE_API_KEY")

    STRIPE_SECRET_KEY: str = os.getenv("STRIPE_SECRET_KEY", "")
    STRIPE_WEBHOOK_SECRET: str = os.getenv("STRIPE_WEBHOOK_SECRET", "")

    BASIC_PLAN_ID: str = os.getenv("BASIC_PLAN_ID", "")
    PRO_PLAN_ID: str = os.getenv("PRO_PLAN_ID", "")
    MAX_PLAN_ID: str = os.getenv("MAX_PLAN_ID", "")

    APP_DEEP_LINK_SCHEME: str = os.getenv("APP_DEEP_LINK_SCHEME", "catas")
    ENCRYPTION_KEY: str = os.getenv("ENCRYPTION_KEY", "")
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "development")

    def validate(self):
        missing = []
        if not self.SUPABASE_URL or not self.SUPABASE_SERVICE_ROLE_KEY:
            missing.append("SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY")
        if not self.OPENAI_API_KEY:
            missing.append("OPENAI_API_KEY")
        if missing:
            raise RuntimeError(f"Variáveis de ambiente não configuradas: {', '.join(missing)}")

settings = Settings()
settings.validate()
