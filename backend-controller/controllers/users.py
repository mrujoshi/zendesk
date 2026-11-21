"""Requirement 1: create user (clients and agents)."""
from fastapi import APIRouter, Depends

import models
from deps import Actor, current_actor, require_admin, require_staff
from rules import RuleError
from schemas import AgentClientsUpdate, AgentCreate, ClientCreate
from security import hash_password

router = APIRouter(tags=["users"])


@router.post("/clients", status_code=201, summary="Register a client (open, like a signup)")
def create_client(body: ClientCreate):
    if models.email_exists("client", body.email):
        raise RuleError(409, "duplicate_email", "A client with this email already exists")
    return models.create_client(body.name, body.email, hash_password(body.password))


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


@router.get("/clients", summary="List clients (agents: only clients linked to them)")
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
