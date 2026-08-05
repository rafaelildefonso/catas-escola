from uuid import uuid4
from datetime import datetime, timezone, timedelta

from app.extensions import db
from werkzeug.security import generate_password_hash, check_password_hash
from jose import jwt

from core.config import settings


def utcnow():
    return datetime.now(timezone.utc)


class User(db.Model):
    __tablename__ = "users"

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid4()))
    email = db.Column(db.String(255), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    created_at = db.Column(db.DateTime(timezone=True), default=utcnow)
    updated_at = db.Column(db.DateTime(timezone=True), default=utcnow, onupdate=utcnow)

    def set_password(self, password: str):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password: str) -> bool:
        return check_password_hash(self.password_hash, password)

    def generate_token(self) -> str:
        payload = {
            "user_id": self.id,
            "email": self.email,
            "exp": datetime.now(timezone.utc) + timedelta(seconds=settings.JWT_EXPIRATION_SECONDS),
            "iat": datetime.now(timezone.utc),
        }
        return jwt.encode(payload, settings.JWT_SECRET_KEY, algorithm="HS256")

    def salvar(self):
        db.session.add(self)
        db.session.commit()

    def atualizar(self, **kwargs):
        for key, value in kwargs.items():
            if key in ("password", "password_hash"):
                continue
            if hasattr(self, key) and value is not None:
                setattr(self, key, value)
        db.session.commit()

    def deletar(self):
        db.session.delete(self)
        db.session.commit()

    @staticmethod
    def listar_todos():
        return User.query.all()

    @staticmethod
    def buscar_por_id(id):
        return User.query.get(id)

    @staticmethod
    def buscar_por_email(email):
        return User.query.filter_by(email=email).first()

    def to_dict(self):
        return {
            "id": self.id,
            "email": self.email,
            "created_at": self.created_at.replace(tzinfo=None).isoformat() if self.created_at else None,
        }
