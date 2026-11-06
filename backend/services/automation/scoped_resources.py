"""Owner-scoped queries for run history, step logs and FCM devices."""

from extensions import db
from models.automation import Automation
from models.automation_run import AutomationRun
from models.automation_step_log import AutomationStepLog
from models.user_device import UserDevice


class ScopedAutomationResources:
    @staticmethod
    def list_runs(user_id, limit, offset):
        runs = (
            AutomationRun.query.filter_by(user_id=user_id)
            .order_by(AutomationRun.created_at.desc())
            .offset(offset).limit(limit).all()
        )
        ids = {run.automation_id for run in runs if run.automation_id}
        automations = {
            item.id: item for item in Automation.query.filter(Automation.id.in_(ids)).all()
        } if ids else {}
        data = []
        for run in runs:
            item = run.to_dict()
            automation = automations.get(run.automation_id)
            item["automations"] = {"name": automation.name, "status": automation.status} if automation else None
            data.append(item)
        return data

    @staticmethod
    def get_run(user_id, run_id):
        run = AutomationRun.query.filter_by(id=run_id, user_id=user_id).first()
        if not run:
            raise ValueError("Execução não encontrada")
        return run.to_dict()

    @staticmethod
    def delete_run(user_id, run_id):
        run = AutomationRun.query.filter_by(id=run_id, user_id=user_id).first()
        if not run:
            raise ValueError("Execução não encontrada")
        db.session.delete(run)
        db.session.commit()

    @staticmethod
    def list_logs(user_id, run_id):
        ScopedAutomationResources.get_run(user_id, run_id)
        from sqlalchemy import or_, and_

        logs = (
            AutomationStepLog.query
            .filter(
                or_(
                    AutomationStepLog.run_id == run_id,
                    and_(
                        AutomationStepLog.run_id.is_(None),
                        AutomationStepLog.automation_id == run_id,
                    ),
                )
            )
            .order_by(AutomationStepLog.step_index)
            .all()
        )
        return [item.to_dict() for item in logs]

    @staticmethod
    def get_log(user_id, log_id):
        log = AutomationStepLog.query.filter_by(id=log_id, user_id=user_id).first()
        if not log:
            raise ValueError("Log não encontrado")
        return log.to_dict()

    @staticmethod
    def upsert_device(user_id, token, platform):
        device = UserDevice.query.filter_by(user_id=user_id, fcm_token=token).first()
        if not device:
            device = UserDevice(user_id=user_id, fcm_token=token, platform=platform)
            db.session.add(device)
        device.active = True
        device.platform = platform
        db.session.commit()
        return ScopedAutomationResources._device_data(device)

    @staticmethod
    def list_devices(user_id):
        devices = UserDevice.query.filter_by(user_id=user_id).all()
        return [ScopedAutomationResources._device_data(item) for item in devices]

    @staticmethod
    def get_device(user_id, device_id):
        device = UserDevice.query.filter_by(id=device_id, user_id=user_id).first()
        if not device:
            raise ValueError("Dispositivo não encontrado")
        return ScopedAutomationResources._device_data(device)

    @staticmethod
    def set_device_active(user_id, device_id, active):
        device = UserDevice.query.filter_by(id=device_id, user_id=user_id).first()
        if not device:
            raise ValueError("Dispositivo não encontrado")
        device.active = active
        db.session.commit()
        return ScopedAutomationResources._device_data(device)

    @staticmethod
    def delete_device(user_id, device_id):
        device = UserDevice.query.filter_by(id=device_id, user_id=user_id).first()
        if not device:
            raise ValueError("Dispositivo não encontrado")
        db.session.delete(device)
        db.session.commit()

    @staticmethod
    def _device_data(device):
        return {"id": device.id, "platform": device.platform, "active": device.active}
