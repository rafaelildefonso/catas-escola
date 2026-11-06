import os
import sys
import logging

# Garantir UTF-8 no Windows para evitar erros de encoding com emoji
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    sys.stderr.reconfigure(encoding='utf-8', errors='replace')

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

from application import create_app, init_firebase
from extensions import db
from sqlalchemy import inspect, text

app = create_app()

with app.app_context():
    db.create_all()
    if db.engine.dialect.name == "sqlite":
        step_log_indexes = {
            item["name"]
            for item in inspect(db.engine).get_indexes("automation_step_logs")
        }
        step_log_indexes.update(
            item["name"]
            for item in inspect(db.engine).get_unique_constraints("automation_step_logs")
            if item.get("name")
        )
        if "automation_step_logs_automation_step_unique" in step_log_indexes:
            db.session.execute(
                text("DROP INDEX IF EXISTS automation_step_logs_automation_step_unique")
            )
        if "automation_step_logs_run_step_unique" not in step_log_indexes:
            db.session.execute(
                text(
                    "CREATE UNIQUE INDEX IF NOT EXISTS "
                    "automation_step_logs_run_step_unique "
                    "ON automation_step_logs (run_id, step_index)"
                )
            )

        automation_columns = {
            column["name"] for column in inspect(db.engine).get_columns("automations")
        }
        if "next_run_at" not in automation_columns:
            db.session.execute(text("ALTER TABLE automations ADD COLUMN next_run_at DATETIME NULL"))
        db.session.execute(text("CREATE INDEX IF NOT EXISTS idx_automations_due ON automations (status, next_run_at)"))
        profile_columns = {
            column["name"] for column in inspect(db.engine).get_columns("profiles")
        }
        sqlite_profile_updates = (
            ("stripe_customer_id", "VARCHAR(255) NULL"),
            ("stripe_subscription_id", "VARCHAR(255) NULL"),
            ("subscription_status", "VARCHAR(30) NOT NULL DEFAULT 'inactive'"),
            ("stripe_current_period_end", "DATETIME NULL"),
        )
        for column_name, column_sql in sqlite_profile_updates:
            if column_name not in profile_columns:
                db.session.execute(
                    text(f"ALTER TABLE profiles ADD COLUMN {column_name} {column_sql}")
                )
        db.session.execute(
            text(
                "CREATE UNIQUE INDEX IF NOT EXISTS uq_profiles_stripe_customer_id "
                "ON profiles (stripe_customer_id)"
            )
        )
        db.session.commit()
    logger.info("Tabelas do banco verificadas/criadas.")

init_firebase()

if not os.getenv("GROQ_API_KEY"):
    logger.warning("GROQ_API_KEY nao configurada. Pipeline de meta-automacao estara indisponivel.")

if __name__ == "__main__":
    app.run(host="127.0.0.1", port=int(os.getenv("PORT", 8000)), debug=True)
