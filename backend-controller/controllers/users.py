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
from schemas import AgentCreate, ClientCreate, UserCreate
from security import hash_password

router = APIRouter(tags=["users"])


@router.post("/clients", status_code=201, summary="Create a client company (admin only)")
def create_client(body: ClientCreate, actor: Actor = Depends(current_actor)):
    require_admin(actor)
    if models.email_exists("client", body.email):
        raise RuleError(409, "duplicate_email", "A client with this email already exists")
    return models.create_client(body.name.strip(), body.email)


@router.get("/clients", summary="List clients with user and ticket counts (staff)")
def list_clients(actor: Actor = Depends(current_actor)):
    require_staff(actor)
    return models.list_clients()


@router.post("/users", status_code=201, summary="Create a user for a client (admin only)")
def create_user(body: UserCreate, actor: Actor = Depends(current_actor)):
    require_admin(actor)
    if not models.get_client(body.client_id):
        raise RuleError(400, "invalid_client", "Client not found")
    if models.email_exists("user", body.email):
        raise RuleError(409, "duplicate_email", "A user with this email already exists")
    return models.create_user(body.client_id, body.name.strip(), body.email, body.category.strip(),
                              hash_password(body.password))


@router.get("/users", summary="List users with their client (staff; filter with ?client_id=)")
def list_users(client_id: int | None = None, actor: Actor = Depends(current_actor)):
    require_staff(actor)
    return models.list_users(client_id)


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
