import uuid
from datetime import datetime, timezone

from app.extensions import db


def utcnow():
    return datetime.now(timezone.utc)


class AutomationRun(db.Model):
    __tablename__ = "automation_runs"

    id = db.Column(db.String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.String, db.ForeignKey("profiles.id", ondelete="CASCADE"))
    automation_id = db.Column(db.String, db.ForeignKey("automations.id", ondelete="SET NULL"), nullable=True)
    correlation_id = db.Column(db.String, nullable=False)
    status = db.Column(db.String, default="pending")
    run_type = db.Column(db.String, default="direct")
    input_summary = db.Column(db.Text, nullable=True)
    input_payload = db.Column(db.JSON, default=dict)
    result_metadata = db.Column(db.JSON, default=dict)
    error_details = db.Column(db.JSON, nullable=True)
    steps_summary = db.Column(db.JSON, nullable=True)
    execution_id = db.Column(db.String, nullable=True)
    execution_run_id = db.Column(db.String, nullable=True)
    started_at = db.Column(db.DateTime(timezone=True), default=utcnow)
    finished_at = db.Column(db.DateTime(timezone=True), nullable=True)
    created_at = db.Column(db.DateTime(timezone=True), default=utcnow)
    updated_at = db.Column(db.DateTime(timezone=True), default=utcnow, onupdate=utcnow)

    __table_args__ = (
        db.UniqueConstraint("correlation_id", name="automation_runs_correlation_unique"),
        db.CheckConstraint(
            "status IN ('pending', 'running', 'paused', 'completed', 'failed', 'canceled')",
            name="automation_runs_status_check"
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
        return AutomationRun.query.all()

    @staticmethod
    def buscar_por_id(id):
        return AutomationRun.query.get(id)

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
