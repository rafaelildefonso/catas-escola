"""
Pipeline de Automação com IA — Padrão Fábrica (Build-Time)
Orquestra: Validação → Interpretação → Seleção de Nódulos →
           Organização → Teste → Geração (AutomationPlan)
"""

import json
import logging
import os
import re
import time
from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional

from dotenv import load_dotenv
from openai import AsyncOpenAI
from pydantic import ValidationError

import worker.modules  # noqa: F401 - registra os módulos executáveis
from models.automation_plan_schema import AutomationPlan
from services.automacao.module_registry import get_full_catalog, get_module_spec
from services.automation.schedule import next_run_at
from worker.modules.registry import get_module_function

load_dotenv()

logger = logging.getLogger(__name__)

GROQ_API_KEY = os.getenv("GROQ_API_KEY")
GROQ_MODEL = os.getenv("GROQ_MODEL", "openai/gpt-oss-20b")
AUTOMATION_TIMEZONE = os.getenv("AUTOMATION_TIMEZONE", "America/Sao_Paulo")

PARAMETER_ALIASES = {
    "gmail.send_email": {
        "recipient": "to",
        "destinatario": "to",
        "destinatário": "to",
        "message": "body",
        "mensagem": "body",
        "corpo": "body",
    },
    "gmail.create_draft": {
        "recipient": "to",
        "destinatario": "to",
        "destinatário": "to",
        "message": "body",
        "mensagem": "body",
        "corpo": "body",
    },
    "google_calendar.create_event": {
        "title": "summary",
        "titulo": "summary",
        "título": "summary",
        "start_time": "start",
        "end_time": "end",
    },
}

PARAMETER_LABELS = {
    "to": "o destinatário",
    "subject": "o assunto",
    "body": "a mensagem",
    "summary": "o nome do evento",
    "start": "o horário de início",
    "end": "o horário de término",
    "spreadsheet_id": "qual planilha deve ser usada",
    "range": "o intervalo de células",
    "values": "os dados que devem ser adicionados",
    "title": "o nome da planilha",
    "folder_name": "o nome da pasta",
    "file_name": "o nome do arquivo",
    "file_content": "o conteúdo do arquivo",
    "file_id": "qual arquivo deve ser usado",
    "event_id": "qual evento deve ser alterado",
    "duration": "por quanto tempo deve aguardar",
}

