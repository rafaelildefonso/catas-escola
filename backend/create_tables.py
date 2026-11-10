from application import create_app
from extensions import db
from models.user import User

app = create_app()
# As tabelas só podem ser criadas dentro do contexto da aplicação, onde a conexão está configurada.
with app.app_context():
    # Cria tabelas ausentes a partir dos modelos importados; não altera tabelas existentes.
    db.create_all()
    print("Tabelas criadas com sucesso!")
