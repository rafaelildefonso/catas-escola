from flask_sqlalchemy import SQLAlchemy

# Instância única da extensão. Ela é conectada ao Flask em application.create_app().
db = SQLAlchemy()
