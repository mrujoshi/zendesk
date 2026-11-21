"""
Model layer on SQLite. All SQL lives here; the controller only calls these functions.

Uses Mrudula's backend/database.py (connection with foreign keys + WAL) and backend/schema.sql.
Database file: backend/zendesk.db (override with the DB_PATH environment variable, e.g. for tests).
"""
import importlib.util
import os
import sqlite3
import threading
from contextlib import contextmanager
from pathlib import Path

from rules import now

# Load Mrudula's backend/database.py by file path (not via sys.path), so files in backend/
# can never shadow controller modules like main.py or rules.py.
BACKEND_DIR = Path(__file__).resolve().parent.parent / "backend"
_spec = importlib.util.spec_from_file_location("zendesk_database", BACKEND_DIR / "database.py")
database = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(database)

DB_PATH = Path(os.getenv("DB_PATH", database.DEFAULT_DB_PATH))

# FastAPI runs sync routes in a thread pool and sqlite3 connections can't be shared
# across threads, so each thread gets its own connection.
_local = threading.local()


def _conn() -> sqlite3.Connection:
    conn = getattr(_local, "conn", None)
    if conn is None:
        conn = database.get_db_connection(DB_PATH)
        conn.isolation_level = None  # autocommit; transaction() below issues BEGIN/COMMIT
        conn.execute("PRAGMA busy_timeout = 5000;")  # wait for a lock instead of failing at once
        _local.conn = conn
        _local.depth = 0
    return conn


def init():
    """Create tables if missing (safe to run every start). Seed data: python3 backend/seed.py"""
    database.init_db(DB_PATH)


@contextmanager
def transaction():
    """All writes inside commit together or not at all. Nested calls join the outer transaction.
    BEGIN IMMEDIATE takes the write lock up front, so two requests can't both read the same
    round-robin pointer and assign the same agent."""
    conn = _conn()
    if _local.depth == 0:
        conn.execute("BEGIN IMMEDIATE")
    _local.depth += 1
    try:
        yield
    except BaseException:
        _local.depth -= 1
        if _local.depth == 0:
            conn.execute("ROLLBACK")
        raise
    _local.depth -= 1
    if _local.depth == 0:
        conn.execute("COMMIT")


# ---------- helpers ----------
def _ts(v):
    """SQLite's CURRENT_TIMESTAMP gives '2026-11-21 10:30:00' (UTC, no zone). Return ISO UTC."""
    if isinstance(v, str) and len(v) == 19 and v[10] == " ":
        return v.replace(" ", "T") + "+00:00"
    return v


def _row(r, drop=("password_hash",)):
    if r is None:
        return None
    d = {k: r[k] for k in r.keys() if k not in drop}
    for k in d:
        if k.endswith("_at"):
            d[k] = _ts(d[k])
    return d


def _one(sql, args=()):
    return _conn().execute(sql, args).fetchone()


def _all(sql, args=()):
    return _conn().execute(sql, args).fetchall()


def _exec(sql, args=()):
    return _conn().execute(sql, args)


def _agent_out(r):
    d = _row(r)
    if d:
        d["is_active"] = bool(d["is_active"])
    return d


def _ticket_out(r):
    d = _row(r)
    if d:
        d["is_escalated"] = bool(d["is_escalated"])
    return d


def _message_out(r):
    """Schema columns are sender_type/sender_id; the API (and UI) call them author_type/author_id."""
    d = _row(r)
    if d:
        d["author_type"] = d.pop("sender_type")
        d["author_id"] = d.pop("sender_id")
    return d


# ---------- users ----------
def create_client(name, email, password_hash):
    cur = _exec("INSERT INTO clients (name, email, password_hash, created_at) VALUES (?, ?, ?, ?)",
                (name, email, password_hash, now()))
    return get_client(cur.lastrowid)


def create_agent(name, email, role, password_hash):
    cur = _exec("INSERT INTO agents (name, email, role, password_hash, is_active, created_at) "
                "VALUES (?, ?, ?, ?, 1, ?)", (name, email, role, password_hash, now()))
    return get_agent(cur.lastrowid)


