import base64
import hashlib
import os

from cryptography.fernet import Fernet
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

from core.config import settings

V2_PREFIX = "v2:"


def _aes256_key() -> bytes:
    if not settings.ENCRYPTION_KEY:
        raise ValueError("ENCRYPTION_KEY não configurada no ambiente.")
    return hashlib.sha256(settings.ENCRYPTION_KEY.encode("utf-8")).digest()


def get_fernet() -> Fernet:
    if not settings.ENCRYPTION_KEY:
        raise ValueError("ENCRYPTION_KEY não configurada no ambiente.")
    return Fernet(settings.ENCRYPTION_KEY.encode())


def encrypt_value(value: str) -> str:
    """Criptografia em repouso: AES-256-GCM com prefixo v2 (recomendado)."""
    if not value:
        return value
    key = _aes256_key()
    aes = AESGCM(key)
    nonce = os.urandom(12)
    ciphertext = aes.encrypt(nonce, value.encode("utf-8"), None)
    token = base64.urlsafe_b64encode(nonce + ciphertext).decode("ascii")
    return V2_PREFIX + token


def decrypt_value(encrypted_value: str) -> str:
    if not encrypted_value:
        return encrypted_value
    if encrypted_value.startswith(V2_PREFIX):
        try:
            raw = base64.urlsafe_b64decode(encrypted_value[len(V2_PREFIX) :].encode("ascii"))
            nonce, ct = raw[:12], raw[12:]
            aes = AESGCM(_aes256_key())
            return aes.decrypt(nonce, ct, None).decode("utf-8")
        except Exception as e:
            print(f"AES-GCM decrypt failed: {e}")
            return encrypted_value
    try:
        f = get_fernet()
        return f.decrypt(encrypted_value.encode()).decode()
    except Exception as e:
        print(
            f"Failed to decrypt value. It might be an unencrypted legacy token. Error: {e}"
        )
        return encrypted_value
