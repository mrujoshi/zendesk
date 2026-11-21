"""Audit trail, queryable across tickets (the brief: "an append-only history of every change
to a ticket (who, what, when), queryable via the API"). Read-only: there is no endpoint that
edits or deletes audit rows, and the database itself rejects UPDATE/DELETE (triggers in schema.sql)."""
from datetime import datetime

from fastapi import APIRouter, Depends, Query

import models
from constants import AuditAction
from controllers.tickets import scope_client_ids
from deps import Actor, current_actor, require_staff

router = APIRouter(tags=["audit"])


@router.get("/audit", summary="Query the audit trail (staff; agents only see their linked clients)")
def query_audit(
    ticket_id: int | None = None,
    actor_type: str | None = Query(None, pattern="^(user|client|agent|admin|system)$"),
    actor_id: int | None = None,
    action: AuditAction | None = None,
    since: datetime | None = Query(None, description="ISO time, inclusive (e.g. 2026-11-21T00:00:00Z)"),
    until: datetime | None = Query(None, description="ISO time, exclusive"),
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    actor: Actor = Depends(current_actor),
):
    require_staff(actor)
    iso = lambda d: d.isoformat(timespec="seconds") if d else None  # noqa: E731
    return models.query_audit(
        client_ids=scope_client_ids(actor),  # admin: all; agent: linked clients only
        ticket_id=ticket_id, actor_type=actor_type, actor_id=actor_id,
        action=action.value if action else None,
        since=iso(since), until=iso(until), limit=limit, offset=offset,
    )
