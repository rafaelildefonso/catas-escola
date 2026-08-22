from datetime import datetime, timezone

from extensions import db


def utcnow():
    return datetime.now(timezone.utc)


class PageAnalysisCache(db.Model):
    __tablename__ = "page_analysis_cache"

    url_hash = db.Column(db.String, primary_key=True)
    url = db.Column(db.Text, nullable=False)
    analysis_result = db.Column(db.JSON, nullable=False)
    created_at = db.Column(db.DateTime(timezone=True), default=utcnow)
    expires_at = db.Column(db.DateTime(timezone=True), nullable=False)

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
        return PageAnalysisCache.query.all()

    @staticmethod
    def buscar_por_id(id):
        return PageAnalysisCache.query.get(id)

    def to_dict(self):
        result = {}
        for col in self.__table__.columns:
            value = getattr(self, col.name)
            if isinstance(value, datetime):
                value = value.replace(tzinfo=None).isoformat()
            result[col.name] = value
        return result
