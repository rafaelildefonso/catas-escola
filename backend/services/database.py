from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from core.config import settings

_engine = None
_SessionLocal = None


def _get_engine():
    global _engine
    if _engine is None:
        if not settings.DATABASE_URL:
            raise RuntimeError(
                "DATABASE_URL não configurada. "
                "Adicione DATABASE_URL ao .env para usar SQLAlchemy."
            )
        _engine = create_engine(
            settings.DATABASE_URL,
            pool_size=10,
            max_overflow=20,
            pool_pre_ping=True,
            echo=settings.ENVIRONMENT == "development",
        )
    return _engine


def _get_session_local():
    global _SessionLocal
    if _SessionLocal is None:
        _SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=_get_engine())
    return _SessionLocal


def get_db():
    SessionLocal = _get_session_local()
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def get_sync_db():
    SessionLocal = _get_session_local()
    db = SessionLocal()
    return db