if not GROQ_API_KEY:
    logger.warning(
        "GROQ_API_KEY não configurada. O pipeline de meta-automação (AutomationPipelineService) "
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
        logger.info(entrada)


class AutomationPipelineService:
    def __init__(self):
        self.client = AsyncOpenAI(
            api_key=GROQ_API_KEY,
            base_url="https://api.groq.com/openai/v1",
        )
        self.model = GROQ_MODEL

    async def chamar_ia(
        self,
        estado: EstadoPipeline,
        system: str,
        user_msg: str,
        usar_historico: bool = False,
    ) -> str:
        mensagens = [{"role": "system", "content": system}]
        if usar_historico:
            mensagens += list(estado.historico_conversa)

        mensagens.append({"role": "user", "content": user_msg})

        resp = await self.client.chat.completions.create(
            model=self.model,
            max_tokens=2000,
            messages=mensagens,
            temperature=0.1,  # Mais determinístico para geração de código/JSON
        )
        resposta = resp.choices[0].message.content

        # Créditos (simplificado aqui para brevidade, mantendo lógica do original)
        try:
            from services.profile.credit_service import credit_service

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

    @staticmethod
    def _extrair_intervalo(prompt: str) -> Optional[dict]:
        match = re.search(
            r"\ba\s+cada\s+(\d+)\s*(minutos?|mins?|horas?|hrs?)\b",
            prompt.casefold(),
        )
        if not match:
            return None
        amount = int(match.group(1))
        unit = match.group(2)
        minutes = amount * 60 if unit.startswith(("hora", "hr")) else amount
        if not 1 <= minutes <= 10080:
            return None
        return {"type": "schedule", "interval_minutes": minutes}

    @staticmethod
    def _extrair_dados_email(prompt: str) -> dict:
        result = {}
        email = re.search(r"[\w.!#$%&'*+/=?^`{|}~-]+@[\w-]+(?:\.[\w-]+)+", prompt)
        subject = re.search(r"\bassunto\s+[\"“](.*?)[\"”]", prompt, re.IGNORECASE)
        body = re.search(
            r"\b(?:mensagem|corpo)\s+[\"“](.*?)[\"”]", prompt, re.IGNORECASE
        )
        if email:
            result["to"] = email.group(0)
        if subject:
            result["subject"] = subject.group(1).strip()
        if body:
            result["body"] = body.group(1).strip()
        return result

    @staticmethod
    def _extrair_nome(prompt: str) -> Optional[str]:
        match = re.search(
            r"\bautoma(?:ç|c)ão\s+chamada\s+(.+?)\s+que\b",
            prompt,
            re.IGNORECASE,
        )
        return match.group(1).strip() if match else None

    @staticmethod
    def _normalizar_parametros(module_id: str, params: Any) -> dict:
        normalized = dict(params) if isinstance(params, dict) else {}
        for alias, canonical in PARAMETER_ALIASES.get(module_id, {}).items():
            if not normalized.get(canonical) and normalized.get(alias):
                normalized[canonical] = normalized[alias]
            normalized.pop(alias, None)
        return normalized

    def _normalizar_workflow(self, estado: EstadoPipeline, workflow_data: Any) -> dict:
        if not isinstance(workflow_data, dict):
            raise ValueError(
                "Não consegui organizar essa automação. Por favor, envie o mesmo pedido novamente."
            )

        data = dict(workflow_data)
        data["name"] = (
            self._extrair_nome(estado.prompt_usuario)
            or data.get("name")
            or estado.interpretacao.get("objetivo")
            or "Nova automação"
        )
        email_data = self._extrair_dados_email(estado.prompt_usuario)
        steps = []
        for raw_step in data.get("steps", []):
            step = dict(raw_step) if isinstance(raw_step, dict) else {}
            module_id = step.get("module_id")
            params = self._normalizar_parametros(module_id, step.get("params"))
            if module_id in {"gmail.send_email", "gmail.create_draft"}:
                for key, value in email_data.items():
                    # Dados escritos pelo usuário têm prioridade sobre variáveis
                    # inventadas pela IA, como {{destinatario}}.
                    params[key] = value
            step["params"] = params
            steps.append(step)
        data["steps"] = steps

        interpreted_trigger = estado.interpretacao.get("trigger")
        inferred_trigger = self._extrair_intervalo(estado.prompt_usuario)
        if inferred_trigger:
            data["trigger"] = inferred_trigger
        elif isinstance(interpreted_trigger, dict) and interpreted_trigger.get(
            "type"
        ) in {"schedule", "cron"}:
            data["trigger"] = interpreted_trigger
        return data

    def _filtrar_informacoes_faltantes(self, estado: EstadoPipeline) -> list:
        missing = estado.interpretacao.get("missing_information", [])
        if not isinstance(missing, list):
            return []
        email_data = self._extrair_dados_email(estado.prompt_usuario)
        has_schedule = self._extrair_intervalo(estado.prompt_usuario) is not None
        filtered = []
        for item in missing:
            text = str(item).casefold()
            if "destinat" in text and email_data.get("to"):
                continue
            if "assunto" in text and email_data.get("subject"):
                continue
            if any(
                term in text for term in ("mensagem", "corpo", "conteúdo")
            ) and email_data.get("body"):
                continue
            if (
                any(term in text for term in ("agendamento", "frequência", "intervalo"))
                and has_schedule
            ):
                continue
            filtered.append(str(item))
        return filtered

    @staticmethod
    def _mensagem_dados_faltantes(module_name: str, missing: list[str]) -> str:
        labels = [
            PARAMETER_LABELS.get(key, "uma informação necessária") for key in missing
        ]
        if len(labels) == 1:
            fields = labels[0]
        else:
            fields = ", ".join(labels[:-1]) + " e " + labels[-1]
        return f"Para criar a ação {module_name.lower()}, preciso que você informe {fields}."

    @staticmethod
    def _referencias_de_variaveis(value: Any) -> set[str]:
        if isinstance(value, str):
            return {
                match.group(1).split(".", 1)[0]
                for match in re.finditer(
                    r"{{\s*([A-Za-z_][A-Za-z0-9_.]*)\s*}}",
                    value,
                )
            }
        if isinstance(value, dict):
            references = set()
            for nested in value.values():
                references.update(
                    AutomationPipelineService._referencias_de_variaveis(nested)
                )
            return references
        if isinstance(value, list):
            references = set()
            for nested in value:
                references.update(
                    AutomationPipelineService._referencias_de_variaveis(nested)
                )
            return references
        return set()

    async def etapa_agente_validador(self, estado: EstadoPipeline) -> bool:
        estado.registrar(
            "VALIDAÇÃO", "Verificando se o prompt é válido para automação..."
        )
        system = """Você é um agente validador de prompts para o CATAS.
Avalie se o prompt descreve uma automação de tarefas (ex: enviar email, marcar agenda, preencher planilha).
Retorne APENAS JSON: {"valido": true/false, "motivo": "explicação curta"}"""

        resposta = await self.chamar_ia(
            estado, system, f"Prompt: {estado.prompt_usuario}"
        )
        resultado = self.extrair_json(resposta)
        estado.valido = resultado.get("valido", False)
        estado.motivo_invalido = resultado.get("motivo", "")
        return estado.valido

    async def etapa_interpretar_prompt(self, estado: EstadoPipeline) -> dict:
        estado.registrar("INTERPRETAÇÃO", "Analisando intenção e contexto...")
        system = f"""Você interpreta pedidos de automação do CATAS. Retorne APENAS JSON com
        objetivo, entidades e trigger. Escolha trigger.type='schedule' e interval_minutes
        para 'a cada N minutos/horas'; trigger.type='cron' e cron_expression de cinco campos
        UTC para horários recorrentes; trigger.type='manual' para ações imediatas.
        Considere os horários informados pelo usuário no fuso {AUTOMATION_TIMEZONE} e
        converta-os para UTC antes de montar cron_expression.
        Nunca converta um pedido recorrente em manual. Se faltar horário, frequência,
        destinatário ou outro dado essencial, indique missing_information em uma lista.
        Não invente dados pessoais nem destinos."""
        resposta = await self.chamar_ia(
            estado, system, estado.prompt_usuario, usar_historico=True
        )
        estado.interpretacao = self.extrair_json(resposta)
        if not isinstance(estado.interpretacao, dict):
            estado.interpretacao = {}
        inferred_trigger = self._extrair_intervalo(estado.prompt_usuario)
        current_trigger = estado.interpretacao.get("trigger")
        if inferred_trigger and (
            not isinstance(current_trigger, dict)
            or current_trigger.get("type") in {None, "manual"}
        ):
            estado.interpretacao["trigger"] = inferred_trigger
        return estado.interpretacao

    async def etapa_escolher_nodulos(self, estado: EstadoPipeline) -> list:
        estado.registrar(
            "SELEÇÃO", "Escolhendo módulos do catálogo via MCP/Registry..."
        )
        catalogo = json.dumps(
            [
                module
                for module in get_full_catalog()
                if get_module_function(module["id"])
            ],
            ensure_ascii=False,
            indent=2,
        )
        system = (
            f"Escolha os módulos necessários do catálogo abaixo para cumprir o objetivo.\nCatálogo:\n{catalogo}\nRetorne JSON: "
            + '{"nodulos": ["id1", "id2"]}'
        )
        contexto = json.dumps(estado.interpretacao, ensure_ascii=False)
        resposta = await self.chamar_ia(
            estado, system, f"Contexto:\n{contexto}", usar_historico=True
        )
        escolhidos = self.extrair_json(resposta).get("nodulos", [])
        estado.nodulos_selecionados = [
            module_id
            for module_id in escolhidos
            if isinstance(module_id, str)
            and get_module_spec(module_id)
            and get_module_function(module_id)
        ]
        return estado.nodulos_selecionados

    async def etapa_organizar_nodulos(self, estado: EstadoPipeline) -> list:
        estado.registrar("ORGANIZAÇÃO", "Orquestrando a sequência lógica...")
        system = (
            "Organize os módulos em etapas. Retorne JSON: "
            + '{"ordem": [{"etapa": 1, "nodulos": ["id"], "paralelo": false}]}'
        )
        payload = json.dumps(
            {"nodulos": estado.nodulos_selecionados, "objetivo": estado.interpretacao},
            ensure_ascii=False,
        )
        resposta = await self.chamar_ia(estado, system, payload, usar_historico=True)
        estado.nodulos_ordenados = self.extrair_json(resposta).get("ordem", [])
        return estado.nodulos_ordenados

    async def etapa_testar_automacao(self, estado: EstadoPipeline) -> dict:
        estado.registrar("TESTE", "Validando integridade do fluxo...")
        selected = set(estado.nodulos_selecionados)
        ordered = []
        groups = (
            estado.nodulos_ordenados
            if isinstance(estado.nodulos_ordenados, list)
            else []
        )
        for group in groups:
            if not isinstance(group, dict):
                continue
            for module_id in group.get("nodulos", []):
                if module_id in selected and module_id not in ordered:
                    ordered.append(module_id)
        ordered.extend(
            module_id
            for module_id in estado.nodulos_selecionados
            if module_id not in ordered
        )
        estado.nodulos_ordenados = [
            {"etapa": index, "nodulos": [module_id], "paralelo": False}
            for index, module_id in enumerate(ordered, start=1)
        ]
        estado.resultado_teste = {"aprovado": bool(ordered), "alertas": []}
        return estado.resultado_teste

    async def etapa_gerar_workflow_plan(self, estado: EstadoPipeline) -> AutomationPlan:
        estado.registrar("WORKFLOW", "Gerando AutomationPlan validado pelo Pydantic...")

        # Injetar schema no prompt para garantir output correto
        schema_info = AutomationPlan.model_json_schema()
        module_contracts = [
            {
                "module_id": module_id,
                "description": spec.description,
                "required_params": spec.required_params,
            }
            for module_id in estado.nodulos_selecionados
            if (spec := get_module_spec(module_id))
        ]

        system = f"""Você é o Arquiteto Final do CATAS. Sua tarefa é gerar o JSON final de execução para o CATAS MVP.
        
        REGRAS CRÍTICAS:
        1. Siga EXATAMENTE este schema: {json.dumps(schema_info)}
        2. Cada step DEVE ter um 'step_id' único e descritivo (ex: 'fetch_email', 'create_event').
        3. Para referenciar dados de passos anteriores, use Jinja2: '{{{{step_id.campo}}}}'.
        4. O 'module_id' e os nomes dos parâmetros devem seguir exatamente estes
           contratos: {json.dumps(module_contracts, ensure_ascii=False)}.
        5. Copie o trigger identificado na interpretação. Para pedidos recorrentes,
           use schedule/interval_minutes ou cron/cron_expression em UTC, nunca manual.
        6. Preencha os parâmetros obrigatórios de cada módulo com dados fornecidos
           pelo usuário. Não invente e-mails, IDs ou horários.
        7. Retorne APENAS o JSON.
        """

        payload = json.dumps(
            {
                "prompt_original": estado.prompt_usuario,
                "interpretacao": estado.interpretacao,
                "ordem_planejada": estado.nodulos_ordenados,
                "contratos_das_acoes": module_contracts,
            },
            ensure_ascii=False,
        )

        resposta = await self.chamar_ia(estado, system, payload, usar_historico=True)
        workflow_data = self.extrair_json(resposta)

        # Validação Pydantic (Garante o Padrão Fábrica)
        try:
            workflow_data = self._normalizar_workflow(estado, workflow_data)
            try:
                plan = AutomationPlan.model_validate(workflow_data)
            except ValidationError as exc:
                logger.warning("Plano de automação gerado fora do schema: %s", exc)
                raise ValueError(
                    "Não consegui organizar essa automação. Por favor, envie o mesmo pedido novamente."
                ) from exc
            if not plan.steps:
                raise ValueError(
                    "Não consegui identificar qual ação deve ser realizada."
                )
            available_references = set(plan.context) | {"trigger", "user", "user_id"}
            for step in plan.steps:
                if (
                    step.module_id not in estado.nodulos_selecionados
                    or not get_module_function(step.module_id)
                ):
                    raise ValueError(
                        "Não consegui escolher uma ação disponível para esse pedido."
                    )
                spec = get_module_spec(step.module_id)
                missing = [
                    key for key in spec.required_params if not step.params.get(key)
                ]
                if missing:
                    raise ValueError(self._mensagem_dados_faltantes(spec.name, missing))
                unknown_references = (
                    self._referencias_de_variaveis(step.params) - available_references
                )
                if unknown_references:
                    raise ValueError(
                        "Não consegui preencher todos os dados dessa ação. "
                        "Descreva os valores diretamente no pedido."
                    )
                if plan.trigger.type in {"schedule", "cron"} and any(
                    "{{trigger." in str(value)
                    and "{{trigger.scheduled_at}}" not in str(value)
                    for value in step.params.values()
                ):
                    raise ValueError(
                        "O agendamento não fornece dados de um evento. Descreva os dados necessários para a ação"
                    )
                available_references.add(step.step_id)
            if plan.trigger.type == "webhook":
                raise ValueError(
                    "A execução por link externo ainda não está disponível."
                )
            try:
                next_run_at(plan.trigger.model_dump())
            except ValueError as exc:
                raise ValueError(
                    "Não consegui entender quando a automação deve acontecer. "
                    "Informe, por exemplo, ‘a cada 120 minutos’ ou ‘todos os dias às 9h’."
                ) from exc
            estado.resultado_execucao = plan
            estado.registrar("WORKFLOW", "Plano validado com sucesso.")
            return plan
        except Exception as e:
            estado.registrar("ERRO", f"Falha na validação do schema: {e}")
            # Em um cenário ideal, faríamos um retry com a IA passando o erro
            raise

    async def process(
        self,
        user_message: str,
        user_id: str = None,
        attachment_urls: List[str] = None,
        preferred_modules: Optional[List[str]] = None,
    ) -> Dict[str, Any]:
        estado = EstadoPipeline(prompt_usuario=user_message, user_id=user_id)

        try:
            if not await self.etapa_agente_validador(estado):
                return {
                    "pipeline_status": "rejected",
                    "message": estado.motivo_invalido,
                }

            await self.etapa_interpretar_prompt(estado)
            missing = self._filtrar_informacoes_faltantes(estado)
            if missing:
                return {
                    "pipeline_status": "needs_clarification",
                    "message": "Preciso de mais detalhes: " + ", ".join(missing),
                }
            preferred = list(dict.fromkeys(preferred_modules or []))
            estado.nodulos_selecionados = [
                module_id
                for module_id in preferred
                if get_module_spec(module_id) and get_module_function(module_id)
            ]
            if not estado.nodulos_selecionados:
                await self.etapa_escolher_nodulos(estado)

            if not estado.nodulos_selecionados:
                return {
                    "pipeline_status": "needs_clarification",
                    "message": "Não identifiquei ferramentas para isso.",
                }

            await self.etapa_organizar_nodulos(estado)
            await self.etapa_testar_automacao(estado)
            if estado.resultado_teste.get("aprovado") is False:
                return {
                    "pipeline_status": "needs_clarification",
                    "message": "Não consegui organizar as ações dessa automação. Tente enviar o pedido novamente.",
                }

            plan = await self.etapa_gerar_workflow_plan(estado)
            recurring_request = re.search(
                r"\b(a cada|todos os dias|todo dia|toda semana|toda segunda|diariamente|semanalmente)\b",
                user_message.casefold(),
            )
            if recurring_request and plan.trigger.type == "manual":
                return {
                    "pipeline_status": "needs_clarification",
                    "message": "Entendi que a tarefa deve se repetir, mas preciso da frequência ou horário para agendá-la.",
                }

            return {
                "pipeline_status": "completed",
                "plataforma": "catas/mvp-python",
                "objetivo": estado.interpretacao.get(
                    "objetivo", "Automação personalizada"
                ),
                "workflow_json": plan.model_dump(),
                "log": estado.log,
                "message": "Automação preparada com sucesso!",
            }
        except ValueError as e:
            return {
                "pipeline_status": "needs_clarification",
                "message": str(e),
                "log": estado.log,
            }
        except Exception as e:
            estado.registrar("ERRO", f"Falha inesperada no pipeline: {e}")
            return {
                "pipeline_status": "failed",
                "message": "Não consegui preparar a automação agora.",
                "log": estado.log,
            }
