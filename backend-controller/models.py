"""
TEMPORARY IN-MEMORY STUB of the Model layer, so the Controller can be built and tested alone.

>>> At merge time Mrudula's SQLite models.py replaces this file. <<<
It must keep the SAME function names, arguments and return shapes (see CONTRACT.md).
Data here is lost on restart; the real one persists to SQLite.
"""
from contextlib import contextmanager
from itertools import count

from rules import now

_clients, _agents, _tickets, _messages, _worksheet, _audit = {}, {}, {}, [], [], []
_settings: dict = {}
_ids = {k: count(1) for k in ("client", "agent", "ticket", "message", "worksheet", "audit")}


def init():
    """Real version: create tables if missing. Stub: seed demo users once."""
    if not _agents:
        create_agent("Admin Asha", "asha@demo.com", "admin")
        create_agent("Priya", "priya@demo.com", "agent")
        create_agent("Rahul", "rahul@demo.com", "agent")
        create_client("Ravi Customer", "ravi@demo.com")


@contextmanager
def transaction():
    """Real version: BEGIN ... COMMIT, ROLLBACK on exception."""
    yield


# ---- users ----
def create_client(name, email):
    c = {"id": next(_ids["client"]), "name": name, "email": email, "created_at": now()}
    _clients[c["id"]] = c
    return dict(c)


def create_agent(name, email, role):
    a = {"id": next(_ids["agent"]), "name": name, "email": email, "role": role,
         "is_active": True, "created_at": now()}
    _agents[a["id"]] = a
    return dict(a)


def get_client(client_id):
    c = _clients.get(client_id)
    return dict(c) if c else None


def get_agent(agent_id):
    a = _agents.get(agent_id)
    return dict(a) if a else None


def email_exists(kind, email):
    table = _clients if kind == "client" else _agents
    return any(u["email"].lower() == email.lower() for u in table.values())


def list_agents():
    return [dict(a) for a in _agents.values()]


def list_clients():
    return [dict(c) for c in _clients.values()]


def active_agent_ids():
    """Agents eligible for round-robin (role 'agent', active)."""
    return [a["id"] for a in _agents.values() if a["is_active"] and a["role"] == "agent"]


def admin_id():
    return next((a["id"] for a in _agents.values() if a["is_active"] and a["role"] == "admin"), None)


# ---- round-robin pointer (settings table) ----
def get_last_assigned():
    return _settings.get("last_assigned_agent_id")


def set_last_assigned(agent_id):
    _settings["last_assigned_agent_id"] = agent_id


# ---- tickets ----
def _current_agent(ticket_id):
    rows = [w for w in _worksheet if w["ticket_id"] == ticket_id]
    return rows[-1]["agent_id"] if rows else None


def _out(t):
    out = dict(t)
    out["agent_id"] = _current_agent(t["id"])
    return out


def create_ticket(client_id, title, description, priority, due_at):
    ts = now()
    t = {"id": next(_ids["ticket"]), "client_id": client_id, "title": title,
         "description": description, "status": "open", "priority": priority,
         "is_escalated": False, "attachment_path": None, "created_at": ts,
         "updated_at": ts, "solved_at": None, "due_at": due_at}
    _tickets[t["id"]] = t
    return _out(t)


def get_ticket(ticket_id):
    t = _tickets.get(ticket_id)
    return _out(t) if t else None


def list_tickets(status, priority, escalated, agent_id, client_id, limit, offset):
    rows = [_out(t) for t in _tickets.values()]
    if status:
        rows = [t for t in rows if t["status"] == status]
    if priority:
        rows = [t for t in rows if t["priority"] == priority]
    if escalated is not None:
        rows = [t for t in rows if t["is_escalated"] == escalated]
    if agent_id:
        rows = [t for t in rows if t["agent_id"] == agent_id]
    if client_id:
        rows = [t for t in rows if t["client_id"] == client_id]
    rows.sort(key=lambda t: t["id"], reverse=True)  # newest first
    return {"items": rows[offset:offset + limit], "total": len(rows), "limit": limit, "offset": offset}


def update_status(ticket_id, status):
    t = _tickets[ticket_id]
    t["status"], t["updated_at"] = status, now()
    t["solved_at"] = now() if status == "solved" else (t["solved_at"] if status == "closed" else None)


def assign(ticket_id, agent_id, assigned_by, reason):
    _worksheet.append({"id": next(_ids["worksheet"]), "ticket_id": ticket_id, "agent_id": agent_id,
                       "assigned_by": assigned_by, "reason": reason, "created_at": now()})
    _tickets[ticket_id]["updated_at"] = now()


def overdue_tickets(now_iso):
    return [_out(t) for t in _tickets.values()
            if t["due_at"] < now_iso and t["status"] in ("open", "pending") and not t["is_escalated"]]


def escalate(ticket_id, new_priority):
    t = _tickets[ticket_id]
    t["priority"], t["is_escalated"], t["updated_at"] = new_priority, True, now()


# ---- messages ----
def add_message(ticket_id, author_type, author_id, text, visibility):
    m = {"id": next(_ids["message"]), "ticket_id": ticket_id, "author_type": author_type,
         "author_id": author_id, "text": text, "visibility": visibility, "created_at": now()}
    _messages.append(m)
    _tickets[ticket_id]["updated_at"] = now()
    return dict(m)


def get_messages(ticket_id, include_internal):
    return [dict(m) for m in _messages if m["ticket_id"] == ticket_id
            and (include_internal or m["visibility"] == "public")]


# ---- audit (append-only) ----
def audit(ticket_id, actor_type, actor_id, action, old_value, new_value):
    _audit.append({"id": next(_ids["audit"]), "ticket_id": ticket_id, "actor_type": actor_type,
                   "actor_id": actor_id, "action": action, "old_value": old_value,
                   "new_value": new_value, "created_at": now()})


def get_audit(ticket_id):
    return [dict(a) for a in _audit if a["ticket_id"] == ticket_id]


# ---- report ----
def daily_report(day):
    ts = list(_tickets.values())
    per_agent = {}
    for t in ts:
        a = _current_agent(t["id"])
        if a and t["status"] in ("open", "pending"):
            per_agent[a] = per_agent.get(a, 0) + 1
    return {
        "date": day,
        "created": sum(t["created_at"][:10] == day for t in ts),
        "solved": sum((t["solved_at"] or "")[:10] == day for t in ts),
        "open": sum(t["status"] in ("open", "pending") for t in ts),
        "escalated": sum(t["is_escalated"] for t in ts),
        "open_per_agent": [{"agent_id": k, "name": _agents[k]["name"], "open": v}
                           for k, v in per_agent.items()],
    }
