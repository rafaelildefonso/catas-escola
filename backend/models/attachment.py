import uuid
from datetime import datetime, timezone

from extensions import db


def utcnow():
    return datetime.now(timezone.utc)


class Attachment(db.Model):
    # Metadados de arquivo enviado; o conteúdo permanece no armazenamento indicado por storage_path.
    __tablename__ = "attachments"

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(
        db.String(36),
        db.ForeignKey("profiles.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    original_name = db.Column(db.String(255), nullable=False)
    storage_path = db.Column(db.String(512), nullable=False)
    content_type = db.Column(db.String(100), nullable=False)
    size_bytes = db.Column(db.BigInteger, nullable=False)
    created_at = db.Column(db.DateTime(timezone=True), default=utcnow, nullable=False)

    def salvar(self):
        db.session.add(self)
        db.session.commit()

    def deletar(self):
        db.session.delete(self)
        db.session.commit()

    def atualizar(self, **kwargs):
        for campo in ("original_name", "storage_path", "content_type", "size_bytes"):
            valor = kwargs.get(campo)
            if valor is not None:
                setattr(self, campo, valor)
        db.session.commit()

    @staticmethod
    def listar_todos():
        return Attachment.query.order_by(Attachment.created_at.desc()).all()

    @staticmethod
    def listar_do_usuario(user_id: str, limite: int = 1000):
        return (
            Attachment.query.filter_by(user_id=user_id)
            .order_by(Attachment.created_at.desc())
            .limit(limite)
            .all()
        )

    @staticmethod
    def buscar_por_id(id: str):
        return Attachment.query.get(id)

    def to_dict(self, url: str | None = None):
        created_at = self.created_at
        if isinstance(created_at, datetime):
            created_at = created_at.replace(tzinfo=None).isoformat()
        return {
            "id": self.id,
            "name": self.original_name,
            "content_type": self.content_type,
            "size_bytes": self.size_bytes,
            "created_at": created_at,
            "url": url,
        }
