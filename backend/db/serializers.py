import json
from datetime import datetime
from uuid import UUID

def to_json(obj):
    # Converte estruturas Python para texto JSON antes de gravá-las em campos compatíveis.
    return json.dumps(obj)

def from_json(json_str):
    # Mantém valores vazios como None, em vez de tentar desserializar uma string inexistente.
    if not json_str:
        return None
    return json.loads(json_str)

def format_datetime(dt):
    # Datas precisam de ISO 8601 para transitarem com segurança em respostas JSON.
    if isinstance(dt, datetime):
        return dt.isoformat()
    return dt

def format_uuid(val):
    # UUIDs não são serializáveis por padrão; sua representação textual é estável.
    if isinstance(val, UUID):
        return str(val)
    return val
