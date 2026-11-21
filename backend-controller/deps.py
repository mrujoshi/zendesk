"""Who is calling. Demo identity via headers: X-Actor-Type (client/agent/admin) + X-Actor-Id."""
from dataclasses import dataclass

from fastapi import Header

import models
from rules import RuleError


@dataclass
class Actor:
    type: str  # client / agent / admin / system
    id: int | None


SYSTEM = Actor("system", None)


def current_actor(
    x_actor_type: str = Header(..., description="client / agent / admin"),
    x_actor_id: int = Header(...),
) -> Actor:
    if x_actor_type == "client":
        if not models.get_client(x_actor_id):
            raise RuleError(401, "unauthorized", "Unknown client")
    elif x_actor_type in ("agent", "admin"):
        agent = models.get_agent(x_actor_id)
        if not agent or not agent["is_active"]:
            raise RuleError(401, "unauthorized", "Unknown or inactive agent")
        if x_actor_type == "admin" and agent["role"] != "admin":
            raise RuleError(403, "forbidden", "Not an admin")
    else:
        raise RuleError(401, "unauthorized", "X-Actor-Type must be client, agent or admin")
    return Actor(x_actor_type, x_actor_id)


def require_staff(actor: Actor) -> None:
    if actor.type not in ("agent", "admin"):
        raise RuleError(403, "forbidden", "Agents only")


def require_admin(actor: Actor) -> None:
    if actor.type != "admin":
        raise RuleError(403, "forbidden", "Admins only")
