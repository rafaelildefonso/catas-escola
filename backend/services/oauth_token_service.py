"""
Refresh lazy de tokens OAuth (Google). Outros provedores podem estender este módulo.
"""
from __future__ import annotations

import os
import urllib.parse
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, Optional

import httpx


def _parse_expiry(iso_ts: Optional[str]) -> Optional[datetime]:
    if not iso_ts:
        return None
    try:
        dt = datetime.fromisoformat(iso_ts.replace("Z", "+00:00"))
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        return dt
    except Exception:
        return None


def token_expires_soon(iso_ts: Optional[str], skew_seconds: int = 120) -> bool:
    dt = _parse_expiry(iso_ts)
    if dt is None:
        return True
    return dt <= datetime.now(timezone.utc) + timedelta(seconds=skew_seconds)


def _google_client_id() -> Optional[str]:
    return os.getenv("GOOGLE_CLIENT_ID") or os.getenv("WEB_CLIENT_ID")

def _google_client_secret() -> Optional[str]:
    return os.getenv("GOOGLE_CLIENT_SECRET") or os.getenv("GOOGLE_OAUTH_CLIENT_SECRET")


def get_google_auth_url(provider: str, redirect_uri: str, state: str) -> Optional[str]:
    client_id = _google_client_id()
    if not client_id:
        return None

    _SCOPES = {
        "google_gmail": "https://mail.google.com/",
        "google_calendar": "https://www.googleapis.com/auth/calendar.events",
        "google_meet": "https://www.googleapis.com/auth/calendar.events",
        "google_sheets": "https://www.googleapis.com/auth/spreadsheets",
        "google_drive": "https://www.googleapis.com/auth/drive.file",
        "google_docs": "https://www.googleapis.com/auth/drive.readonly",
    }
    scope = _SCOPES.get(provider, "email")

    params = {
        "client_id": client_id,
        "redirect_uri": redirect_uri,
        "response_type": "code",
        "scope": scope,
        "access_type": "offline",
        "state": state,
        "prompt": "consent",
    }
    return "https://accounts.google.com/o/oauth2/v2/auth?" + urllib.parse.urlencode(params)


def exchange_google_auth_code(code: str, redirect_uri: str) -> Optional[Dict[str, Any]]:
    client_id = _google_client_id()
    client_secret = _google_client_secret()
    if not client_id or not client_secret:
        return None
    try:
        with httpx.Client(timeout=30.0) as client:
            r = client.post(
                "https://oauth2.googleapis.com/token",
                data={
                    "grant_type": "authorization_code",
                    "code": code,
                    "redirect_uri": redirect_uri,
                    "client_id": client_id,
                    "client_secret": client_secret,
                },
            )
            r.raise_for_status()
            return r.json()
    except Exception as e:
        print(f"Google auth code exchange failed: {e}")
        return None


def refresh_google_tokens(refresh_token: str) -> Optional[Dict[str, Any]]:
    client_id = _google_client_id()
    client_secret = _google_client_secret()
    if not refresh_token or not client_id or not client_secret:
        return None
    try:
        with httpx.Client(timeout=30.0) as client:
            r = client.post(
                "https://oauth2.googleapis.com/token",
                data={
                    "grant_type": "refresh_token",
                    "refresh_token": refresh_token,
                    "client_id": client_id,
                    "client_secret": client_secret,
                },
            )
            r.raise_for_status()
            return r.json()
    except Exception as e:
        print(f"Google token refresh failed: {e}")
        return None


def is_google_provider(provider: str) -> bool:
    return provider.startswith("google") or provider == "google"
