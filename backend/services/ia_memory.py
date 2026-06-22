"""
Memória semântica (RAG) via tabela ia_memory + pgvector.
Histórico de chat usa chat_sessions/messages (repositório chat).
"""
from __future__ import annotations

import json
from datetime import datetime
from typing import Any, Dict, List, Optional

from openai import OpenAI

from core.config import settings
from services.db_supabase import supabase

_EMBED_MODEL = "text-embedding-3-small"
_EMBED_DIM = 1536


def _embedding_client() -> Optional[OpenAI]:
    if not settings.OPENAI_API_KEY:
        return None
    return OpenAI(api_key=settings.OPENAI_API_KEY)


def embed_text(text: str) -> List[float]:
    client = _embedding_client()
    if not client or not text.strip():
        return []
    r = client.embeddings.create(model=_EMBED_MODEL, input=text[:8000])
    vec = r.data[0].embedding
    if len(vec) != _EMBED_DIM:
        return []
    return vec


def load_memory(user_id: str) -> dict:
    try:
        res = (
            supabase.table("ia_memory")
            .select("key, content, metadata")
            .eq("user_id", user_id)
            .order("created_at", desc=True)
            .limit(80)
            .execute()
        )
        merged: Dict[str, Any] = {}
        for row in res.data or []:
            k = row.get("key") or "note"
            merged[k] = row.get("content")
        return merged
    except Exception:
        return {}


def save_memory(user_id: str, memory: dict) -> None:
    for k, v in memory.items():
        if v is None:
            continue
        text = v if isinstance(v, str) else json.dumps(v, ensure_ascii=False)
        row: Dict[str, Any] = {
            "user_id": user_id,
            "key": str(k),
            "content": text[:12000],
            "metadata": {},
            "created_at": datetime.utcnow().isoformat(),
        }
        emb = embed_text(text[:8000])
        if emb:
            row["embedding"] = emb
        try:
            supabase.table("ia_memory").insert(row).execute()
        except Exception:
            pass


def search_similar_memory(user_id: str, query: str, limit: int = 8) -> List[Dict[str, Any]]:
    emb = embed_text(query)
    if not emb:
        return []
    try:
        res = (
            supabase.rpc(
                "match_ia_memory",
                {
                    "query_embedding": emb,
                    "match_user": user_id,
                    "match_count": limit,
                },
            )
            .execute()
        )
        return res.data or []
    except Exception:
        return []


def load_history(user_id: str, limit: int = 20) -> list[dict]:
    try:
        from repositories import chat as chat_repo

        sessions = chat_repo.get_user_sessions(user_id, limit=1)
        if not sessions:
            return []
        sid = sessions[0]["id"]
        msgs = chat_repo.get_session_messages(sid, user_id, limit=limit)
        return [{"role": m["role"], "content": m["content"]} for m in msgs]
    except Exception:
        return []


def save_message(user_id: str, role: str, content: str) -> None:
    try:
        from repositories import chat as chat_repo

        sessions = chat_repo.get_user_sessions(user_id, limit=1)
        if not sessions:
            s = chat_repo.create_session(user_id)
            sid = s["id"]
        else:
            sid = sessions[0]["id"]
        chat_repo.save_message(
            session_id=sid, role=role, content=content, metadata={}
        )
    except Exception:
        pass


def extract_memory_from_conversation(history: list[dict], current_memory: dict) -> dict:
    """Delega extração ao modelo configurado (Claude) — mantido para compatibilidade."""
    if not history:
        return current_memory

    import os
    from anthropic import Anthropic

    api_key = os.getenv("ANTHROPIC_API_KEY")
    if not api_key:
        return current_memory

    history_text = "\n".join(
        f"{m['role'].upper()}: {m['content']}" for m in history[-10:]
    )

    prompt = f"""Você é um sistema de extração de memória. Analise a conversa abaixo e extraia informações importantes sobre o usuário.

MEMÓRIA ATUAL (já conhecida):
{json.dumps(current_memory, ensure_ascii=False, indent=2)}

CONVERSA RECENTE:
{history_text}

Retorne SOMENTE um JSON válido (sem markdown, sem explicação) com a memória ATUALIZADA e MESCLADA. Use esta estrutura:
{{
  "nome": "nome do usuário ou null",
  "preferencias": ["lista de preferências identificadas"],
  "fatos_importantes": ["fatos relevantes sobre o usuário"],
  "contexto_profissional": "profissão ou área de trabalho ou null",
  "outros": {{}}
}}"""

    client = Anthropic(api_key=api_key)
    response = client.messages.create(
        model="claude-3-5-sonnet-20240620",
        max_tokens=800,
        messages=[{"role": "user", "content": prompt}],
    )
    raw = response.content[0].text.strip()
    if raw.startswith("```"):
        raw = raw.split("```")[1]
        if raw.startswith("json"):
            raw = raw[4:]
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return current_memory


def chat(user_id: str, user_message: str) -> str:
    memory = load_memory(user_id)
    history = load_history(user_id, limit=20)

    memory_text = (
        json.dumps(memory, ensure_ascii=False, indent=2)
        if memory
        else "Nenhuma informação ainda."
    )
    system_prompt = f"""Você é um assistente pessoal prestativo e atencioso.

O que você já sabe sobre este usuário:
{memory_text}

Use essas informações para personalizar suas respostas quando relevante.
Seja natural — não mencione explicitamente que "consultou a memória".
Responda sempre em português."""

    messages = history + [{"role": "user", "content": user_message}]

    client = _embedding_client()
    if not client:
        return "OPENAI_API_KEY não configurada para o chat com memória."

    response = client.chat.completions.create(
        model="gpt-4o-mini",
        max_tokens=1000,
        messages=[{"role": "system", "content": system_prompt}, *messages],
    )
    assistant_message = response.choices[0].message.content or ""

    save_message(user_id, "user", user_message)
    save_message(user_id, "assistant", assistant_message)

    total_messages = len(history) + 2
    if total_messages % 10 == 0 or total_messages <= 4:
        updated_memory = extract_memory_from_conversation(
            history
            + [
                {"role": "user", "content": user_message},
                {"role": "assistant", "content": assistant_message},
            ],
            memory,
        )
        save_memory(user_id, updated_memory)

    return assistant_message


def main():
    print("=" * 50)
    print("  Chatbot com Memória (ia_memory + chat_sessions)")
    print("=" * 50)
    user_id = input("\nDigite seu ID de usuário: ").strip() or "user_default"
    while True:
        try:
            user_input = input("\nVocê: ").strip()
        except (EOFError, KeyboardInterrupt):
            break
        if not user_input or user_input.lower() == "sair":
            break
        print("\nAssistente: ", end="", flush=True)
        print(chat(user_id, user_input))


if __name__ == "__main__":
    main()
