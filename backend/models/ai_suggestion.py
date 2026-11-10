import uuid
from datetime import datetime, timezone

from extensions import db


def utcnow():
    return datetime.now(timezone.utc)


class AiSuggestion(db.Model):
    # Registro de uma sugestão produzida pela IA para um usuário e, opcionalmente, uma página.
    __tablename__ = "ai_suggestions"

    id = db.Column(db.String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.String, db.ForeignKey("profiles.id", ondelete="CASCADE"))
    context_id = db.Column(db.String, db.ForeignKey("page_contexts.id", ondelete="SET NULL"), nullable=True)
    title = db.Column(db.String, nullable=False)
    description = db.Column(db.Text, nullable=True)
    confidence_score = db.Column(db.Float, nullable=True)
    payload_preview = db.Column(db.JSON, nullable=True)
    suggested_workflow = db.Column(db.String, nullable=True)
    status = db.Column(db.String, default="pending")
    created_at = db.Column(db.DateTime(timezone=True), default=utcnow)

    __table_args__ = (
        db.CheckConstraint(
            "status IN ('pending', 'accepted', 'rejected', 'executed')",
            name="ai_suggestions_status_check"
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
        return AiSuggestion.query.all()

    @staticmethod
    def buscar_por_id(id):
        return AiSuggestion.query.get(id)

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
