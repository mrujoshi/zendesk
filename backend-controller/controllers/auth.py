"""Login / logout / who am I. Token goes in 'Authorization: Bearer <token>'."""
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends

import models
from deps import Actor, bearer_token, current_actor
from rules import RuleError
from schemas import LoginRequest
from security import SESSION_HOURS, hash_token, new_token, verify_password

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/login", summary="Log in as a user (of a client) or an agent; returns a bearer token")
def login(body: LoginRequest):
    user = models.find_for_login(body.user_type.value, body.email)
    # Same message for "no such email" and "wrong password": don't reveal which emails exist
    if not user or not verify_password(body.password, user["password_hash"]):
        raise RuleError(401, "invalid_credentials", "Email or password is wrong")
    if body.user_type.value == "agent" and not user["is_active"]:
        raise RuleError(403, "inactive", "This agent account is disabled")

    token = new_token()
    expires = (datetime.now(timezone.utc) + timedelta(hours=SESSION_HOURS)).isoformat(timespec="seconds")
    models.create_session(hash_token(token), body.user_type.value, user["id"], expires)
    return {"token": token, "expires_at": expires, "user": _profile(body.user_type.value, user["id"])}


@router.post("/logout", summary="Revoke the current token")
def logout(token: str = Depends(bearer_token)):
    models.revoke_session(hash_token(token))
    return {"ok": True}


@router.get("/me", summary="Who is logged in")
def me(actor: Actor = Depends(current_actor)):
    return _profile("user" if actor.type == "user" else "agent", actor.id)


def _profile(user_type: str, user_id: int) -> dict:
    """role is 'user', 'agent' or 'admin'. Users also get their client (company)."""
    if user_type == "user":
        u = models.get_user(user_id)
        return {"id": u["id"], "name": u["name"], "email": u["email"], "role": "user",
                "category": u["category"], "client_id": u["client_id"], "client_name": u["client_name"]}
    a = models.get_agent(user_id)
    return {"id": a["id"], "name": a["name"], "email": a["email"], "role": a["role"]}
