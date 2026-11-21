"""Tickets: create, list/filter, detail, status, assign (round-robin + manual), messages, audit."""
from fastapi import APIRouter, Depends, Query

import models
import rules
from deps import SYSTEM, Actor, current_actor, require_staff
from rules import RuleError
from constants import Priority, Status, Visibility
from schemas import AssignRequest, MessageCreate, PriorityUpdate, StatusUpdate, TicketCreate

router = APIRouter(tags=["tickets"])


def scope_client_ids(actor: Actor) -> list[int] | None:
    """Which clients' tickets this actor may see. None = no limit (admin)."""
    if actor.type == "client":
        return [actor.id]
    if actor.type == "agent":
        return models.linked_client_ids(actor.id)  # configured by the admin (agent_clients)
    return None


def get_or_404(ticket_id: int, actor: Actor) -> dict:
    t = models.get_ticket(ticket_id)
    scope = scope_client_ids(actor)
    # Outside your scope = 404, not 403: don't reveal that the ticket exists
    if not t or (scope is not None and t["client_id"] not in scope):
        raise RuleError(404, "not_found", "Ticket not found")
    return t


def assign_round_robin(ticket_id: int, client_id: int) -> int | None:
    """Call inside a transaction. Picks the next active agent LINKED to this client.
    Nobody linked -> None: the ticket stays unassigned for the admin (option A)."""
    agent_id = rules.next_agent(models.active_agent_ids(client_id), models.get_last_assigned())
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
        assign_round_robin(t["id"], actor.id)
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
        client_id=None,
        limit=limit,
        offset=offset,
        client_ids=scope_client_ids(actor),  # client: own; agent: linked clients; admin: all
    )


@router.get("/tickets/{ticket_id}", summary="Ticket detail with message thread")
def ticket_detail(ticket_id: int, actor: Actor = Depends(current_actor)):
    t = get_or_404(ticket_id, actor)
    t["messages"] = models.get_messages(ticket_id, include_internal=actor.type != "client")
    return t


@router.patch("/tickets/{ticket_id}/status", summary="Change status (validated transitions)")
def change_status(ticket_id: int, body: StatusUpdate, actor: Actor = Depends(current_actor)):
    require_staff(actor)
    new = body.status.value
    # Read + check + write inside ONE locked transaction. If two agents act at the same moment,
    # the second waits, then sees the updated ticket and gets a clear 400 (no lost update).
    with models.transaction():
        t = get_or_404(ticket_id, actor)
        rules.check_transition(t["status"], new)
        models.update_status(ticket_id, new)
        models.audit(ticket_id, actor.type, actor.id, "status", t["status"], new)
    return models.get_ticket(ticket_id)


@router.patch("/tickets/{ticket_id}/priority", summary="Change priority (staff); SLA deadline recalculated")
def change_priority(ticket_id: int, body: PriorityUpdate, actor: Actor = Depends(current_actor)):
    require_staff(actor)
    new = body.priority.value
    with models.transaction():  # read + check + write under one lock (see change_status)
        t = get_or_404(ticket_id, actor)
        if t["status"] not in (Status.OPEN, Status.PENDING):
            raise RuleError(400, "ticket_not_active", f"Cannot change priority of a {t['status']} ticket")
        if t["priority"] == new:
            raise RuleError(400, "no_change", f"Priority is already {new}")
        # New deadline counts from when the ticket was created, not from now. Raising priority on
        # an old ticket can make it overdue at once; the escalation job then handles it.
        models.update_priority(ticket_id, new, rules.due_at(new, t["created_at"]))
        models.audit(ticket_id, actor.type, actor.id, "priority", t["priority"], new)
    return models.get_ticket(ticket_id)


@router.post("/tickets/{ticket_id}/assign", summary="Manual reassign (pointer not moved)")
def reassign(ticket_id: int, body: AssignRequest, actor: Actor = Depends(current_actor)):
    require_staff(actor)
    with models.transaction():  # read + check + write under one lock (see change_status)
        t = get_or_404(ticket_id, actor)
        if t["status"] == Status.CLOSED:
            raise RuleError(400, "ticket_closed", "Cannot reassign a closed ticket")
        if body.agent_id not in models.active_agent_ids():
            raise RuleError(400, "invalid_agent", "Agent not found or inactive")
        if body.agent_id not in models.active_agent_ids(t["client_id"]):
            raise RuleError(400, "agent_not_linked", "Agent has no access to this client")
        if t["agent_id"] == body.agent_id:
            return t
        models.assign(ticket_id, body.agent_id, assigned_by=actor.id, reason="manual_reassign")
        models.audit(ticket_id, actor.type, actor.id, "assigned",
                     str(t["agent_id"]) if t["agent_id"] else None, str(body.agent_id))
    return models.get_ticket(ticket_id)


@router.post("/tickets/{ticket_id}/messages", status_code=201, summary="Add message (auto status)")
def add_message(ticket_id: int, body: MessageCreate, actor: Actor = Depends(current_actor)):
    internal = body.visibility == Visibility.INTERNAL
    if internal:
        require_staff(actor)
    author_type = "client" if actor.type == "client" else "agent"
    with models.transaction():  # read + check + write under one lock (see change_status)
        t = get_or_404(ticket_id, actor)
        # Checked even for internal notes: nobody writes on a closed ticket
        new_status = rules.status_after_reply(t["status"], author_type)
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
    for candidate in models.overdue_tickets(rules.now()):
        with models.transaction():
            # Re-read under the lock: the background job and a manual run (or an agent solving
            # the ticket) may race; skip if it's no longer an un-escalated active ticket.
            t = models.get_ticket(candidate["id"])
            if t["is_escalated"] or t["status"] not in ("open", "pending"):
                continue
            new_p = rules.escalated_priority(t["priority"])
            admin = models.admin_id()
            models.escalate(t["id"], new_p)
            models.audit(t["id"], SYSTEM.type, SYSTEM.id, "escalated", t["priority"], new_p)
            if admin is not None and admin != t["agent_id"]:
                models.assign(t["id"], admin, assigned_by=None, reason="escalation")
                models.audit(t["id"], SYSTEM.type, SYSTEM.id, "assigned",
                             str(t["agent_id"]) if t["agent_id"] else None, str(admin))
        done.append(t["id"])
    return done
