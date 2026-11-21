"""Passwords and session tokens. Standard library only."""
import hashlib
import hmac
import os
import secrets
import threading
import time

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


# ---------- Brute-force protection for login ----------
LOGIN_MAX_ATTEMPTS = int(os.getenv("LOGIN_MAX_ATTEMPTS", "5"))
LOGIN_LOCK_SECONDS = int(os.getenv("LOGIN_LOCK_SECONDS", str(15 * 60)))


class LoginThrottle:
    """After LOGIN_MAX_ATTEMPTS wrong passwords for one account within LOGIN_LOCK_SECONDS, that
    account is locked until the window passes (even the right password is refused meanwhile).
    Keyed by (user_type, email), and unknown emails count too, so the lock reveals nothing about
    which emails exist. In memory: fine for one server process; a shared store (DB/Redis) would
    be needed with several servers."""

    def __init__(self):
        self._fails: dict[tuple[str, str], list[float]] = {}
        self._lock = threading.Lock()

    def _recent(self, key, now):
        recent = [t for t in self._fails.get(key, []) if now - t < LOGIN_LOCK_SECONDS]
        if recent:
            self._fails[key] = recent
        else:
            self._fails.pop(key, None)
        return recent

    def seconds_locked(self, user_type: str, email: str) -> int:
        """0 if login may be attempted, else seconds until the lock ends."""
        key, now = (user_type, email.lower()), time.monotonic()
        with self._lock:
            recent = self._recent(key, now)
            if len(recent) < LOGIN_MAX_ATTEMPTS:
                return 0
            return max(1, int(LOGIN_LOCK_SECONDS - (now - recent[0])))

    def failed(self, user_type: str, email: str) -> None:
        key, now = (user_type, email.lower()), time.monotonic()
        with self._lock:
            self._recent(key, now)
            self._fails.setdefault(key, []).append(now)

    def succeeded(self, user_type: str, email: str) -> None:
        with self._lock:
            self._fails.pop((user_type, email.lower()), None)


login_throttle = LoginThrottle()
