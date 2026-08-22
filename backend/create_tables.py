from application import create_app
from extensions import db
from models.user import User

app = create_app()
with app.app_context():
    db.create_all()
    print("Tabelas criadas com sucesso!")
