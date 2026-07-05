import uuid
from datetime import datetime, timezone

from app.extensions import db


def utcnow():
    return datetime.now(timezone.utc)


class UserWebhookConfig(db.Model):
    __tablename__ = "user_webhook_configs"

    id = db.Column(db.String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.String, db.ForeignKey("profiles.id", ondelete="CASCADE"))
    automation_id = db.Column(db.String, db.ForeignKey("automations.id", ondelete="SET NULL"), nullable=True)
    slug = db.Column(db.String, unique=True, nullable=False)
    name = db.Column(db.String, nullable=False)
    description = db.Column(db.Text, nullable=True)
    hmac_secret = db.Column(db.String, nullable=False)
    is_active = db.Column(db.Boolean, default=True)
    allowed_sources = db.Column(db.JSON, nullable=True)
    payload_mapping = db.Column(db.JSON, default=dict)
    created_at = db.Column(db.DateTime(timezone=True), default=utcnow)
    updated_at = db.Column(db.DateTime(timezone=True), default=utcnow, onupdate=utcnow)

    def salvar(self):
        db.session.add(self)
        db.session.commit()

    def atualizar(self, **kwargs):
        for key, value in kwargs.items():
            if hasattr(self, key) and value is not None:
                setattr(self, key, value)
        db.session.commit()

    def deletar(self):
        db.session.delete(self)
        db.session.commit()

    @staticmethod
    def listar_todos():
        return UserWebhookConfig.query.all()

    @staticmethod
    def buscar_por_id(id):
        return UserWebhookConfig.query.get(id)

    def to_dict(self):
        result = {}
        for col in self.__table__.columns:
            value = getattr(self, col.name)
            if isinstance(value, uuid.UUID):
                value = str(value)
            elif isinstance(value, datetime):
                value = value.replace(tzinfo=None).isoformat()
            result[col.name] = value
        return result
