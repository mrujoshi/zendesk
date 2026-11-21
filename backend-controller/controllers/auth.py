"""Login / logout / who am I. Token goes in 'Authorization: Bearer <token>'."""
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends

import models
from deps import Actor, bearer_token, current_actor
from rules import RuleError
from schemas import LoginRequest
from security import SESSION_HOURS, hash_token, new_token, verify_password

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/login", summary="Log in as client or agent; returns a bearer token")
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
    role = user.get("role", "client")
    return {
        "token": token,
        "expires_at": expires,
        "user": {"id": user["id"], "name": user["name"], "email": user["email"], "role": role},
    }


@router.post("/logout", summary="Revoke the current token")
def logout(token: str = Depends(bearer_token)):
    models.revoke_session(hash_token(token))
    return {"ok": True}


@router.get("/me", summary="Who is logged in")
def me(actor: Actor = Depends(current_actor)):
    user = models.get_client(actor.id) if actor.type == "client" else models.get_agent(actor.id)
    return {"id": user["id"], "name": user["name"], "email": user["email"], "role": actor.type}
