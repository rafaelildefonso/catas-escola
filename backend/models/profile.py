import uuid
from datetime import datetime, timezone

from extensions import db


def utcnow():
    return datetime.now(timezone.utc)


class Profile(db.Model):
    __tablename__ = "profiles"

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    subscription_tier = db.Column(db.String, default="basic")
    monthly_quota_limit = db.Column(db.Integer, default=500)
    quota_used = db.Column(db.Integer, default=0)
    rollover_credits = db.Column(db.Integer, default=0)
    stripe_customer_id = db.Column(db.String(255), nullable=True, unique=True)
    stripe_subscription_id = db.Column(db.String(255), nullable=True)
    subscription_status = db.Column(db.String(30), nullable=False, default="inactive")
    stripe_current_period_end = db.Column(db.DateTime(timezone=True), nullable=True)
    last_quota_reset = db.Column(db.DateTime(timezone=True), default=utcnow)
    language = db.Column(db.String, default="en")
    industry = db.Column(db.String, nullable=True)
    role = db.Column(db.String, nullable=True)
    onboarding_completed = db.Column(db.Boolean, default=False)
    onboarding_data = db.Column(db.JSON, default=dict)
    created_at = db.Column(db.DateTime(timezone=True), default=utcnow)
    updated_at = db.Column(db.DateTime(timezone=True), default=utcnow, onupdate=utcnow)

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
        return Profile.query.all()

    @staticmethod
    def buscar_por_id(id):
        return Profile.query.get(id)

    def to_dict(self):
        result = {}
        for col in self.__table__.columns:
            if col.name in {"stripe_customer_id", "stripe_subscription_id"}:
                continue
            value = getattr(self, col.name)
            if isinstance(value, uuid.UUID):
                value = str(value)
            elif isinstance(value, datetime):
                value = value.replace(tzinfo=None).isoformat()
            result[col.name] = value
        result["has_billing_subscription"] = bool(self.stripe_subscription_id)
        result["has_billing_account"] = bool(self.stripe_customer_id)
        return result
