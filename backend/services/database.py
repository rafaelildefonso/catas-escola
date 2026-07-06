import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from core.config import settings

_engine = None
_SessionLocal = None

_INSTANCE_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "instance")


def _get_db_url():
    db_url = settings.DATABASE_URL
    if db_url:
        return db_url
    # Se for SQLite relativo, aponta para instance/ igual ao Flask-SQLAlchemy
    return f"sqlite:///{os.path.join(_INSTANCE_DIR, 'catas_dev.db').replace(os.sep, '/')}"


def _get_engine():
    global _engine
    if _engine is None:
        _engine = create_engine(
            _get_db_url(),
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
