"""Who is calling: reads 'Authorization: Bearer <token>' and loads the user from the session."""
from dataclasses import dataclass

from fastapi import Header

import models
from rules import RuleError, now
from security import hash_token


@dataclass
class Actor:
    type: str  # client / agent / admin / system
    id: int | None


# System actions (round-robin, escalation). audit.actor_id is NOT NULL, so the system uses id 0.
SYSTEM = Actor("system", 0)


def bearer_token(authorization: str | None = Header(None)) -> str:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise RuleError(401, "unauthorized", "Login required (Authorization: Bearer <token>)")
    return authorization.split(" ", 1)[1].strip()


def current_actor(authorization: str | None = Header(None)) -> Actor:
    token = bearer_token(authorization)
    session = models.get_session(hash_token(token), now())
    if not session:
        raise RuleError(401, "unauthorized", "Session expired or invalid; please log in again")

    if session["user_type"] == "client":
        if not models.get_client(session["user_id"]):
            raise RuleError(401, "unauthorized", "User no longer exists")
        return Actor("client", session["user_id"])

    agent = models.get_agent(session["user_id"])
    if not agent or not agent["is_active"]:  # disabled agents are locked out immediately
        raise RuleError(401, "unauthorized", "Agent account is disabled")
    return Actor(agent["role"], agent["id"])  # 'agent' or 'admin'


def require_staff(actor: Actor) -> None:
    if actor.type not in ("agent", "admin"):
        raise RuleError(403, "forbidden", "Agents only")


def require_admin(actor: Actor) -> None:
    if actor.type != "admin":
        raise RuleError(403, "forbidden", "Admins only")
