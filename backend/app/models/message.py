import uuid
from datetime import datetime, timezone

from app.extensions import db


def utcnow():
    return datetime.now(timezone.utc)


class Message(db.Model):
    __tablename__ = "messages"

    id = db.Column(db.String, primary_key=True, default=lambda: str(uuid.uuid4()))
    session_id = db.Column(db.String, db.ForeignKey("chat_sessions.id", ondelete="CASCADE"), nullable=True)
    role = db.Column(db.String, nullable=False)
    content = db.Column(db.Text, nullable=False)
    metadata_ = db.Column("metadata", db.JSON, default=dict)
    created_at = db.Column(db.DateTime(timezone=True), default=utcnow)

    chat_session = db.relationship("ChatSession", back_populates="messages")

    __table_args__ = (
        db.CheckConstraint("role IN ('user', 'assistant', 'system')", name="messages_role_check"),
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
        return Message.query.all()

    @staticmethod
    def buscar_por_id(id):
        return Message.query.get(id)

    def to_dict(self):
        result = {}
        for col in self.__table__.columns:
            value = getattr(self, col.key)
            if isinstance(value, uuid.UUID):
                value = str(value)
            elif isinstance(value, datetime):
                value = value.replace(tzinfo=None).isoformat()
            result[col.name] = value
        return result
