import httpx
import pytest
from unittest.mock import patch, AsyncMock, MagicMock
from datetime import datetime


class TestModuleRegistry:
    """Fase 1: Verifica se todos os módulos estão registrados corretamente."""

    def test_all_modules_registered(self):
        from worker.modules.registry import _MODULE_REGISTRY
        expected = {
            "http.request", "ai.transform_data", "flow.wait",
            "gmail.send_email", "gmail.create_draft", "gmail.get_unread_emails",
            "google_calendar.create_event", "google_sheets.append_row",
        }
        assert expected.issubset(_MODULE_REGISTRY.keys())

    def test_each_module_is_callable_async_function(self):
        from worker.modules.registry import _MODULE_REGISTRY
        import inspect
        for module_id, func in _MODULE_REGISTRY.items():
            assert inspect.iscoroutinefunction(func), f"{module_id} não é async"

    def test_get_module_function_returns_none_for_unknown(self):
        from worker.modules.registry import get_module_function
        assert get_module_function("nonexistent.module") is None


class TestRunnerUnit:
    """Testa o AutomationRunner com módulos mockados via registry."""

    @pytest.fixture
    def runner(self):
        from worker.runner import AutomationRunner
        return AutomationRunner()

    @pytest.fixture
    def mock_http(self):
        from worker.modules.registry import _MODULE_REGISTRY
        original = _MODULE_REGISTRY.get("http.request")
        mock = AsyncMock(return_value={"status_code": 200, "data": "ok"})
        _MODULE_REGISTRY["http.request"] = mock
        yield mock
        if original:
            _MODULE_REGISTRY["http.request"] = original
        else:
            del _MODULE_REGISTRY["http.request"]

    @pytest.mark.asyncio
    async def test_simple_step_execution(self, runner, mock_http):
        plan = {
            "name": "Test",
            "steps": [{
                "step_id": "step_1",
                "module_id": "http.request",
                "params": {"url": "https://example.com", "method": "GET"},
            }],
        }

        result = await runner.run_plan(plan)

        mock_http.assert_awaited_once()
        assert result["step_1"] == {"status_code": 200, "data": "ok"}

    @pytest.mark.asyncio
    async def test_conditional_branching_true(self, runner, mock_http):
        plan = {
            "name": "Conditional Test",
            "context": {"valor": 10},
            "steps": [{
                "step_id": "check",
                "module_id": "flow.condition",
                "params": {"expression": "{{ valor > 5 }}"},
                "true_branch": [{
                    "step_id": "true_step",
                    "module_id": "http.request",
                    "params": {"url": "https://example.com/true", "method": "GET"},
                }],
                "false_branch": [{
                    "step_id": "false_step",
                    "module_id": "http.request",
                    "params": {"url": "https://example.com/false", "method": "GET"},
                }],
            }],
        }

        result = await runner.run_plan(plan)

        assert mock_http.await_count == 1
        assert "true_step" in result
        assert "false_step" not in result

    @pytest.mark.asyncio
    async def test_conditional_branching_false(self, runner, mock_http):
        plan = {
            "name": "Conditional False",
            "context": {"valor": 1},
            "steps": [{
                "step_id": "check",
                "module_id": "flow.condition",
                "params": {"expression": "{{ valor > 5 }}"},
                "true_branch": [{
                    "step_id": "true_step",
                    "module_id": "http.request",
                    "params": {"url": "https://example.com/true", "method": "GET"},
                }],
                "false_branch": [{
                    "step_id": "false_step",
                    "module_id": "http.request",
                    "params": {"url": "https://example.com/false", "method": "GET"},
                }],
            }],
        }

        result = await runner.run_plan(plan)

        assert mock_http.await_count == 1
        assert "false_step" in result
        assert "true_step" not in result

    @pytest.mark.asyncio
    async def test_conditional_empty_branches(self, runner):
        plan = {
            "name": "Empty Branches",
            "context": {"valor": 10},
            "steps": [{
                "step_id": "check",
                "module_id": "flow.condition",
                "params": {"expression": "{{ valor > 5 }}"},
            }],
        }

        result = await runner.run_plan(plan)
        assert result["check"]["condition_met"] is True

    @pytest.mark.asyncio
    async def test_variable_resolution_between_steps(self, runner):
        from worker.modules.registry import _MODULE_REGISTRY
        original = _MODULE_REGISTRY.get("http.request")

        async def mock_http_impl(params):
            if "user" in params["url"]:
                return {"status_code": 200, "data": {"email_id": "42", "name": "João"}}
            return {"status_code": 200, "data": {"subject": "Bem-vindo!"}}

        mock = AsyncMock(side_effect=mock_http_impl)
        _MODULE_REGISTRY["http.request"] = mock

        try:
            plan = {
                "name": "Var Resolve",
                "steps": [
                    {
                        "step_id": "user_step",
                        "module_id": "http.request",
                        "params": {"url": "https://api.example.com/user", "method": "GET"},
                    },
                    {
                        "step_id": "email_step",
                        "module_id": "http.request",
                        "params": {
                            "url": "https://api.example.com/email/{{user_step.data.email_id}}",
                            "method": "GET",
                        },
                    },
                ],
            }

            result = await runner.run_plan(plan)

            assert result["user_step"]["data"]["email_id"] == "42"
            assert result["email_step"]["data"]["subject"] == "Bem-vindo!"
        finally:
            _MODULE_REGISTRY["http.request"] = original

    @pytest.mark.asyncio
    async def test_trigger_payload_injected(self, runner, mock_http):
        async def side_effect(params):
            return {"status_code": 200, "data": params}

        mock_http.side_effect = side_effect

        plan = {
            "name": "Trigger Test",
            "steps": [{
                "step_id": "s1",
                "module_id": "http.request",
                "params": {
                    "url": "{{trigger.callback_url}}",
                    "method": "POST",
                    "body": {"msg": "{{trigger.message}}"},
                },
            }],
        }

        result = await runner.run_plan(
            plan,
            trigger_payload={"callback_url": "https://hook.example.com", "message": "Hello"},
        )

        assert result["s1"]["data"]["url"] == "https://hook.example.com"
        assert result["s1"]["data"]["body"]["msg"] == "Hello"

    @pytest.mark.asyncio
    async def test_raises_error_on_unknown_module(self, runner):
        plan = {
            "name": "Error Test",
            "steps": [{
                "step_id": "bad",
                "module_id": "nonexistent.module",
                "params": {},
            }],
        }

        with pytest.raises(ValueError, match="não está registrado"):
            await runner.run_plan(plan)

    @pytest.mark.asyncio
    async def test_user_id_propagated_to_context_and_trigger(self, runner, mock_http):
        plan = {
            "name": "User ID Test",
            "steps": [{
                "step_id": "s1",
                "module_id": "http.request",
                "params": {"url": "https://example.com", "method": "GET"},
            }],
        }

        result = await runner.run_plan(plan, user_id="user_123")

        assert result["user_id"] == "user_123"
        assert result["trigger"]["user_id"] == "user_123"

    @pytest.mark.asyncio
    async def test_plan_accepts_automationplan_object(self, runner, mock_http):
        from app.models.automation_plan_schema import AutomationPlan, AutomationStep

        plan_obj = AutomationPlan(
            name="Object Test",
            steps=[AutomationStep(
                step_id="s1", module_id="http.request",
                params={"url": "https://example.com", "method": "GET"},
            )],
        )

        result = await runner.run_plan(plan_obj)

        assert result["s1"]["status_code"] == 200


