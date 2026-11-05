import json
from datetime import datetime
from uuid import UUID

def to_json(obj):
    return json.dumps(obj)

def from_json(json_str):
    if not json_str:
        return None
    return json.loads(json_str)

def format_datetime(dt):
    if isinstance(dt, datetime):
        return dt.isoformat()
    return dt

def format_uuid(val):
    if isinstance(val, UUID):
        return str(val)
    return val
