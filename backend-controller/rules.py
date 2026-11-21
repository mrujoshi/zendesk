"""Business rules. Pure Python: no database, no FastAPI. Easy to test and explain."""
import os
from datetime import datetime, timedelta, timezone

from constants import ALLOWED_TRANSITIONS, NEXT_PRIORITY, SLA, Priority, Status


class RuleError(Exception):
    """Raised by controllers/rules; main.py turns it into {"error", "message"} JSON."""

    def __init__(self, status: int, code: str, message: str):
        self.status, self.code, self.message = status, code, message


# Set SLA_UNIT=minutes for the live demo so escalation happens quickly.
SLA_UNIT = os.getenv("SLA_UNIT", "hours")


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def _status(value: str) -> Status:
    """Guard: a status stored in the DB that isn't in our lifecycle (e.g. 'escalated' from old seed
    data) returns a clear 400 instead of crashing with a 500. Escalation is the is_escalated flag."""
    try:
        return Status(value)
    except ValueError:
        raise RuleError(400, "unknown_status",
                        f"Ticket has unsupported status '{value}'; expected open, pending, solved or closed")


def check_transition(old: str, new: str) -> None:
    old_s, new_s = _status(old), _status(new)
    if old_s == new_s:
        raise RuleError(400, "no_change", f"Ticket is already {old}")
    if new_s not in ALLOWED_TRANSITIONS[old_s]:
        raise RuleError(400, "invalid_transition", f"Cannot move from {old} to {new}")


def status_after_reply(current: str, author_type: str) -> str:
    """Agent reply -> pending (waiting on client). Client reply -> open (agent's turn)."""
    if _status(current) == Status.CLOSED:
        raise RuleError(400, "ticket_closed", "Ticket is closed; please open a new one")
    return (Status.PENDING if author_type == "agent" else Status.OPEN).value


def due_at(priority: str, created_at: str | None = None) -> str:
    """SLA deadline = creation time + SLA for the priority. Used at creation (now) and when
    priority changes (from the ticket's original created_at, like Zendesk SLA policies)."""
    start = datetime.fromisoformat(created_at) if created_at else datetime.now(timezone.utc)
    if start.tzinfo is None:
        start = start.replace(tzinfo=timezone.utc)
    delta = timedelta(**{SLA_UNIT: SLA[Priority(priority)]})
    return (start + delta).isoformat(timespec="seconds")


def escalated_priority(priority: str) -> str:
    return NEXT_PRIORITY[Priority(priority)].value


def next_agent(agent_ids: list[int], last_id: int | None) -> int | None:
    """Round-robin: next agent id after last_id, wrapping around. None if no agents."""
    if not agent_ids:
        return None
    ids = sorted(agent_ids)
    for a in ids:
        if last_id is None or a > last_id:
            return a
    return ids[0]