class TestAutomationRunnerService:
    """Testa a integração do service layer com o runner."""

    @pytest.mark.asyncio
    async def test_start_automation_runs_background_task(self):
        from app.services.automacao.runner_service import AutomationRunnerService

        plan = {
            "name": "Service Test",
            "steps": [{
                "step_id": "s1",
                "module_id": "http.request",
                "params": {"url": "https://example.com", "method": "GET"},
            }],
        }

        with patch("worker.repositorio_dados.atualizar_status_run"), \
             patch("app.services.automacao.registrar_automation_run_service.RegistrarAutomationRunService.executar", return_value=None):

            result = await AutomationRunnerService.start_automation(
                "run_123", plan, user_id="user_123",
            )

            assert "id" in result
            assert result["id"] == "direct-run_123"

    @pytest.mark.asyncio
    async def test_trigger_automation_from_webhook_returns_webhook_id(self):
        from app.services.automacao.runner_service import AutomationRunnerService

        plan = {"name": "Webhook Test", "steps": []}
        result = await AutomationRunnerService.trigger_automation_from_webhook(
            "wh_123", plan, {"source": "zap"}, user_id="user_123",
        )

        assert result["id"].startswith("webhook-")

    @pytest.mark.asyncio
    async def test_start_automation_calls_worker_http_and_returns_run_id(self):
        from app.services.automacao.runner_service import AutomationRunnerService

        plan = {
            "name": "Worker HTTP Test",
            "steps": [{
                "step_id": "s1", "module_id": "http.request",
                "params": {"url": "https://example.com", "method": "GET"},
            }],
        }

        with patch("app.services.automacao.runner_service.httpx.AsyncClient.post") as mock_post:
            mock_post.return_value.status_code = 202
            mock_post.return_value.json = lambda: {"status": "accepted", "automation_id": "run_123"}

            result = await AutomationRunnerService.start_automation("user_123", plan)

        assert "first_execution_run_id" in result
        assert result["first_execution_run_id"].startswith("direct-")

        mock_post.assert_called_once()

    @pytest.mark.asyncio
    async def test_start_automation_logs_error_when_worker_unreachable(self):
        from app.services.automacao.runner_service import AutomationRunnerService

        plan = {"name": "Worker Fail Test", "steps": []}

        with patch("app.services.automacao.runner_service.httpx.AsyncClient.post") as mock_post:
            mock_post.side_effect = httpx.ConnectError("Worker unreachable")

            result = await AutomationRunnerService.start_automation("user_123", plan)

        assert "first_execution_run_id" in result
        assert result["first_execution_run_id"].startswith("direct-")
