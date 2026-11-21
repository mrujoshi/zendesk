# Mini-Zendesk: contract between M, V, C

Run the backend: `.venv/bin/uvicorn main:app --reload`, then open http://127.0.0.1:8000/docs

## For Mrudula (Model): replace `models.py` with the SQLite version, keeping these exact functions

| Function | Returns |
|---|---|
| `init()` | create tables if missing (+ seed) |
| `transaction()` | context manager: BEGIN / COMMIT / ROLLBACK |
| `create_client(name, email)` / `create_agent(name, email, role)` | dict |
| `get_client(id)` / `get_agent(id)` | dict or None (agent has `role`, `is_active`) |
| `email_exists(kind, email)` | bool (`kind` = "client" / "agent") |
| `list_agents()` / `list_clients()` | list of dicts |
| `active_agent_ids()` | ids of active agents with role 'agent' (round-robin pool) |
| `admin_id()` | id of an active admin, or None |
| `get_last_assigned()` / `set_last_assigned(id)` | settings table, key `last_assigned_agent_id` |
| `create_ticket(client_id, title, description, priority, due_at)` | ticket dict |
| `get_ticket(id)` | ticket dict **with `agent_id`** (latest worksheet row) or None |
| `list_tickets(status, priority, escalated, agent_id, client_id, limit, offset)` | `{items, total, limit, offset}`, newest first |
| `update_status(id, status)` | sets `updated_at`; `solved_at` = now when solved, cleared when reopened |
| `assign(ticket_id, agent_id, assigned_by, reason)` | inserts a worksheet row (never updates) |
| `add_message(ticket_id, author_type, author_id, text, visibility)` | message dict |
| `get_messages(ticket_id, include_internal)` | list, oldest first |
| `audit(ticket_id, actor_type, actor_id, action, old_value, new_value)` | insert only |
| `get_audit(ticket_id)` | list, oldest first |
| `overdue_tickets(now_iso)` | open/pending, not escalated, `due_at < now_iso` |
| `escalate(id, new_priority)` | sets priority, `is_escalated = 1` |
| `daily_report(day)` | `{date, created, solved, open, escalated, open_per_agent}` |

Ticket dict keys: `id, client_id, agent_id, title, description, status, priority, is_escalated, attachment_path, created_at, updated_at, solved_at, due_at`.
Times are UTC ISO strings (`2026-11-21T10:30:00+00:00`).
Remember `PRAGMA foreign_keys = ON` on every connection.

## For Mrunnayee (UI)

Every request sends the headers `X-Actor-Type` (client / agent / admin) and `X-Actor-Id`.
Demo users: admin id 1, agents 2 and 3, client id 1.

| Method | URL | Who |
|---|---|---|
| POST | `/api/clients` | anyone |
| POST | `/api/agents` | admin |
| GET | `/api/agents`, `/api/clients` | staff |
| POST | `/api/tickets` `{title, description, priority}` | client |
| GET | `/api/tickets?status=&priority=&escalated=&agent_id=&limit=&offset=` | all (client sees own only) |
| GET | `/api/tickets/{id}` (includes `messages`) | all |
| PATCH | `/api/tickets/{id}/status` `{status}` | staff |
| POST | `/api/tickets/{id}/assign` `{agent_id}` | staff |
| POST | `/api/tickets/{id}/messages` `{text, visibility}` | all (internal = staff only) |
| GET | `/api/tickets/{id}/audit` | staff |
| GET | `/api/reports/daily?day=YYYY-MM-DD` | staff |
| POST | `/api/escalations/run` | admin (demo button) |

Errors always look like `{"error": "code", "message": "text"}`. Show `message` to the user.
Codes: 400 rule broken, 401 unknown user, 403 not allowed, 404 not found, 409 duplicate, 422 bad input.

## Rules (in `rules.py`)
- Status moves: open→pending/solved, pending→open/solved, solved→open/closed, closed→none
- Agent reply → pending, client reply → open, reply on closed → 400
- Round-robin among active agents; manual reassign does not move the pointer
- SLA: urgent 1, high 4, normal 24, low 48 (hours; `SLA_UNIT=minutes` for the demo)
- Escalation runs every 60 s: priority +1, flagged, moved to admin, audited