def get_client(client_id):
    return _row(_one("SELECT * FROM clients WHERE id = ?", (client_id,)))


def get_agent(agent_id):
    return _agent_out(_one("SELECT * FROM agents WHERE id = ?", (agent_id,)))


def find_for_login(user_type, email):
    """The only function that returns password_hash."""
    table = "clients" if user_type == "client" else "agents"
    r = _one(f"SELECT * FROM {table} WHERE lower(email) = lower(?)", (email,))
    return _row(r, drop=()) if r else None


def email_exists(kind, email):
    table = "clients" if kind == "client" else "agents"
    return _one(f"SELECT 1 FROM {table} WHERE lower(email) = lower(?)", (email,)) is not None


def list_agents():
    return [_agent_out(r) for r in _all("SELECT * FROM agents ORDER BY id")]


def list_clients():
    return [_row(r) for r in _all("SELECT * FROM clients ORDER BY id")]


def active_agent_ids():
    """Round-robin pool: active agents with role 'agent' (admins only get escalations)."""
    return [r["id"] for r in _all("SELECT id FROM agents WHERE role = 'agent' AND is_active = 1 ORDER BY id")]


def admin_id():
    r = _one("SELECT id FROM agents WHERE role = 'admin' AND is_active = 1 ORDER BY id LIMIT 1")
    return r["id"] if r else None


# ---------- sessions ----------
def create_session(token_hash, user_type, user_id, expires_at):
    _exec("INSERT INTO sessions (token_hash, user_type, user_id, created_at, expires_at) VALUES (?, ?, ?, ?, ?)",
          (token_hash, user_type, user_id, now(), expires_at))


def get_session(token_hash, now_iso):
    return _row(_one("SELECT * FROM sessions WHERE token_hash = ? AND revoked_at IS NULL AND expires_at > ?",
                     (token_hash, now_iso)))


def revoke_session(token_hash):
    _exec("UPDATE sessions SET revoked_at = ? WHERE token_hash = ? AND revoked_at IS NULL", (now(), token_hash))


# ---------- round-robin pointer ----------
def get_last_assigned():
    r = _one("SELECT value FROM system_settings WHERE key = 'last_assigned_agent_id'")
    return int(r["value"]) if r else None


def set_last_assigned(agent_id):
    _exec("INSERT INTO system_settings (key, value) VALUES ('last_assigned_agent_id', ?) "
          "ON CONFLICT(key) DO UPDATE SET value = excluded.value", (str(agent_id),))


# ---------- tickets ----------
def create_ticket(client_id, title, description, priority, due_at):
    ts = now()
    cur = _exec("INSERT INTO tickets (title, description, status, priority, client_id, due_at, created_at, updated_at) "
                "VALUES (?, ?, 'open', ?, ?, ?, ?, ?)", (title, description, priority, client_id, due_at, ts, ts))
    return get_ticket(cur.lastrowid)


def get_ticket(ticket_id):
    return _ticket_out(_one("SELECT * FROM tickets WHERE id = ?", (ticket_id,)))


def list_tickets(status, priority, escalated, agent_id, client_id, limit, offset):
    where, args = [], []
    if status:
        where.append("status = ?"); args.append(status)
    if priority:
        where.append("priority = ?"); args.append(priority)
    if escalated is not None:
        where.append("is_escalated = ?"); args.append(1 if escalated else 0)
    if agent_id:
        where.append("agent_id = ?"); args.append(agent_id)
    if client_id:
        where.append("client_id = ?"); args.append(client_id)
    w = (" WHERE " + " AND ".join(where)) if where else ""
    total = _one(f"SELECT COUNT(*) AS n FROM tickets{w}", args)["n"]
    rows = _all(f"SELECT * FROM tickets{w} ORDER BY id DESC LIMIT ? OFFSET ?", [*args, limit, offset])
    return {"items": [_ticket_out(r) for r in rows], "total": total, "limit": limit, "offset": offset}


