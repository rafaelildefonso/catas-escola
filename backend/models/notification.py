import uuid
from datetime import datetime, timezone

from extensions import db


class Notification(db.Model):
    __tablename__ = "notifications"

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.String(36), db.ForeignKey("profiles.id", ondelete="CASCADE"), nullable=False, index=True)
    type = db.Column(db.String(30), nullable=False, default="automation")
    title = db.Column(db.String(255), nullable=False)
    body = db.Column(db.Text, nullable=False)
    image_url = db.Column(db.String(255), nullable=True)
    action_type = db.Column(db.String(30), nullable=True)
    action_data = db.Column(db.Text, nullable=True)
    extra_data = db.Column("metadata", db.JSON, nullable=True)
    is_read = db.Column(db.Boolean, nullable=False, default=False)
    created_at = db.Column(db.DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

    def salvar(self):
        db.session.add(self)
        db.session.commit()

    def atualizar(self, **kwargs):
        for field in ("is_read", "title", "body"):
            if field in kwargs:
                setattr(self, field, kwargs[field])
        db.session.commit()

    def deletar(self):
        db.session.delete(self)
        db.session.commit()

    @staticmethod
    def listar_todos():
        return Notification.query.all()

    @staticmethod
    def buscar_por_id(id):
        return db.session.get(Notification, id)

    def to_dict(self):
        return {
            "id": self.id,
            "type": self.type,
            "title": self.title,
            "body": self.body,
            "action_type": self.action_type,
            "action_data": self.action_data,
            "is_read": self.is_read,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }
