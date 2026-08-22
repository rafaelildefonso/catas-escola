"""
Pipeline de Automação com IA — Padrão Fábrica (Build-Time)
Orquestra: Validação → Interpretação → Seleção de Nódulos →
           Organização → Teste → Geração (AutomationPlan)
"""

import json
import time
import re
import os
from dataclasses import dataclass, field
from typing import Any, List, Dict, Optional
from dotenv import load_dotenv
from openai import AsyncOpenAI
from app.models.automation_plan_schema import AutomationPlan
from app.services.automacao.module_registry import get_full_catalog

load_dotenv()

GROQ_API_KEY = os.getenv("GROQ_API_KEY")
GROQ_MODEL   = os.getenv("GROQ_MODEL", "llama-3.3-70b-versatile")

if not GROQ_API_KEY:
    import logging
    logging.getLogger(__name__).warning(
        "⚠️ GROQ_API_KEY não configurada. O pipeline de meta-automação (AutomationPipelineService) "
        "falhará ao processar requisições. Configure a variável GROQ_API_KEY no .env."
    )

@dataclass
class EstadoPipeline:
    prompt_usuario: str = ""
    user_id: Optional[str] = None
    valido: bool = False
    motivo_invalido: str = ""
    interpretacao: dict = field(default_factory=dict)
    nodulos_selecionados: list = field(default_factory=list)
    nodulos_ordenados: list = field(default_factory=list)
    resultado_teste: dict = field(default_factory=dict)
    resultado_execucao: Optional[AutomationPlan] = None
    historico_conversa: list = field(default_factory=list)
    log: list = field(default_factory=list)

    def registrar(self, etapa: str, msg: str):
        ts = time.strftime("%H:%M:%S")
        entrada = f"[{ts}] [{etapa}] {msg}"
        self.log.append(entrada)
        print(entrada)