def update_status(ticket_id, status):
    ts = now()
    if status == "solved":
        _exec("UPDATE tickets SET status = ?, solved_at = ?, updated_at = ? WHERE id = ?", (status, ts, ts, ticket_id))
    elif status == "closed":  # keep solved_at
        _exec("UPDATE tickets SET status = ?, updated_at = ? WHERE id = ?", (status, ts, ticket_id))
    else:  # reopened: no longer solved
        _exec("UPDATE tickets SET status = ?, solved_at = NULL, updated_at = ? WHERE id = ?", (status, ts, ticket_id))


def assign(ticket_id, agent_id, assigned_by, reason):
    """Current agent lives on tickets.agent_id; every assignment is also appended to worksheet (history).
    assigned_by = agent id of the person who did it, or None for the system."""
    ts = now()
    _exec("UPDATE tickets SET agent_id = ?, updated_at = ? WHERE id = ?", (agent_id, ts, ticket_id))
    _exec("INSERT INTO worksheet (ticket_id, agent_id, assigned_by, reason, status, created_at) "
          "SELECT id, ?, ?, ?, status, ? FROM tickets WHERE id = ?", (agent_id, assigned_by, reason, ts, ticket_id))


def overdue_tickets(now_iso):
    return [_ticket_out(r) for r in _all(
        "SELECT * FROM tickets WHERE status IN ('open', 'pending') AND is_escalated = 0 "
        "AND due_at IS NOT NULL AND due_at < ? ORDER BY id", (now_iso,))]


def escalate(ticket_id, new_priority):
    _exec("UPDATE tickets SET priority = ?, is_escalated = 1, updated_at = ? WHERE id = ?",
          (new_priority, now(), ticket_id))


# ---------- messages ----------
def add_message(ticket_id, author_type, author_id, text, visibility):
    ts = now()
    cur = _exec("INSERT INTO messages (ticket_id, sender_id, sender_type, text, visibility, created_at) "
                "VALUES (?, ?, ?, ?, ?, ?)", (ticket_id, author_id, author_type, text, visibility, ts))
    _exec("UPDATE tickets SET updated_at = ? WHERE id = ?", (ts, ticket_id))
    return _message_out(_one("SELECT * FROM messages WHERE id = ?", (cur.lastrowid,)))


def get_messages(ticket_id, include_internal):
    vis = "" if include_internal else " AND visibility = 'public'"
    return [_message_out(r) for r in _all(
        f"SELECT * FROM messages WHERE ticket_id = ?{vis} ORDER BY created_at ASC, id ASC", (ticket_id,))]


# ---------- audit (append-only) ----------
def audit(ticket_id, actor_type, actor_id, action, old_value, new_value):
    _exec("INSERT INTO audit (ticket_id, actor_type, actor_id, action, old_value, new_value, created_at) "
          "VALUES (?, ?, ?, ?, ?, ?, ?)", (ticket_id, actor_type, actor_id, action, old_value, new_value, now()))


def get_audit(ticket_id):
    return [_row(r) for r in _all("SELECT * FROM audit WHERE ticket_id = ? ORDER BY created_at ASC, id ASC",
                                  (ticket_id,))]


# ---------- report ----------
def daily_report(day):
    """'day' is YYYY-MM-DD in UTC. substr(...,1,10) works for both ISO and SQLite timestamp formats."""
    one = lambda sql, *a: _one(sql, a)["n"]  # noqa: E731
    per_agent = _all(
        "SELECT a.id AS agent_id, a.name, COUNT(*) AS open FROM tickets t JOIN agents a ON a.id = t.agent_id "
        "WHERE t.status IN ('open', 'pending') GROUP BY a.id, a.name ORDER BY open DESC, a.name")
    return {
        "date": day,
        "created": one("SELECT COUNT(*) AS n FROM tickets WHERE substr(created_at, 1, 10) = ?", day),
        "solved": one("SELECT COUNT(*) AS n FROM tickets WHERE substr(solved_at, 1, 10) = ?", day),
        "open": one("SELECT COUNT(*) AS n FROM tickets WHERE status IN ('open', 'pending')"),
        "escalated": one("SELECT COUNT(*) AS n FROM tickets WHERE is_escalated = 1"),
        "open_per_agent": [dict(r) for r in per_agent],
    }
