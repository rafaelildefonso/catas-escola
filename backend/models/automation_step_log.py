import uuid
from datetime import datetime, timezone

from extensions import db


def utcnow():
    return datetime.now(timezone.utc)


class AutomationStepLog(db.Model):
    __tablename__ = "automation_step_logs"

    id = db.Column(db.String, primary_key=True, default=lambda: str(uuid.uuid4()))
    automation_id = db.Column(db.String, nullable=False)
    step_index = db.Column(db.Integer, nullable=False)
    module_id = db.Column(db.String, nullable=False)
    status = db.Column(db.String, nullable=False)
    result = db.Column(db.JSON, nullable=True)
    intent = db.Column(db.String, nullable=True)
    run_id = db.Column(db.String, db.ForeignKey("automation_runs.id", ondelete="SET NULL"), nullable=True)
    user_id = db.Column(db.String, db.ForeignKey("profiles.id", ondelete="CASCADE"), nullable=True)
    updated_at = db.Column(db.DateTime(timezone=True), default=utcnow, onupdate=utcnow)

    __table_args__ = (
        db.UniqueConstraint("run_id", "step_index", name="automation_step_logs_run_step_unique"),
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
    def listar_todos(automation_id=None, run_id=None):
        query = AutomationStepLog.query
        if automation_id:
            query = query.filter_by(automation_id=automation_id)
        if run_id:
            query = query.filter_by(run_id=run_id)
        return query.all()

    @staticmethod
    def buscar_por_id(id):
        return AutomationStepLog.query.get(id)

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