class AutomationPipelineService:
    def __init__(self):
        self.client = AsyncOpenAI(
            api_key=GROQ_API_KEY,
            base_url="https://api.groq.com/openai/v1",
        )
        self.model = GROQ_MODEL

    async def chamar_ia(self, estado: EstadoPipeline, system: str, user_msg: str, usar_historico: bool = False) -> str:
        mensagens = [{"role": "system", "content": system}]
        if usar_historico:
            mensagens += list(estado.historico_conversa)

        mensagens.append({"role": "user", "content": user_msg})

        resp = await self.client.chat.completions.create(
            model=self.model,
            max_tokens=2000,
            messages=mensagens,
            temperature=0.1 # Mais determinístico para geração de código/JSON
        )
        resposta = resp.choices[0].message.content
        
        # Créditos (simplificado aqui para brevidade, mantendo lógica do original)
        try:
            from app.services.profile.credit_service import credit_service
            usage = resp.usage
            total_tokens = getattr(usage, "total_tokens", 0)
            credits_cost = credit_service.calculate_credits(total_tokens)
            if estado.user_id and credits_cost > 0:
                credit_service.debit_credits(estado.user_id, credits_cost)
        except Exception:
            pass
            
        if usar_historico:
            estado.historico_conversa.append({"role": "user", "content": user_msg})
            estado.historico_conversa.append({"role": "assistant", "content": resposta})

        return resposta

    def extrair_json(self, texto: str) -> Any:
        try:
            match = re.search(r"```(?:json)?\s*([\s\S]+?)\s*```", texto)
            if match:
                return json.loads(match.group(1))
            return json.loads(texto)
        except Exception:
            try:
                cleaned = texto.strip().split("```json")[-1].split("```")[0].strip()
                return json.loads(cleaned)
            except Exception:
                return {}

    async def etapa_agente_validador(self, estado: EstadoPipeline) -> bool:
        estado.registrar("VALIDAÇÃO", "Verificando se o prompt é válido para automação...")
        system = """Você é um agente validador de prompts para o CATAS.
Avalie se o prompt descreve uma automação de tarefas (ex: enviar email, marcar agenda, preencher planilha).
Retorne APENAS JSON: {"valido": true/false, "motivo": "explicação curta"}"""

        resposta = await self.chamar_ia(estado, system, f"Prompt: {estado.prompt_usuario}")
        resultado = self.extrair_json(resposta)
        estado.valido = resultado.get("valido", False)
        estado.motivo_invalido = resultado.get("motivo", "")
        return estado.valido

    async def etapa_interpretar_prompt(self, estado: EstadoPipeline) -> dict:
        estado.registrar("INTERPRETAÇÃO", "Analisando intenção e contexto...")
        system = "Você é um interpretador de automações. Extraia objetivo, gatilho e entidades. Retorne APENAS JSON."
        resposta = await self.chamar_ia(estado, system, estado.prompt_usuario, usar_historico=True)
        estado.interpretacao = self.extrair_json(resposta)
        return estado.interpretacao

    async def etapa_escolher_nodulos(self, estado: EstadoPipeline) -> list:
        estado.registrar("SELEÇÃO", "Escolhendo módulos do catálogo via MCP/Registry...")
        catalogo = json.dumps(get_full_catalog(), ensure_ascii=False, indent=2)
        system = f"Escolha os módulos necessários do catálogo abaixo para cumprir o objetivo.\nCatálogo:\n{catalogo}\nRetorne JSON: " + '{"nodulos": ["id1", "id2"]}'
        contexto = json.dumps(estado.interpretacao, ensure_ascii=False)
        resposta = await self.chamar_ia(estado, system, f"Contexto:\n{contexto}", usar_historico=True)
        estado.nodulos_selecionados = self.extrair_json(resposta).get("nodulos", [])
        return estado.nodulos_selecionados

    async def etapa_organizar_nodulos(self, estado: EstadoPipeline) -> list:
        estado.registrar("ORGANIZAÇÃO", "Orquestrando a sequência lógica...")
        system = "Organize os módulos em etapas. Retorne JSON: " + '{"ordem": [{"etapa": 1, "nodulos": ["id"], "paralelo": false}]}'
        payload = json.dumps({"nodulos": estado.nodulos_selecionados, "objetivo": estado.interpretacao}, ensure_ascii=False)
        resposta = await self.chamar_ia(estado, system, payload, usar_historico=True)
        estado.nodulos_ordenados = self.extrair_json(resposta).get("ordem", [])
        return estado.nodulos_ordenados

    async def etapa_testar_automacao(self, estado: EstadoPipeline) -> dict:
        estado.registrar("TESTE", "Validando integridade do fluxo...")
        system = "Valide se o fluxo é lógico e seguro. Retorne JSON: " + '{"aprovado": true, "alertas": []}'
        payload = json.dumps({"ordem": estado.nodulos_ordenados}, ensure_ascii=False)
        resposta = await self.chamar_ia(estado, system, payload, usar_historico=True)
        estado.resultado_teste = self.extrair_json(resposta)
        return estado.resultado_teste

    async def etapa_gerar_workflow_plan(self, estado: EstadoPipeline) -> AutomationPlan:
        estado.registrar("WORKFLOW", "Gerando AutomationPlan validado pelo Pydantic...")
        
        # Injetar schema no prompt para garantir output correto
        schema_info = AutomationPlan.model_json_schema()
        
        system = f"""Você é o Arquiteto Final do CATAS. Sua tarefa é gerar o JSON final de execução para o CATAS MVP.
        
        REGRAS CRÍTICAS:
        1. Siga EXATAMENTE este schema: {json.dumps(schema_info)}
        2. Cada step DEVE ter um 'step_id' único e descritivo (ex: 'fetch_email', 'create_event').
        3. Para referenciar dados de passos anteriores, use Jinja2: '{{{{step_id.campo}}}}'.
        4. O 'module_id' deve ser um dos selecionados: {estado.nodulos_selecionados}.
        5. Retorne APENAS o JSON.
        """
        
        payload = json.dumps({
            "prompt_original": estado.prompt_usuario,
            "interpretacao": estado.interpretacao,
            "ordem_planejada": estado.nodulos_ordenados
        }, ensure_ascii=False)
        
        resposta = await self.chamar_ia(estado, system, payload, usar_historico=True)
        workflow_data = self.extrair_json(resposta)
        
        # Validação Pydantic (Garante o Padrão Fábrica)
        try:
            plan = AutomationPlan.model_validate(workflow_data)
            estado.resultado_execucao = plan
            estado.registrar("WORKFLOW", "✅ Plano validado com sucesso!")
            return plan
        except Exception as e:
            estado.registrar("ERRO", f"Falha na validação do schema: {e}")
            # Em um cenário ideal, faríamos um retry com a IA passando o erro
            raise

    async def process(self, user_message: str, user_id: str = None, attachment_urls: List[str] = []) -> Dict[str, Any]:
        estado = EstadoPipeline(prompt_usuario=user_message, user_id=user_id)
        
        try:
            if not await self.etapa_agente_validador(estado):
                return {"pipeline_status": "rejected", "message": estado.motivo_invalido}

            await self.etapa_interpretar_prompt(estado)
            await self.etapa_escolher_nodulos(estado)
            
            if not estado.nodulos_selecionados:
                return {"pipeline_status": "needs_clarification", "message": "Não identifiquei ferramentas para isso."}

            await self.etapa_organizar_nodulos(estado)
            await self.etapa_testar_automacao(estado)
            
            plan = await self.etapa_gerar_workflow_plan(estado)

            return {
                "pipeline_status": "completed",
                "plataforma": "catas/mvp-python",
                "objetivo": estado.interpretacao.get("objetivo", "Automação personalizada"),
                "workflow_json": plan.model_dump(),
                "log": estado.log,
                "message": "Automação preparada com sucesso!"
            }
        except Exception as e:
            return {"pipeline_status": "failed", "message": f"Erro no pipeline: {str(e)}", "log": estado.log}