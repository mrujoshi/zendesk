"""Requirement 1: create user (clients and agents)."""
from fastapi import APIRouter, Depends

import models
from deps import Actor, current_actor, require_admin, require_staff
from rules import RuleError
from schemas import AgentCreate, ClientCreate
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


@router.get("/clients", summary="List clients")
def list_clients(actor: Actor = Depends(current_actor)):
    require_staff(actor)
    return models.list_clients()
