import uuid
from datetime import datetime, timezone

from extensions import db


def utcnow():
    return datetime.now(timezone.utc)


class Automation(db.Model):
    # Definição persistida de uma automação, incluindo gatilho e passos em JSON.
    __tablename__ = "automations"

    id = db.Column(db.String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.String, db.ForeignKey("profiles.id", ondelete="CASCADE"))
    name = db.Column(db.String, nullable=True)
    description = db.Column(db.Text, nullable=True)
    trigger = db.Column(db.JSON, default=dict)
    steps = db.Column(db.JSON, default=list)
    status = db.Column(db.String, default="draft")
    version = db.Column(db.Integer, default=1)
    external_ref = db.Column(db.JSON, default=dict)
    expires_at = db.Column(db.DateTime(timezone=True), nullable=True)
    next_run_at = db.Column(db.DateTime(timezone=True), nullable=True, index=True)
    created_at = db.Column(db.DateTime(timezone=True), default=utcnow)
    updated_at = db.Column(db.DateTime(timezone=True), default=utcnow, onupdate=utcnow)

    __table_args__ = (
        db.CheckConstraint("status IN ('draft', 'active', 'paused')", name="automations_status_check"),
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
        return Automation.query.all()

    @staticmethod
    def buscar_por_id(id):
        return Automation.query.get(id)

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
