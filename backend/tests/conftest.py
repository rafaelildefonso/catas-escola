import os
import sys
import pytest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

os.environ.setdefault("DATABASE_URL", "sqlite:///:memory:")
os.environ.setdefault("SUPABASE_URL", "https://test.supabase.co")
os.environ.setdefault("SUPABASE_SERVICE_ROLE_KEY", "test-key")
os.environ.setdefault("ENVIRONMENT", "test")
os.environ.setdefault("ENCRYPTION_KEY", "test-key-32-chars-minimum-for-test!")
os.environ.setdefault("GROQ_API_KEY", "test-groq")
os.environ.setdefault("OPENAI_API_KEY", "test-openai")
os.environ.setdefault("GOOGLE_API_KEY", "test-google")
os.environ.setdefault("STRIPE_SECRET_KEY", "test-stripe")

from app import create_app
from app.extensions import db as _db


@pytest.fixture(scope="session")
def app():
    app = create_app()
    with app.app_context():
        _db.create_all()
        yield app
        _db.drop_all()


@pytest.fixture(scope="session")
def client(app):
    return app.test_client()


@pytest.fixture(autouse=True)
def db_session(app):
    with app.app_context():
        _db.create_all()
        yield _db.session
        _db.session.rollback()
        for tbl in reversed(_db.metadata.sorted_tables):
            _db.session.execute(tbl.delete())
        _db.session.commit()
