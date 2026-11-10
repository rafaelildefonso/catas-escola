import uuid
from datetime import datetime, timezone

from extensions import db


def utcnow():
    return datetime.now(timezone.utc)


class UserDevice(db.Model):
    # Dispositivo conhecido pelo usuário, utilizado por automações e integrações.
    __tablename__ = "user_devices"

    id = db.Column(db.String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.String, db.ForeignKey("profiles.id", ondelete="CASCADE"))
    fcm_token = db.Column(db.String, nullable=False)
    platform = db.Column(db.String, nullable=True)
    active = db.Column(db.Boolean, default=True)
    last_seen_at = db.Column(db.DateTime(timezone=True), default=utcnow)
    created_at = db.Column(db.DateTime(timezone=True), default=utcnow)
    updated_at = db.Column(db.DateTime(timezone=True), default=utcnow, onupdate=utcnow)

    __table_args__ = (
        db.UniqueConstraint("user_id", "fcm_token", name="user_devices_user_id_fcm_token_key"),
        db.CheckConstraint(
            "platform IN ('android', 'ios', 'web')",
            name="user_devices_platform_check"
        ),
    )

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
        return UserDevice.query.all()

    @staticmethod
    def buscar_por_id(id):
        return UserDevice.query.get(id)

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
