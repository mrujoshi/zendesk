"""Passwords and session tokens. Standard library only."""
import hashlib
import hmac
import secrets

PBKDF2_ITERATIONS = 200_000
SESSION_HOURS = 8


def hash_password(password: str) -> str:
    """Salted PBKDF2. Stored as 'pbkdf2$<iterations>$<salt>$<hash>'."""
    salt = secrets.token_hex(16)
    digest = hashlib.pbkdf2_hmac("sha256", password.encode(), bytes.fromhex(salt), PBKDF2_ITERATIONS)
    return f"pbkdf2${PBKDF2_ITERATIONS}${salt}${digest.hex()}"


def verify_password(password: str, stored: str) -> bool:
    if not stored:
        return False  # never allow login to an account with no password
    if stored.startswith("pbkdf2$"):
        _, iters, salt, expected = stored.split("$")
        digest = hashlib.pbkdf2_hmac("sha256", password.encode(), bytes.fromhex(salt), int(iters))
        return hmac.compare_digest(digest.hex(), expected)
    # Legacy: plain SHA-256 hex, as written by the current seed.py
    return hmac.compare_digest(hashlib.sha256(password.encode()).hexdigest(), stored)


def new_token() -> str:
    """Raw token sent to the browser once. Only its hash is stored."""
    return secrets.token_urlsafe(32)


def hash_token(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()
