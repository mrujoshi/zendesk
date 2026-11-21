"""Requirement 1: create users.

- Client = a company. Admins create clients; clients don't log in.
- User   = a person who belongs to one client and logs in. Admins create users for a client.
           There is no open sign-up: otherwise anyone could join any client and read its tickets.
- Agent  = support staff (role 'agent' or 'admin').
"""
from fastapi import APIRouter, Depends

import models
from deps import Actor, current_actor, require_admin, require_staff
from rules import RuleError
from schemas import AgentClientsUpdate, AgentCreate, ClientCreate, UserCreate
from security import hash_password

router = APIRouter(tags=["users"])


@router.post("/clients", status_code=201, summary="Create a client company (admin only)")
def create_client(body: ClientCreate, actor: Actor = Depends(current_actor)):
    require_admin(actor)
    if models.email_exists("client", body.email):
        raise RuleError(409, "duplicate_email", "A client with this email already exists")
    return models.create_client(body.name.strip(), body.email)


@router.post("/users", status_code=201, summary="Create a user for a client (admin only)")
def create_user(body: UserCreate, actor: Actor = Depends(current_actor)):
    require_admin(actor)
    if not models.get_client(body.client_id):
        raise RuleError(400, "invalid_client", "Client not found")
    if models.email_exists("user", body.email):
        raise RuleError(409, "duplicate_email", "A user with this email already exists")
    return models.create_user(body.client_id, body.name.strip(), body.email, body.category.strip(),
                              hash_password(body.password))


@router.get("/users", summary="List users with their client (staff; agents: only their linked clients)")
def list_users(client_id: int | None = None, actor: Actor = Depends(current_actor)):
    require_staff(actor)
    users = models.list_users(client_id)
    if actor.type == "agent":
        allowed = set(models.linked_client_ids(actor.id))
        users = [u for u in users if u["client_id"] in allowed]
    return users


@router.post("/agents", status_code=201, summary="Create an agent (admin only)")
def create_agent(body: AgentCreate, actor: Actor = Depends(current_actor)):
    require_admin(actor)
    if models.email_exists("agent", body.email):
        raise RuleError(409, "duplicate_email", "An agent with this email already exists")
    return models.create_agent(body.name, body.email, body.role.value, hash_password(body.password))


@router.get("/agents", summary="List agents (for dropdowns)")
def list_agents(actor: Actor = Depends(current_actor)):
    require_staff(actor)
    return models.list_agents()


@router.get("/clients", summary="List clients with user/ticket counts (agents: only clients linked to them)")
def list_clients(actor: Actor = Depends(current_actor)):
    require_staff(actor)
    if actor.type == "agent":
        return models.list_clients(models.linked_client_ids(actor.id))
    return models.list_clients()


# ---------- Agent <-> client access (configured by the admin) ----------
def _agent_or_400(agent_id: int) -> dict:
    agent = models.get_agent(agent_id)
    if not agent:
        raise RuleError(404, "not_found", "Agent not found")
    if agent["role"] != "agent":
        raise RuleError(400, "not_an_agent", "Admins see all clients; access is set for agents only")
    return agent


@router.get("/agents/{agent_id}/clients", summary="Clients this agent can access (admin, or the agent)")
def get_agent_clients(agent_id: int, actor: Actor = Depends(current_actor)):
    if not (actor.type == "admin" or (actor.type == "agent" and actor.id == agent_id)):
        raise RuleError(403, "forbidden", "Admins only")
    _agent_or_400(agent_id)
    return {"agent_id": agent_id, "client_ids": models.linked_client_ids(agent_id)}


@router.put("/agents/{agent_id}/clients", summary="Set the full list of clients an agent can access (admin)")
def set_agent_clients(agent_id: int, body: AgentClientsUpdate, actor: Actor = Depends(current_actor)):
    require_admin(actor)
    _agent_or_400(agent_id)
    wanted = sorted(set(body.client_ids))
    missing = sorted(set(wanted) - set(models.existing_client_ids(wanted)))
    if missing:
        raise RuleError(400, "unknown_client", f"Unknown client id(s): {missing}")
    with models.transaction():
        models.set_agent_clients(agent_id, wanted)
    # Takes effect on the agent's next request: access is checked on every call, not stored in the token
    return {"agent_id": agent_id, "client_ids": models.linked_client_ids(agent_id)}


@router.get("/clients/{client_id}/agents", summary="Agents linked to a client (for the reassign dropdown)")
def get_client_agents(client_id: int, actor: Actor = Depends(current_actor)):
    require_staff(actor)
    if actor.type == "agent" and client_id not in models.linked_client_ids(actor.id):
        raise RuleError(404, "not_found", "Client not found")
    if not models.get_client(client_id):
        raise RuleError(404, "not_found", "Client not found")
    return models.linked_agents(client_id)
