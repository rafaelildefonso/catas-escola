import uuid
from datetime import datetime, timezone

from extensions import db

TIPOS_TERMO = ("uso", "consentimento")


def utcnow():
    return datetime.now(timezone.utc)


class TermoAceite(db.Model):
    __tablename__ = "termos_aceite"

    VERSAO_ATUAL = "1.0"

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.String(36), nullable=False)
    tipo = db.Column(db.String(20), nullable=False)  # 'uso' | 'consentimento'
    versao = db.Column(db.String(20), nullable=False, default=VERSAO_ATUAL)
    origem = db.Column(db.String(20), nullable=True)  # 'signup' | 'primeiro-acesso' | 'web'
    aceito_em = db.Column(db.DateTime(timezone=True), default=utcnow)

    def salvar(self):
        db.session.add(self)
        db.session.commit()

    def deletar(self):
        db.session.delete(self)
        db.session.commit()

    @staticmethod
    def listar_todos():
        return TermoAceite.query.all()

    @staticmethod
    def buscar_por_id(id):
        return TermoAceite.query.get(id)

    @staticmethod
    def listar_por_usuario(user_id):
        return (
            TermoAceite.query.filter_by(user_id=user_id)
            .order_by(TermoAceite.aceito_em.desc())
            .all()
        )

    @staticmethod
    def buscar_ultimo(user_id, tipo):
        return (
            TermoAceite.query.filter_by(user_id=user_id, tipo=tipo)
            .order_by(TermoAceite.aceito_em.desc())
            .first()
        )

    @staticmethod
    def existe_aceite(user_id, tipo, versao):
        return (
            TermoAceite.query.filter_by(user_id=user_id, tipo=tipo, versao=versao)
            .first()
            is not None
        )

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
