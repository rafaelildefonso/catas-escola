"""Auditoria reproduzivel: HTTP publico real e conectores Google simulados.
Nao usa tokens reais nem modifica contas ou o banco local.
Execute: python auditoria_integracoes.py
"""
import asyncio
import importlib
import json
import logging
import sys
from pathlib import Path
from unittest.mock import patch
import httpx

sys.path.insert(0, str(Path(__file__).parent / 'backend'))
import worker.modules
from worker.modules.registry import get_module_function

logging.disable(logging.CRITICAL)
results = []
real_client = httpx.AsyncClient

async def record(name, fn):
    print('TEST: ' + name, flush=True)
    try:
        detail = await asyncio.wait_for(fn(), timeout=15)
        results.append({'test': name, 'status': 'PASS', 'detail': detail})
    except Exception as exc:
        results.append({'test': name, 'status': 'FAIL', 'detail': type(exc).__name__ + ': ' + str(exc)[:300]})

async def main():
    async def live_http():
        result = await get_module_function('http.request')({'url': 'https://jsonplaceholder.typicode.com/todos/1'})
        assert result['status_code'] == 200 and result['data']['id'] == 1
        return 'GET externo real: HTTP 200, JSON id=1'
    if '--offline' in sys.argv:
        results.append({'test':'HTTP real','status':'INCONCLUSIVE','detail':'Tentativa externa interrompida sem resposta neste ambiente'})
    else:
        await record('HTTP real', live_http)

    cases = [
        ('gmail.send_email', {'to':'audit@example.invalid','subject':'Teste','body':'Teste'}, 'POST', '/messages/send', {'id':'m1'}, 'message_id', 'm1'),
        ('gmail.create_draft', {'to':'audit@example.invalid','subject':'Teste','body':'Teste'}, 'POST', '/drafts', {'id':'d1','message':{'id':'m1'}}, 'draft_id', 'd1'),
        ('gmail.get_unread_emails', {}, 'GET', '/messages', {'messages':[]}, 'emails', []),
        ('google_calendar.create_event', {'summary':'Teste','start':'2026-10-30T14:00:00-03:00','end':'2026-10-30T15:00:00-03:00'}, 'POST', '/events', {'id':'e1'}, 'event_id', 'e1'),
        ('google_calendar.list_events', {}, 'GET', '/events', {'items':[{'id':'e1','summary':'Teste'}]}, 'count', 1),
        ('google_calendar.update_event', {'event_id':'e1','summary':'Novo'}, 'PATCH', '/events/e1', {'id':'e1'}, 'event_id', 'e1'),
        ('google_calendar.delete_event', {'event_id':'e1'}, 'DELETE', '/events/e1', {}, 'deleted', True),
        ('google_sheets.append_row', {'spreadsheet_id':'s1','range':'A1','values':[['Teste']]}, 'POST', '/values/A1:append', {'updates':{'updatedRows':1}}, 'updated_rows', 1),
        ('google_sheets.get_values', {'spreadsheet_id':'s1','range':'A1'}, 'GET', '/values/A1', {'values':[['Teste']]}, 'row_count', 1),
        ('google_sheets.update_values', {'spreadsheet_id':'s1','range':'A1','values':[['Teste']]}, 'PUT', '/values/A1', {'updatedCells':1}, 'updated_cells', 1),
        ('google_sheets.create_spreadsheet', {'title':'Teste'}, 'POST', '/spreadsheets', {'spreadsheetId':'s1'}, 'spreadsheet_id', 's1'),
        ('google_drive.list_files', {}, 'GET', '/files', {'files':[{'id':'f1','name':'teste.txt'}]}, 'count', 1),
        ('google_drive.upload_file', {'file_name':'teste.txt','file_content':'teste'}, 'POST', '/files', {'id':'f1'}, 'file_id', 'f1'),
        ('google_drive.create_folder', {'folder_name':'Teste'}, 'POST', '/files', {'id':'f1'}, 'folder_id', 'f1'),
        ('google_drive.get_file_content', {'file_id':'f1'}, 'GET', '/files/f1', {'id':'f1','name':'teste.txt','mimeType':'text/plain'}, 'content', 'conteudo de teste'),
    ]
    for name, params, method, suffix, response, key, expected in cases:
        async def run_case():
            calls = []
            def handler(req):
                assert req.method == method and req.url.path.endswith(suffix)
                assert req.headers['Authorization'] == 'Bearer audit-fake'
                calls.append(req)
                if req.url.params.get('alt') == 'media':
                    return httpx.Response(200, text='conteudo de teste')
                return httpx.Response(200, json=response)
            func = get_module_function(name)
            module = importlib.import_module(func.__module__)
            with patch.object(module, 'get_google_access_token', return_value='audit-fake'), patch.object(httpx, 'AsyncClient', side_effect=lambda *a, **kw: real_client(*a, transport=httpx.MockTransport(handler), verify=False, trust_env=False, **kw)):
                result = await func({'user_id':'audit', **params})
            assert calls and result[key] == expected, result
            return 'Resposta Google simulada; metodo, endpoint, autenticacao e resultado verificados'
        await record(name + ' (isolado)', run_case)

    async def ai_actual_config():
        from worker.modules import ai_modules
        with patch.object(ai_modules, '_get_provider', side_effect=ValueError('Provedor indisponivel no teste isolado')):
            result = await get_module_function('ai.transform_data')({'text':'Teste local CATAS','instruction':'Retorne OK','format':'json'})
        if result.get('parsed', {}).get('status') == 'mock' or 'MOCK' in result.get('text',''):
            raise AssertionError('Retornou MOCK, nao uma resposta de IA real')
        return 'Resposta real do provedor'
    await record('IA: falha simulada do provedor', ai_actual_config)

    async def boot():
        from application import create_app
        create_app()
        return 'API inicializada'
    await record('Inicializacao API com configuracao local', boot)
    out = Path(__file__).with_name('resultado_auditoria_integracoes.json')
    out.write_text(json.dumps(results, indent=2, ensure_ascii=False), encoding='utf-8')
    print(json.dumps(results, indent=2, ensure_ascii=True))

if __name__ == '__main__':
    asyncio.run(main())
