import uuid
from datetime import datetime, timezone

from extensions import db


def utcnow():
    return datetime.now(timezone.utc)


class AutomationGenerationLog(db.Model):
    # Auditoria da geração de um plano de automação pela IA.
    __tablename__ = "automation_generation_logs"

    id = db.Column(db.String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.String, db.ForeignKey("profiles.id", ondelete="CASCADE"))
    session_id = db.Column(db.String, db.ForeignKey("chat_sessions.id", ondelete="SET NULL"), nullable=True)
    intent_raw = db.Column(db.Text, nullable=True)
    attempts = db.Column(db.JSON, default=list)
    errors = db.Column(db.JSON, default=list)
    final_plan = db.Column(db.JSON, nullable=True)
    model = db.Column(db.String, nullable=True)
    tokens_used = db.Column(db.Integer, nullable=True)
    created_at = db.Column(db.DateTime(timezone=True), default=utcnow)

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
        return AutomationGenerationLog.query.all()

    @staticmethod
    def buscar_por_id(id):
        return AutomationGenerationLog.query.get(id)

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
