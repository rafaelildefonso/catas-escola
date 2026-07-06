from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from core.config import settings

_engine = None
_SessionLocal = None


def _get_engine():
    global _engine
    if _engine is None:
        db_url = settings.DATABASE_URL or "sqlite:///catas_dev.db"
        _engine = create_engine(
            db_url,
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
