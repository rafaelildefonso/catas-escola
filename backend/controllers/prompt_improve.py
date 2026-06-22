from flask import Blueprint, request, jsonify

prompt_bp = Blueprint("prompt", __name__, url_prefix="/prompt")


@prompt_bp.route("/improve", methods=["POST"])
def improve_prompt():
    data = request.get_json(silent=True) or {}
    text = (data.get("text") or "").strip()

    if len(text) < 5:
        return jsonify({"original": data.get("text", ""), "improved": text})

    is_question = any(text.lower().startswith(q) for q in ["o que", "como", "por que", "quando", "onde", "qual", "quem"])
    is_code_request = any(keyword in text.lower() for keyword in ["código", "código", "programa", "função", "criar", "desenvolver", "implementar", "bug", "erro"])
    is_analysis = any(keyword in text.lower() for keyword in ["analisar", "análise", "revisar", "explicar", "entender"])

    if is_code_request:
        improved = f"""# Solicitação de Desenvolvimento

## Objetivo
{text.capitalize()}

## Requisitos Esperados
- Código limpo e bem documentado
- Seguir as melhores práticas da linguagem
- Incluir tratamento de erros quando aplicável
- Adicionar comentários explicativos em partes complexas

## Entrega
Por favor, forneça o código completo, funcional e pronto para uso."""
    elif is_analysis:
        improved = f"""# Solicitação de Análise

## Tarefa
{text.capitalize()}

## Formato Esperado
- Análise detalhada e estruturada
- Pontos principais destacados
- Exemplos práticos quando relevante
- Conclusão clara e objetiva

## Profundidade
Forneça uma análise completa, mas mantenha a clareza e objetividade."""
    elif is_question:
        improved = f"""# Pergunta

{text.capitalize()}

## Formato de Resposta Esperado
- Resposta clara e direta
- Explicação fundamentada
- Exemplos práticos quando aplicável
- Recursos adicionais se houver

Por favor, seja preciso e completo na sua resposta."""
    else:
        improved = f"""# Solicitação

## Descrição
{text.capitalize()}

## Requisitos
- Resposta clara e objetiva
- Informações precisas e atualizadas
- Exemplos práticos quando relevante
- Explicações detalhadas quando necessário

## Formato
Forneça uma resposta completa, bem estruturada e fácil de entender."""

    return jsonify({
        "original": data.get("text", ""),
        "improved": improved.strip()
    })
