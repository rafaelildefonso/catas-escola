import asyncio
import logging
from typing import Any, List, Dict, Union
from models.automation_plan_schema import AutomationPlan, AutomationStep, FlowConditionStep
from worker.utils.resolver import resolve_variables
from worker.modules.registry import get_module_function

import worker.modules  # noqa: F401  # Registra todos os @register_module no catálogo

logger = logging.getLogger(__name__)


def _log_step(
    run_id: str,
    automation_id: str,
    step_index: int,
    module_id: str,
    status: str,
    user_id: str = None,
    result: dict = None,
):
    try:
        from worker.repositorio_dados import registrar_passo_execucao
        registrar_passo_execucao(
            run_id,
            step_index,
            module_id,
            status,
            user_id=user_id,
            result=result,
            automation_id=automation_id,
        )
    except Exception as e:
        logger.warning(f"âš ï¸ Falha ao logar step {step_index} ({module_id}): {e}")


class AutomationRunner:
    """
    Motor de Execução Assíncrono (Runner) em Python puro para o CATAS.
    Roda automações localmente sem latência e custos extras (MVP sem Temporal).
    """
    
    async def run_plan(
        self,
        plan_data: Union[dict, AutomationPlan],
        trigger_payload: dict = None,
        user_id: str = None,
        run_id: str = None,
        automation_id: str = None,
        timeout: int = 300,
    ) -> dict:
        """
        Recebe um dicionário ou objeto AutomationPlan e executa sequencialmente
        todos os seus passos, mantendo e atualizando o contexto de execução.
        user_id é injetado no contexto para que módulos Google possam resolver OAuth tokens.

        Args:
            plan_data: Plano de automação (dict ou AutomationPlan)
            trigger_payload: Payload do gatilho que iniciou a automação
            user_id: ID do usuário dono da automação
            run_id: ID da execução (para rastreamento em logs)
            timeout: Tempo máximo de execução em segundos (default 5 min)
        """
        if isinstance(plan_data, dict):
            plan = AutomationPlan(**plan_data)
        else:
            plan = plan_data

        run_context = plan.context.copy() if plan.context else {}

        if trigger_payload:
            run_context["trigger"] = trigger_payload
        elif "trigger" not in run_context:
            run_context["trigger"] = {}

        if user_id:
            run_context["user_id"] = user_id
            run_context["trigger"]["user_id"] = user_id

        run_context["run_id"] = run_id
        run_context["automation_id"] = automation_id or run_id

        log_prefix = f"[run_id={run_id}]" if run_id else ""
            
        logger.info(f"{log_prefix} ⚡ Iniciando execução da receita: '{plan.name}' (timeout={timeout}s)")
        
        try:
            await asyncio.wait_for(
                self._execute_steps(plan.steps, run_context, log_prefix=log_prefix),
                timeout=timeout,
            )
        except asyncio.TimeoutError:
            logger.error(f"{log_prefix} â° Timeout de {timeout}s excedido na receita '{plan.name}'.")
            raise TimeoutError(
                f"Automação '{plan.name}' excedeu o limite de {timeout}s de execução."
            )

        logger.info(f"{log_prefix} ✅ Execução da receita '{plan.name}' concluída com sucesso.")
        return run_context

    async def _execute_steps(self, steps: List[Union[AutomationStep, FlowConditionStep]], run_context: Dict[str, Any], log_prefix: str = ""):
        run_id = run_context.get("run_id")
        automation_id = run_context.get("automation_id") or run_id
        user_id = run_context.get("user_id")

        for step_index, step in enumerate(steps):
            logger.info(f"{log_prefix} 👉 Executando passo: '{step.step_id}' (módulo: '{step.module_id}')")
            
            if isinstance(step, FlowConditionStep) or step.module_id == "flow.condition":
                expression = step.params.get("expression", "")
                resolved_expr = resolve_variables(expression, run_context)

                if isinstance(resolved_expr, bool):
                    condition_met = resolved_expr
                elif isinstance(resolved_expr, str):
                    condition_met = resolved_expr.strip().lower() in ("true", "1", "yes")
                else:
                    condition_met = bool(resolved_expr)
                    
                logger.info(f"{log_prefix} ðŸ” Condicional '{step.step_id}' resolvida como: {condition_met}")

                true_branch = getattr(step, "true_branch", [])
                false_branch = getattr(step, "false_branch", [])

                if not true_branch and "true_branch" in step.params:
                    true_branch = step.params["true_branch"]
                if not false_branch and "false_branch" in step.params:
                    false_branch = step.params["false_branch"]

                def ensure_steps(branch_steps):
                    ensured = []
                    for s in branch_steps:
                        if isinstance(s, dict):
                            if s.get("module_id") == "flow.condition":
                                ensured.append(FlowConditionStep(**s))
                            else:
                                ensured.append(AutomationStep(**s))
                        else:
                            ensured.append(s)
                    return ensured

                true_branch = ensure_steps(true_branch)
                false_branch = ensure_steps(false_branch)

                branch_to_execute = true_branch if condition_met else false_branch
                if branch_to_execute:
                    logger.info(f"{log_prefix} 🌿 Entrando no ramo: {'true_branch' if condition_met else 'false_branch'}")
                    await self._execute_steps(branch_to_execute, run_context, log_prefix=log_prefix)
                else:
                    logger.info(f"{log_prefix} 🌿 Ramo {'true_branch' if condition_met else 'false_branch'} está vazio. Pulando.")

                run_context[step.step_id] = {"condition_met": condition_met}

            else:
                resolved_params = resolve_variables(step.params, run_context)

                if run_context.get("user_id"):
                    resolved_params["user_id"] = run_context["user_id"]
                resolved_params["run_id"] = run_id
                resolved_params["automation_id"] = automation_id

                func = get_module_function(step.module_id)
                if not func:
                    raise ValueError(
                        f"Módulo '{step.module_id}' não está registrado no catálogo de módulos."
                    )

                # Log: running
                if run_id:
                    _log_step(run_id, automation_id, step_index, step.module_id, "running", user_id=user_id)

                try:
                    result = await func(resolved_params)
                except Exception as e:
                    logger.error(f"{log_prefix} âŒ Erro crítico no passo '{step.step_id}': {e}")
                    if run_id:
                        _log_step(run_id, automation_id, step_index, step.module_id, "error", user_id=user_id, result={"error": str(e)})
                    raise

                run_context[step.step_id] = result

                # Log: success
                if run_id:
                    _log_step(run_id, automation_id, step_index, step.module_id, "success", user_id=user_id, result=result)

                logger.info(f"{log_prefix} 💾 Passo '{step.step_id}' concluído com sucesso.")
