import uuid
from datetime import datetime, timezone

from sqlalchemy.orm import defer

from extensions import db


def utcnow():
    return datetime.now(timezone.utc)


class GeneratedReport(db.Model):
    # Registro de relatórios gerados, com parâmetros e conteúdo armazenados em JSON.
    """PDF criado por uma automação e disponibilizado na biblioteca do usuário."""

    __tablename__ = "generated_reports"

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(
        db.String(36),
        db.ForeignKey("profiles.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    automation_id = db.Column(db.String, db.ForeignKey("automations.id", ondelete="SET NULL"))
    automation_run_id = db.Column(
        db.String,
        db.ForeignKey("automation_runs.id", ondelete="SET NULL"),
        index=True,
    )
    title = db.Column(db.String(255), nullable=False)
    summary = db.Column(db.Text, nullable=True)
    source_name = db.Column(db.String(255), nullable=True)
    metrics = db.Column(db.JSON, default=dict, nullable=False)
    pdf_content = db.Column(db.LargeBinary, nullable=False)
    created_at = db.Column(db.DateTime(timezone=True), default=utcnow, nullable=False, index=True)

    def salvar(self):
        db.session.add(self)
        db.session.commit()

    @staticmethod
    def listar_do_usuario(user_id: str, limite: int = 100):
        return (
            GeneratedReport.query.filter_by(user_id=user_id)
            .options(defer(GeneratedReport.pdf_content))
            .order_by(GeneratedReport.created_at.desc())
            .limit(limite)
            .all()
        )

    @staticmethod
    def buscar_do_usuario(report_id: str, user_id: str):
        return GeneratedReport.query.filter_by(id=report_id, user_id=user_id).first()

    def to_dict(self):
        created_at = self.created_at
        if isinstance(created_at, datetime):
            created_at = created_at.replace(tzinfo=None).isoformat()
        return {
            "id": self.id,
            "title": self.title,
            "summary": self.summary,
            "source_name": self.source_name,
            "metrics": self.metrics or {},
            "automation_id": self.automation_id,
            "automation_run_id": self.automation_run_id,
            "created_at": created_at,
        }
