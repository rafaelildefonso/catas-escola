from pydantic import BaseModel, Field, model_validator, ConfigDict
from typing import List, Dict, Any, Optional, Literal, Union


class AutomationStep(BaseModel):
    model_config = ConfigDict(extra="allow")
    step_id: str = Field(..., description="ID único para este step")
    module_id: str = Field(..., description="ID do módulo a ser executado")
    params: Dict[str, Any] = Field(default_factory=dict, description="Parâmetros para a activity")
    description: Optional[str] = Field(None, description="Descrição do que este passo faz")


class FlowConditionStep(AutomationStep):
    module_id: Literal["flow.condition"] = "flow.condition"
    true_branch: List[Union['FlowConditionStep', AutomationStep]] = Field(default_factory=list)
    false_branch: List[Union['FlowConditionStep', AutomationStep]] = Field(default_factory=list)


class TriggerConfig(BaseModel):
    type: Literal["manual", "cron", "webhook", "schedule"] = "manual"
    cron_expression: Optional[str] = None
    webhook_id: Optional[str] = None
    interval_minutes: Optional[int] = None


class AutomationPlan(BaseModel):
    model_config = ConfigDict(extra="allow")
    name: str = Field(..., description="Nome da automação")
    description: Optional[str] = Field(None, description="Objetivo da automação")
    steps: List[Union[FlowConditionStep, AutomationStep]] = Field(..., description="Lista ordenada de passos")
    context: Dict[str, Any] = Field(default_factory=dict, description="Contexto inicial de variáveis")
    trigger: Optional[TriggerConfig] = Field(default_factory=TriggerConfig)

    @model_validator(mode="after")
    def validate_unique_step_ids(self) -> 'AutomationPlan':
        ids = set()

        def collect_ids(steps_list):
            for step in steps_list:
                if step.step_id in ids:
                    raise ValueError(f"step_id duplicado encontrado: {step.step_id}")
                ids.add(step.step_id)
                if isinstance(step, FlowConditionStep):
                    collect_ids(step.true_branch)
                    collect_ids(step.false_branch)

        collect_ids(self.steps)
        return self

    @model_validator(mode="after")
    def validate_step_references(self) -> 'AutomationPlan':
        return self
