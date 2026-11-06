"""Modules that turn automation data into an archived, downloadable PDF report."""

from io import BytesIO
import math
from typing import Any

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle
from reportlab.graphics.charts.barcharts import VerticalBarChart
from reportlab.graphics.shapes import Drawing, String

from worker.modules.registry import register_module


def _number(value: Any):
    if isinstance(value, (int, float)) and not isinstance(value, bool):
        return float(value)
    if isinstance(value, str):
        cleaned = value.replace("R$", "").replace(" ", "").strip()
        if "," in cleaned and "." in cleaned:
            if cleaned.rfind(",") > cleaned.rfind("."):
                cleaned = cleaned.replace(".", "").replace(",", ".")
            else:
                cleaned = cleaned.replace(",", "")
        elif "," in cleaned:
            cleaned = cleaned.replace(",", ".")
        try:
            return float(cleaned)
        except ValueError:
            return None
    return None


def _rows(data: Any):
    if isinstance(data, dict):
        data = data.get("values") or data.get("data") or []
    if not isinstance(data, list):
        raise ValueError("Os dados do relatório devem ser uma lista de linhas da planilha.")
    rows = []
    for row in data[:200]:
        if isinstance(row, list):
            rows.append([str(cell)[:80] for cell in row[:8]])
    if not rows:
        raise ValueError("A planilha não possui dados suficientes para gerar o relatório.")
    return rows


def _metrics(rows):
    values = []
    labels = []
    for index, row in enumerate(rows[1:], start=1):
        numeric = next((number for cell in row[1:] if (number := _number(cell)) is not None), None)
        if numeric is not None:
            values.append(numeric)
            labels.append((row[0] if row else str(index))[:12])
    return {
        "rows_analyzed": max(0, len(rows) - 1),
        "total": round(sum(values), 2),
        "average": round(sum(values) / len(values), 2) if values else 0,
        "chart_values": values[:10],
        "chart_labels": labels[:10],
    }


def _chart(metrics):
    values = metrics["chart_values"]
    if not values:
        return None
    drawing = Drawing(460, 210)
    drawing.add(String(0, 192, "Visão comparativa dos dados", fontSize=11, fillColor=colors.HexColor("#243B53")))
    chart = VerticalBarChart()
    chart.x = 32
    chart.y = 28
    chart.height = 145
    chart.width = 400
    chart.data = [values]
    chart.categoryAxis.categoryNames = metrics["chart_labels"]
    chart.categoryAxis.labels.angle = 25
    chart.categoryAxis.labels.fontSize = 7
    chart.valueAxis.labels.fontSize = 7
    chart.valueAxis.valueMin = 0
    chart.valueAxis.valueMax = max(values) * 1.2 if max(values) else 1
    chart.valueAxis.valueStep = max(1, math.ceil(chart.valueAxis.valueMax / 4))
    chart.bars[0].fillColor = colors.HexColor("#3563E9")
    drawing.add(chart)
    return drawing


def _pdf(title: str, source_name: str, rows, metrics, summary: str):
    buffer = BytesIO()
    document = SimpleDocTemplate(
        buffer, pagesize=A4, rightMargin=1.6 * cm, leftMargin=1.6 * cm,
        topMargin=1.6 * cm, bottomMargin=1.6 * cm,
    )
    styles = getSampleStyleSheet()
    content = [Paragraph(title, styles["Title"])]
    if source_name:
        content.append(Paragraph(f"Fonte: {source_name}", styles["BodyText"]))
    content.append(Spacer(1, 10))
    content.append(Paragraph(summary, styles["BodyText"]))
    content.append(Spacer(1, 12))
    metrics_table = Table([
        ["Linhas analisadas", "Total", "Média"],
        [str(metrics["rows_analyzed"]), f'{metrics["total"]:,.2f}', f'{metrics["average"]:,.2f}'],
    ], colWidths=[5.3 * cm, 5.3 * cm, 5.3 * cm])
    metrics_table.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#E8EEFF")),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.HexColor("#243B53")),
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
        ("GRID", (0, 0), (-1, -1), 0.25, colors.HexColor("#CBD5E1")),
        ("ALIGN", (0, 0), (-1, -1), "CENTER"),
        ("PADDING", (0, 0), (-1, -1), 8),
    ]))
    content.extend([metrics_table, Spacer(1, 14)])
    chart = _chart(metrics)
    if chart:
        content.extend([chart, Spacer(1, 10)])
    content.append(Paragraph("Dados utilizados", styles["Heading2"]))
    table = Table(rows[:25], repeatRows=1, colWidths=[16 * cm / max(1, len(rows[0]))] * len(rows[0]))
    table.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#243B53")),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
        ("GRID", (0, 0), (-1, -1), 0.2, colors.HexColor("#CBD5E1")),
        ("FONTSIZE", (0, 0), (-1, -1), 7),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("PADDING", (0, 0), (-1, -1), 4),
    ]))
    content.append(table)
    document.build(content)
    return buffer.getvalue()


@register_module("report.generate_pdf")
async def generate_pdf_report(params: dict) -> dict:
    """Build a PDF with metrics/chart and persist it in the user's report library."""
    user_id = params.get("user_id")
    if not user_id:
        raise ValueError("user_id é obrigatório para gerar um relatório.")
    title = str(params.get("title") or "Relatório automatizado").strip()[:255]
    source_name = str(params.get("source_name") or "Google Planilhas").strip()[:255]
    rows = _rows(params.get("data"))
    metrics = _metrics(rows)
    summary = str(params.get("summary") or (
        f"Foram organizadas {metrics['rows_analyzed']} linhas de dados. "
        "O gráfico apresenta os primeiros valores numéricos identificados na planilha."
    ))
    pdf_content = _pdf(title, source_name, rows, metrics, summary)

    from worker.repositorio_dados import salvar_relatorio_gerado
    report_id = salvar_relatorio_gerado(
        user_id=user_id,
        automation_id=params.get("automation_id"),
        automation_run_id=params.get("run_id"),
        title=title,
        summary=summary,
        source_name=source_name,
        metrics={key: value for key, value in metrics.items() if not key.startswith("chart_")},
        pdf_content=pdf_content,
    )
    return {"report_id": report_id, "title": title, "format": "pdf", "rows_analyzed": metrics["rows_analyzed"]}
