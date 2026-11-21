# Mini-Zendesk: contract between M, V, C

Run the backend: `.venv/bin/uvicorn main:app --reload`, then open http://127.0.0.1:8000/docs

## Model functions (`models.py`, implemented on SQLite): the controller calls only these

| Function | Returns |
|---|---|
| `init()` | create tables if missing (+ seed) |
| `transaction()` | context manager: BEGIN / COMMIT / ROLLBACK |
| `create_client(name, email)` / `create_user(client_id, name, email, category, password_hash)` / `create_agent(name, email, role, password_hash)` | dict **without** password_hash |
| `find_for_login(user_type, email)` | `user_type` = "user" / "agent"; row **with** password_hash (only function that returns it), or None |
| `create_session(token_hash, user_type, user_id, expires_at)` | insert into `sessions` (see `sessions.sql`) |
| `get_session(token_hash, now_iso)` | session dict if not revoked and not expired, else None |
| `revoke_session(token_hash)` | set `revoked_at` |
| `get_client(id)` / `get_user(id)` / `get_agent(id)` | dict or None (user has `client_id`, `client_name`; agent has `role`, `is_active`) |
| `email_exists(kind, email)` | bool (`kind` = "user" / "agent" / "client") |
| `list_agents()` / `list_clients(ids=None)` / `list_users(client_id=None)` | list of dicts (clients include `user_count`, `ticket_count`) |
| `active_agent_ids(client_id=None)` | active agents with role 'agent'; with client_id only those linked to it |
| `linked_client_ids(agent_id)` / `linked_agents(client_id)` / `set_agent_clients(agent_id, ids)` / `existing_client_ids(ids)` | agent ↔ client access (`agent_clients` table) |
| `admin_id()` | id of an active admin, or None |
| `get_last_assigned()` / `set_last_assigned(id)` | settings table, key `last_assigned_agent_id` |
| `create_ticket(client_id, user_id, title, description, priority, due_at)` | ticket dict |
| `get_ticket(id)` | ticket dict **with `agent_id`** (latest worksheet row) or None |
| `list_tickets(status, priority, escalated, agent_id, client_id, limit, offset)` | `{items, total, limit, offset}`, newest first |
| `update_status(id, status)` | sets `updated_at`; `solved_at` = now when solved, cleared when reopened |
| `assign(ticket_id, agent_id, assigned_by, reason)` | inserts a worksheet row (never updates) |
| `add_message(ticket_id, author_type, author_id, text, visibility)` | message dict |
| `get_messages(ticket_id, include_internal)` | list, oldest first |
| `audit(ticket_id, actor_type, actor_id, action, old_value, new_value)` | insert only |
| `get_audit(ticket_id)` | list, oldest first |
| `overdue_tickets(now_iso)` | open/pending, not escalated, `due_at < now_iso` |
| `update_priority(id, priority, due_at)` | sets priority + new SLA deadline |
| `escalate(id, new_priority)` | sets priority, `is_escalated = 1` |
| `daily_report(day)` | `{date, created, solved, open, escalated, open_per_agent}` |

Ticket dict keys: `id, client_id, client_name, user_id, user_name, user_email, agent_id, agent_name, title, description, status, priority, is_escalated, attachment_path, created_at, updated_at, solved_at, due_at`.
Times are UTC ISO strings (`2026-11-21T10:30:00+00:00`).
Remember `PRAGMA foreign_keys = ON` on every connection.

## For Mrunnayee (UI)

Log in with `POST /api/auth/login {email, password, user_type}` → save `token`.
Every request sends `Authorization: Bearer <token>`. On 401, send the user back to the login page.
Demo (password `password123`): asha@demo.com (admin), priya@demo.com (agent) → user_type `agent`;
aditi@acme.com / aarav@acme.com (Acme Corp), rohan@globex.com (Globex) → user_type `user`.

**Clients and users.** A *client* is a company (`clients` table) and does not log in. A *user* is a person
who belongs to exactly one client (`users.client_id`) and logs in with user_type `user`. A user sees
**all tickets of their own client** (colleagues share them) and nothing from any other client: another
client's ticket returns 404. `/auth/me` for a user returns `role: "user"`, `client_id`, `client_name`.
Only admins create clients and users (no open sign-up, otherwise anyone could join any client).

| Method | URL | Who |
|---|---|---|
| POST | `/api/auth/login` `{email, password, user_type: "user" \| "agent"}`, `/api/auth/logout`; GET `/api/auth/me` | anyone / logged in |
| POST | `/api/clients` `{name, email}` | admin |
| GET | `/api/clients` (with `user_count`, `ticket_count`) | staff |
| POST | `/api/users` `{client_id, name, email, password, category}` | admin |
| GET | `/api/users?client_id=` (with `client_name`) | staff |
| POST | `/api/agents` | admin |
| GET | `/api/agents`, `/api/clients` | staff (agents get only their linked clients) |
| GET | `/api/agents/{id}/clients` | admin, or that agent → `{agent_id, client_ids}` |
| PUT | `/api/agents/{id}/clients` `{client_ids: [..]}` | admin; replaces the agent's full list |
| GET | `/api/clients/{id}/agents` | staff → agents linked to that client (use for the reassign dropdown) |
| POST | `/api/tickets` `{title, description, priority}` | user (ticket belongs to their client) |
| GET | `/api/tickets?status=&priority=&escalated=&agent_id=&limit=&offset=` | all (user: own client's tickets; agent: linked clients; admin: all) |
| GET | `/api/tickets/{id}` (includes `messages`) | all |
| PATCH | `/api/tickets/{id}/status` `{status}` | staff |
| PATCH | `/api/tickets/{id}/priority` `{priority}` | staff (open/pending tickets only; SLA deadline recalculated from creation; audit action `priority`) |
| POST | `/api/tickets/{id}/assign` `{agent_id, note?}` | staff (`note` is saved as an internal note) |
| POST | `/api/tickets/{id}/messages` `{text, visibility}` | all (internal = staff only) |
| GET | `/api/tickets/{id}/audit` | staff (oldest first, with `actor_name`) |
| GET | `/api/audit?ticket_id=&actor_type=&actor_id=&action=&since=&until=&limit=&offset=` | staff (agents: linked clients only); newest first, with `actor_name`, `ticket_title` |
| GET | `/api/tickets/{id}/assist?refresh=` → `{category, summary, sentiment: Angry\|Neutral\|Positive, sentiment_reason, confidence, steps[], suggested_reply, source: ai\|offline, model, generated_at, cached}` | staff (AI assistant; needs `ANTHROPIC_API_KEY` on the server, else `source: offline`) |
| GET | `/api/reports/daily?day=YYYY-MM-DD` | staff |
| POST | `/api/escalations/run` | admin (demo button) |

Errors always look like `{"error": "code", "message": "text"}`. Show `message` to the user.
Codes: 400 rule broken, 401 not logged in / token expired, 403 not allowed, 404 not found, 409 duplicate, 422 bad input.

## Rules (in `rules.py`)
- Status moves: open→pending/solved, pending→open/solved, solved→open/closed, closed→none
- Agent reply → pending, user reply → open, reply on closed → 400
- Round-robin among active agents; manual reassign does not move the pointer
- SLA: urgent 1, high 4, normal 24, low 48 (hours; `SLA_UNIT=minutes` for the demo)
- Escalation runs every 60 s: priority +1, flagged, moved to admin, audited
