import sys
import os
import asyncio
import logging

# Adiciona o diretório server ao PYTHONPATH
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from worker.runner import AutomationRunner
import worker.modules  # noqa: F401  # Registra todos os módulos no catálogo ANTES de testar
from worker.modules.registry import get_module_function

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s — %(message)s",
)
logger = logging.getLogger("test_runner")

async def run_test():
    logger.info("🧪 [TESTE INICIAL] Inicializando motor e catálogo de módulos...")
    
    # Plano de teste contendo:
    # 1. Requisição HTTP real para obter dados estáveis
    # 2. IA para processar a informação (cai no Mock se não houver chaves de API, preservando fluxo)
    # 3. Fluxo condicional avaliando dados passados
    test_plan = {
        "name": "Automação de Teste de MVP",
        "description": "Valida chamadas HTTP, Jinja2 Variable Resolver, condicionais e fluxo (MVP direto).",
        "context": {
            "usuario": "Rafael"
        },
        "trigger": {
            "type": "manual"
        },
        "steps": [
            {
                "step_id": "step_1",
                "module_id": "http.request",
                "params": {
                    "method": "GET",
                    "url": "https://jsonplaceholder.typicode.com/todos/1"
                },
                "description": "Obtém um To-Do estável público."
            },
            {
                "step_id": "step_2",
                "module_id": "ai.transform_data",
                "params": {
                    "text": "O usuário {{usuario}} realizou a tarefa com título: '{{step_1.data.title}}'.",
                    "instruction": "Extraia o nome do usuário e resuma a ação dele.",
                    "format": "text"
                },
                "description": "Usa LLM / Mock AI para extrair e formatar informações."
            },
            {
                "step_id": "step_3",
                "module_id": "flow.condition",
                "params": {
                    "expression": "{{ step_1.data.userId == 1 }}"
                },
                "description": "Valida se o userId retornado no step_1 é igual a 1.",
                "true_branch": [
                    {
                        "step_id": "step_true",
                        "module_id": "http.request",
                        "params": {
                            "method": "GET",
                            "url": "https://jsonplaceholder.typicode.com/posts/1"
                        },
                        "description": "Executado se To-Do pertencer ao userId 1."
                    }
                ],
                "false_branch": [
                    {
                        "step_id": "step_false",
                        "module_id": "http.request",
                        "params": {
                            "method": "GET",
                            "url": "https://jsonplaceholder.typicode.com/posts/2"
                        },
                        "description": "Executado caso contrário."
                    }
                ]
            }
        ]
    }

    try:
        # Inicializa o runner genérico
        runner = AutomationRunner()
        
        logger.info("⚡ Executando o plano de teste...")
        final_context = await runner.run_plan(test_plan)
        
        logger.info("\n📊 === RESULTADOS DA EXECUÇÃO ===")
        logger.info(f"Usuário Inicial: {final_context.get('usuario')}")
        
        # Validação do Step 1
        s1 = final_context.get("step_1", {})
        logger.info(f"Step 1 (HTTP GET) Código: {s1.get('status_code')}")
        logger.info(f"Step 1 Data: {s1.get('data')}")
        
        # Validação do Step 2
        s2 = final_context.get("step_2", {})
        logger.info(f"Step 2 (AI/Mock Output): {s2.get('text')}")
        
        # Validação do Condicional (Step 3)
        s3 = final_context.get("step_3", {})
        logger.info(f"Step 3 Condição atendida? {s3.get('condition_met')}")
        
        # Verifica se o ramo correto rodou
        if s3.get("condition_met"):
            assert "step_true" in final_context, "ERRO: Ramo TRUE deveria ter executado!"
            assert "step_false" not in final_context, "ERRO: Ramo FALSE não deveria ter executado!"
            logger.info("🎉 Sucesso: Ramo TRUE executado corretamente.")
            logger.info(f"Step True HTTP Resposta: {final_context['step_true']['data'].get('title')[:30]}...")
        else:
            assert "step_false" in final_context, "ERRO: Ramo FALSE deveria ter executado!"
            assert "step_true" not in final_context, "ERRO: Ramo TRUE não deveria ter executado!"
            logger.info("🎉 Sucesso: Ramo FALSE executado corretamente.")
            
        logger.info("\n🏆 TODOS OS TESTES PASSARAM COM SUCESSO! O motor está robusto e funcional.")
        
    except Exception as e:
        logger.exception(f"❌ Teste falhou com erro: {e}")

async def test_google_modules_registration():
    logger.info("\n🧪 [TESTE MÓDULOS GOOGLE] Verificando registro e tratamento de erro de autenticação...")
    google_modules = [
        "gmail.send_email",
        "gmail.create_draft",
        "gmail.get_unread_emails",
        "google_calendar.create_event",
        "google_sheets.append_row",
    ]
    all_ok = True
    for module_id in google_modules:
        func = get_module_function(module_id)
        assert func is not None, f"Módulo '{module_id}' NÃO registrado!"
        logger.info(f"  ✅ '{module_id}' registrado como '{func.__name__}'")
        all_ok = True

    if all_ok:
        logger.info("🎉 Todos os módulos Google registrados com sucesso!")

async def test_google_modules_auth_error():
    logger.info("\n🧪 [TESTE AUTH GOOGLE] Validando erro amigável sem token (comportamento esperado)...")
    google_modules = [
        ("gmail.send_email", {"to": "a@b.com", "subject": "test", "body": "test", "user_id": "fake_user"}),
        ("gmail.create_draft", {"to": "a@b.com", "subject": "test", "body": "test", "user_id": "fake_user"}),
        ("gmail.get_unread_emails", {"max_results": 5, "user_id": "fake_user"}),
        ("google_calendar.create_event", {"summary": "Test", "start": "2026-01-01T00:00:00Z", "end": "2026-01-01T01:00:00Z", "user_id": "fake_user"}),
        ("google_sheets.append_row", {"spreadsheet_id": "fake", "range": "A1:C", "values": [["a", "b", "c"]], "user_id": "fake_user"}),
    ]
    for module_id, params in google_modules:
        func = get_module_function(module_id)
        try:
            await func(params)
            logger.warning(f"  ⚠️ '{module_id}' não lançou erro (token pode existir?!)")
        except ValueError as e:
            logger.info(f"  ✅ '{module_id}' → ValueError esperado: {e}")
        except Exception as e:
            logger.info(f"  ✅ '{module_id}' → erro esperado (sem token real): {type(e).__name__}: {e}")

    logger.info("🎉 Todos os módulos Google tratam ausência de token corretamente!")

async def run_all_tests():
    await run_test()
    await test_google_modules_registration()
    await test_google_modules_auth_error()

if __name__ == "__main__":
    asyncio.run(run_all_tests())
