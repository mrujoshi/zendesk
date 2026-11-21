"""Tickets: create, list/filter, detail, status, assign (round-robin + manual), messages, audit."""
from fastapi import APIRouter, Depends, Query

import models
import rules
from deps import SYSTEM, Actor, current_actor, require_staff
from rules import RuleError
from constants import Priority, Status, Visibility
from schemas import AssignRequest, MessageCreate, StatusUpdate, TicketCreate

router = APIRouter(tags=["tickets"])


def get_or_404(ticket_id: int, actor: Actor) -> dict:
    t = models.get_ticket(ticket_id)
    # A client asking for someone else's ticket gets 404, not 403 (don't reveal it exists)
    if not t or (actor.type == "client" and t["client_id"] != actor.id):
        raise RuleError(404, "not_found", "Ticket not found")
    return t


def assign_round_robin(ticket_id: int) -> int | None:
    """Call inside a transaction. Returns the chosen agent id, or None if no agents."""
    agent_id = rules.next_agent(models.active_agent_ids(), models.get_last_assigned())
    if agent_id is not None:
        models.assign(ticket_id, agent_id, assigned_by=None, reason="round_robin")
        models.set_last_assigned(agent_id)
        models.audit(ticket_id, SYSTEM.type, SYSTEM.id, "assigned", None, str(agent_id))
    return agent_id


@router.post("/tickets", status_code=201, summary="Create ticket (client) + auto-assign round-robin")
def create_ticket(body: TicketCreate, actor: Actor = Depends(current_actor)):
    if actor.type != "client":
        raise RuleError(403, "forbidden", "Only clients create tickets")
    p = body.priority.value
    with models.transaction():
        t = models.create_ticket(actor.id, body.title, body.description, p, rules.due_at(p))
        models.audit(t["id"], actor.type, actor.id, "created", None, "open")
        assign_round_robin(t["id"])
    return models.get_ticket(t["id"])


@router.get("/tickets", summary="List tickets with filters + pagination")
def list_tickets(
    status: Status | None = None,
    priority: Priority | None = None,
    escalated: bool | None = None,
    agent_id: int | None = None,
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    actor: Actor = Depends(current_actor),
):
    return models.list_tickets(
        status=status.value if status else None,
        priority=priority.value if priority else None,
        escalated=escalated,
        agent_id=agent_id,
        client_id=actor.id if actor.type == "client" else None,  # clients see only their own
        limit=limit,
        offset=offset,
    )


@router.get("/tickets/{ticket_id}", summary="Ticket detail with message thread")
def ticket_detail(ticket_id: int, actor: Actor = Depends(current_actor)):
    t = get_or_404(ticket_id, actor)
    t["messages"] = models.get_messages(ticket_id, include_internal=actor.type != "client")
    return t


@router.patch("/tickets/{ticket_id}/status", summary="Change status (validated transitions)")
def change_status(ticket_id: int, body: StatusUpdate, actor: Actor = Depends(current_actor)):
    require_staff(actor)
    t = get_or_404(ticket_id, actor)
    new = body.status.value
    rules.check_transition(t["status"], new)
    with models.transaction():
        models.update_status(ticket_id, new)
        models.audit(ticket_id, actor.type, actor.id, "status", t["status"], new)
    return models.get_ticket(ticket_id)


@router.post("/tickets/{ticket_id}/assign", summary="Manual reassign (pointer not moved)")
def reassign(ticket_id: int, body: AssignRequest, actor: Actor = Depends(current_actor)):
    require_staff(actor)
    t = get_or_404(ticket_id, actor)
    if t["status"] == Status.CLOSED:
        raise RuleError(400, "ticket_closed", "Cannot reassign a closed ticket")
    if body.agent_id not in models.active_agent_ids():
        raise RuleError(400, "invalid_agent", "Agent not found or inactive")
    if t["agent_id"] == body.agent_id:
        return t
    with models.transaction():
        models.assign(ticket_id, body.agent_id, assigned_by=actor.id, reason="manual_reassign")
        models.audit(ticket_id, actor.type, actor.id, "assigned",
                     str(t["agent_id"]) if t["agent_id"] else None, str(body.agent_id))
    return models.get_ticket(ticket_id)


@router.post("/tickets/{ticket_id}/messages", status_code=201, summary="Add message (auto status)")
def add_message(ticket_id: int, body: MessageCreate, actor: Actor = Depends(current_actor)):
    t = get_or_404(ticket_id, actor)
    internal = body.visibility == Visibility.INTERNAL
    if internal:
        require_staff(actor)
    author_type = "client" if actor.type == "client" else "agent"
    # Checked even for internal notes: nobody writes on a closed ticket
    new_status = rules.status_after_reply(t["status"], author_type)
    with models.transaction():
        msg = models.add_message(ticket_id, author_type, actor.id, body.text, body.visibility.value)
        if not internal and new_status != t["status"]:
            models.update_status(ticket_id, new_status)
            models.audit(ticket_id, actor.type, actor.id, "status", t["status"], new_status)
    return msg


@router.get("/tickets/{ticket_id}/messages", summary="Message thread, oldest first")
def list_messages(ticket_id: int, actor: Actor = Depends(current_actor)):
    get_or_404(ticket_id, actor)
    return models.get_messages(ticket_id, include_internal=actor.type != "client")


@router.get("/tickets/{ticket_id}/audit", summary="Audit trail (staff only)")
def audit_trail(ticket_id: int, actor: Actor = Depends(current_actor)):
    require_staff(actor)
    get_or_404(ticket_id, actor)
    return models.get_audit(ticket_id)


def escalate_overdue() -> list[int]:
    """Escalation job: raise priority, flag, move to an admin, audit. Returns escalated ids."""
    done = []
    for t in models.overdue_tickets(rules.now()):
        new_p = rules.escalated_priority(t["priority"])
        admin = models.admin_id()
        with models.transaction():
            models.escalate(t["id"], new_p)
            models.audit(t["id"], SYSTEM.type, SYSTEM.id, "escalated", t["priority"], new_p)
            if admin is not None and admin != t["agent_id"]:
                models.assign(t["id"], admin, assigned_by=None, reason="escalation")
                models.audit(t["id"], SYSTEM.type, SYSTEM.id, "assigned",
                             str(t["agent_id"]) if t["agent_id"] else None, str(admin))
        done.append(t["id"])
    return done
