import csv
import io
import json
from collections.abc import Mapping

from openpyxl import Workbook
from reportlab.lib import colors
from reportlab.lib.pagesizes import letter, landscape
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.platypus import Paragraph, SimpleDocTemplate, Table, TableStyle

from services.relatorio.gerar_relatorio_automacoes_service import GerarRelatorioAutomacoesService
from services.relatorio.gerar_relatorio_chat_service import GerarRelatorioChatService

_EXPORT_LIMIT = 10_000


class ExportacaoRelatorioError(ValueError):
    pass


class ExportarRelatorioService:
    @staticmethod
    def executar(user_id: str, tipo: str, formato: str, filtros: dict | None = None):
        if formato not in {"csv", "xlsx", "pdf"}:
            raise ExportacaoRelatorioError("Formato inválido. Use csv, xlsx ou pdf.")
        if tipo not in {"automacoes", "chat"}:
            raise ExportacaoRelatorioError("Relatório inválido. Use automacoes ou chat.")

        dados = ExportarRelatorioService._obter_dados(user_id, tipo, filtros or {})
        colunas, linhas = _tabularizar(dados)
        if formato == "csv":
            conteudo = _gerar_csv(colunas, linhas)
            mime_type = "text/csv; charset=utf-8"
        elif formato == "xlsx":
            conteudo = _gerar_xlsx(colunas, linhas)
            mime_type = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        else:
            conteudo = _gerar_pdf(tipo, colunas, linhas)
            mime_type = "application/pdf"

        return conteudo, mime_type, f"relatorio-{tipo}.{formato}"

    @staticmethod
    def _obter_dados(user_id: str, tipo: str, filtros: dict):
        if tipo == "chat":
            return GerarRelatorioChatService.executar(
                user_id=user_id,
                dias=filtros.get("dias", 30),
            )

        limite = 100
        registros = []
        deslocamento = 0
        total = None
        while total is None or deslocamento < total:
            pagina = GerarRelatorioAutomacoesService.executar(
                user_id=user_id,
                status=filtros.get("status"),
                data_inicio=filtros.get("data_inicio"),
                data_fim=filtros.get("data_fim"),
                busca=filtros.get("busca"),
                ordem=filtros.get("ordem", "created_at"),
                limite=limite,
                deslocamento=deslocamento,
            )
            registros.extend(pagina.get("items", []))
            total = int(pagina.get("total", len(registros)))
            deslocamento += limite
            if len(registros) >= _EXPORT_LIMIT and deslocamento < total:
                raise ExportacaoRelatorioError(
                    "O relatório excede o limite de 10.000 registros. Aplique filtros para exportar."
                )
        return {"total": total, "items": registros}


def _tabularizar(dados: dict):
    if isinstance(dados.get("items"), list):
        registros = dados["items"]
        if not registros:
            return ["total"], [[dados.get("total", 0)]]
        colunas = list(dict.fromkeys(
            chave
            for registro in registros
            for chave in _achatar(registro).keys()
        ))
        return colunas, [
            [_valor_planilha(_achatar(registro).get(coluna, "")) for coluna in colunas]
            for registro in registros
        ]

    achatado = _achatar(dados)
    return ["campo", "valor"], [
        [_valor_planilha(campo), _valor_planilha(valor)]
        for campo, valor in achatado.items()
    ]


def _achatar(valor, prefixo=""):
    resultado = {}
    if isinstance(valor, Mapping):
        for chave, item in valor.items():
            nome = f"{prefixo}.{chave}" if prefixo else str(chave)
            resultado.update(_achatar(item, nome))
    elif isinstance(valor, (list, tuple)):
        resultado[prefixo] = json.dumps(valor, ensure_ascii=False, default=str)
    else:
        resultado[prefixo] = valor
    return resultado


def _valor_planilha(valor):
    if isinstance(valor, str) and valor.startswith(("=", "+", "-", "@")):
        return f"'{valor}"
    return valor


def _gerar_csv(colunas, linhas):
    arquivo = io.StringIO(newline="")
    escritor = csv.writer(arquivo)
    escritor.writerow(colunas)
    escritor.writerows(linhas)
    return io.BytesIO(("\ufeff" + arquivo.getvalue()).encode("utf-8")).getvalue()


def _gerar_xlsx(colunas, linhas):
    workbook = Workbook()
    worksheet = workbook.active
    worksheet.title = "Relatório"
    worksheet.append(colunas)
    for linha in linhas:
        worksheet.append(linha)
    worksheet.freeze_panes = "A2"
    worksheet.auto_filter.ref = worksheet.dimensions
    for column in worksheet.columns:
        letter = column[0].column_letter
        width = min(max(max(len(str(cell.value or "")) for cell in column) + 2, 12), 48)
        worksheet.column_dimensions[letter].width = width
    buffer = io.BytesIO()
    workbook.save(buffer)
    return buffer.getvalue()


def _gerar_pdf(tipo, colunas, linhas):
    buffer = io.BytesIO()
    documento = SimpleDocTemplate(
        buffer,
        pagesize=landscape(letter),
        leftMargin=28,
        rightMargin=28,
        topMargin=32,
        bottomMargin=32,
    )
    estilos = getSampleStyleSheet()
    elementos = [Paragraph(f"Relatório de {tipo}", estilos["Title"])]
    tabela = [[Paragraph(str(valor), estilos["BodyText"]) for valor in colunas]]
    tabela.extend([
        [Paragraph(str(valor if valor is not None else ""), estilos["BodyText"]) for valor in linha]
        for linha in linhas
    ])
    tabela_pdf = Table(tabela, repeatRows=1, hAlign="LEFT")
    tabela_pdf.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#E8EEF8")),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.HexColor("#172B4D")),
        ("GRID", (0, 0), (-1, -1), 0.25, colors.HexColor("#CBD5E1")),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("PADDING", (0, 0), (-1, -1), 5),
    ]))
    elementos.append(tabela_pdf)
    documento.build(elementos)
    return buffer.getvalue()
