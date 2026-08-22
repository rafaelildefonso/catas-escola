import uuid
from datetime import datetime, timezone

from extensions import db


def utcnow():
    return datetime.now(timezone.utc)


class ExecutionLog(db.Model):
    __tablename__ = "execution_logs"

    id = db.Column(db.String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.String, db.ForeignKey("profiles.id", ondelete="CASCADE"))
    suggestion_id = db.Column(db.String, db.ForeignKey("ai_suggestions.id", ondelete="SET NULL"), nullable=True)
    session_id = db.Column(db.String, db.ForeignKey("chat_sessions.id", ondelete="SET NULL"), nullable=True)
    workflow_name = db.Column(db.String, nullable=True)
    status = db.Column(db.String, default="running")
    input_data = db.Column(db.JSON, nullable=True)
    result_data = db.Column(db.JSON, nullable=True)
    error_message = db.Column(db.Text, nullable=True)
    started_at = db.Column(db.DateTime(timezone=True), default=utcnow)
    finished_at = db.Column(db.DateTime(timezone=True), nullable=True)

    __table_args__ = (
        db.CheckConstraint("status IN ('running', 'success', 'failed')", name="execution_logs_status_check"),
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
        return ExecutionLog.query.all()

    @staticmethod
    def buscar_por_id(id):
        return ExecutionLog.query.get(id)

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
