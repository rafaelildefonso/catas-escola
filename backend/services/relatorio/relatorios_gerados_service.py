from models.generated_report import GeneratedReport


class RelatoriosGeradosService:
    @staticmethod
    def listar(user_id: str):
        return [report.to_dict() for report in GeneratedReport.listar_do_usuario(user_id)]

    @staticmethod
    def buscar_pdf(user_id: str, report_id: str):
        report = GeneratedReport.buscar_do_usuario(report_id, user_id)
        if not report:
            raise ValueError("Relatório não encontrado.")
        return report
