import uuid
from datetime import datetime, timezone

from extensions import db


def utcnow():
    return datetime.now(timezone.utc)


class MessageFeedback(db.Model):
    __tablename__ = "message_feedback"

    id = db.Column(db.String, primary_key=True, default=lambda: str(uuid.uuid4()))
    message_id = db.Column(db.String, nullable=False)
    user_id = db.Column(db.String, nullable=False)
    session_id = db.Column(db.String, nullable=False)
    is_liked = db.Column(db.Boolean, nullable=False)
    reason = db.Column(db.String, nullable=True)
    created_at = db.Column(db.DateTime(timezone=True), default=utcnow)
    updated_at = db.Column(db.DateTime(timezone=True), default=utcnow, onupdate=utcnow)

    __table_args__ = (
        db.UniqueConstraint("message_id", "user_id", name="uq_feedback_message_user"),
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
        return MessageFeedback.query.all()

    @staticmethod
    def buscar_por_id(id):
        return MessageFeedback.query.get(id)

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
