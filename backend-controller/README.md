# Mini-Zendesk: Controller layer (C of MVC)

The FastAPI Controller for Mini-Zendesk, a small support ticketing system.
Owner: Monali (Controller). Model: Mrudula. UI: Mrunnayee.

**Stack:** React (UI) · Python FastAPI (API) · SQLite (database)

## What the Controller does

For every request from the UI, the controller:
1. **Receives** it (URL + method)
2. **Validates** the input (Pydantic; bad input returns 422)
3. **Checks who is calling** and whether their role allows it
4. **Applies business rules** (status moves, round-robin, escalation)
5. **Calls the Model** to read or save (the controller never writes SQL)
6. **Returns JSON** with the right status code

```
React (V)  ──HTTP──>  Controller (C)  ──function calls──>  Model (M)  ──>  SQLite
                       │
                       ├─ schemas.py  (input validation)
                       ├─ deps.py     (who is calling, roles)
                       └─ rules.py    (business rules)
```

## Files

| File | Purpose |
|---|---|
| `main.py` | App setup, routers, one error format, escalation job every 60 s |
| `controllers/tickets.py` | Tickets: create, list/filter, detail, status, assign, messages, audit, escalation |
| `controllers/users.py` | Create and list clients and agents |
| `controllers/reports.py` | Daily report, manual escalation trigger |
| `constants.py` | Fixed values as Enums: status, priority, role, visibility, allowed moves, SLA. **No status table** |
| `schemas.py` | Request bodies (uses the Enums from `constants.py`) |
| `controllers/auth.py` | Login, logout, me |
| `deps.py` | Current user from the bearer token, role checks |
| `security.py` | Password hashing, token creation and hashing |
| `sessions.sql` | `sessions` table to add to the Model's schema |
| `rules.py` | Pure business rules (no DB, no FastAPI) |
| `models.py` | Model on **SQLite**: all SQL lives here. Uses `../backend/database.py` and `../backend/schema.sql`; DB file `../backend/zendesk.db` (override with `DB_PATH`) |
| `CONTRACT.md` | Function list for the Model, endpoint list for the UI |

## Run

```bash
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
.venv/bin/uvicorn main:app --reload
```

Open http://127.0.0.1:8000/docs to try every endpoint.

For a quick escalation demo, run with short SLAs:
```bash
SLA_UNIT=minutes .venv/bin/uvicorn main:app --reload
```

## Login (sessions)

```
1. POST /api/auth/login  {email, password, user_type: "client" | "agent"}
2. API checks the password hash (and is_active for agents)
3. API returns {token, expires_at, user}
4. React sends on every call:  Authorization: Bearer <token>
5. POST /api/auth/logout revokes the token
```

- Passwords: salted PBKDF2 (`security.py`). Old plain SHA-256 hashes from `seed.py` are still accepted.
- Tokens: random (`secrets.token_urlsafe`); only a **SHA-256 hash** is stored in `sessions`.
- Tokens expire after **8 hours**. Logout sets `revoked_at`.
- A disabled agent (`is_active = 0`) is locked out on the next request.
- Wrong email and wrong password return the same 401, so the API doesn't reveal which emails exist.
- Table: see `sessions.sql`.

Demo users (password `password123`): admin `asha@demo.com`, agents `priya@demo.com` / `rahul@demo.com` (user_type `agent`), client `ravi@demo.com` (user_type `client`).

In `/docs`: call login, copy the token, then fill the `authorization` field on each call with `Bearer <token>`.

## Endpoints

| Method | URL | Who | Purpose |
|---|---|---|---|
| POST | `/api/auth/login` | anyone | Log in, get a token |
| POST | `/api/auth/logout` | logged in | Revoke token |
| GET | `/api/auth/me` | logged in | Current user |
| POST | `/api/clients` | anyone | Register a client |
| POST | `/api/agents` | admin | Create an agent |
| GET | `/api/agents`, `/api/clients` | staff | Lists for dropdowns |
| POST | `/api/tickets` | client | Create ticket + auto-assign round-robin |
| GET | `/api/tickets?status=&priority=&escalated=&agent_id=&limit=&offset=` | all | List + filters (clients see only their own) |
| GET | `/api/tickets/{id}` | all | Detail with message thread |
| PATCH | `/api/tickets/{id}/status` | staff | Change status (validated) |
| PATCH | `/api/tickets/{id}/priority` | staff | Change priority; SLA deadline recalculated from creation time |
| POST | `/api/tickets/{id}/assign` | staff | Manual reassign |
| POST | `/api/tickets/{id}/messages` | all | Add message (internal = staff only) |
| GET | `/api/tickets/{id}/messages` | all | Thread, oldest first |
| GET | `/api/tickets/{id}/audit` | staff | Audit trail |
| GET | `/api/reports/daily?day=YYYY-MM-DD` | staff | Created, solved, open, escalated, per agent |
| POST | `/api/escalations/run` | admin | Run escalation now (demo) |

## Business rules (`rules.py`)

### Status lifecycle
```
open    → pending, solved
pending → open, solved
solved  → open, closed
closed  → (none)
```
Any other move returns **400** `invalid_transition`.

### Auto status on reply
| Event | New status |
|---|---|
| Agent replies (public) | pending (waiting on client) |
| Client replies | open (agent's turn; also reopens a solved ticket) |
| Reply on a closed ticket | rejected, 400 |
| Internal note | no change |

### Round-robin assignment
1. Get active agents (role `agent`), sorted by id
2. Pick the next one after `last_assigned_agent_id`; wrap around at the end
3. No agents → ticket stays unassigned
4. Save a worksheet row, move the pointer, write an audit row (one transaction)

Manual reassign adds a worksheet row but **does not move the pointer**.
Closed tickets and inactive agents are rejected with 400.

### SLA and escalation
| Priority | Must be solved within |
|---|---|
| urgent | 1 hour |
| high | 4 hours |
| normal | 24 hours |
| low | 48 hours |

Every 60 s the job finds open or pending tickets past `due_at` that aren't escalated yet, then:
priority goes up one level → `is_escalated = true` → reassigned to an admin → audited.

### Visibility
Messages are `public` or `internal`. Clients never see internal notes and cannot create them.

### Privacy
A client asking for someone else's ticket gets **404**, not 403, so the API doesn't reveal that the ticket exists.

## Agent ↔ client access
- Table `agent_clients` (many-to-many): an agent can serve many clients, a client can have many agents.
- **Agents** see and act only on tickets of their linked clients; anything else is **404** (list, detail, reply, status, priority, assign, audit). **Admins** see everything.
- **Round-robin** picks the next active agent *linked to that ticket's client*. **No linked agent → ticket stays unassigned** for the admin (option A).
- **Reassign** only to a linked agent (else 400 `agent_not_linked`). Escalation still moves tickets to the admin.
- **Configure (admin only):** `PUT /api/agents/{id}/clients {"client_ids": [1, 2]}` replaces the list. Takes effect on the agent's next request (checked every call, not stored in the token).
- Seed: every client has 2 agents, every agent 2–3 clients (e.g. Acme → Priya + Monali).


## Priority changes
- Staff can change priority on **open or pending** tickets (`PATCH /api/tickets/{id}/priority`).
- The SLA deadline is recalculated from the ticket's **creation time** (like Zendesk SLA policies), not from now.
  Raising an old ticket to urgent can make it overdue at once; the escalation job then escalates it.
- Same priority → 400 `no_change`; solved/closed → 400 `ticket_not_active`; every change is in the audit trail (`priority low → high`).

## Input cleaning
Titles, descriptions, messages and names are trimmed; whitespace-only values are rejected with 422.
Messages and descriptions are capped at 10,000 characters. Passwords are never trimmed.

## Audit trail
Every change is one row in `audit`: **who** (`actor_type`, `actor_id`), **what** (`action`, `old_value → new_value`), **when** (`created_at`).

| action | written when | example delta |
|---|---|---|
| `created` | user opens a ticket | `→ open` |
| `assigned` | round-robin (system) or manual reassign | `Priya Agent (2) → Rahul Agent (3)` |
| `status_change` | status set by staff or by a reply | `open → pending` |
| `priority_change` | staff change priority | `low → high` |
| `priority_bumped` | SLA breached (system) | `high → urgent` |
| `escalated` | SLA breached → moved to admin (system) | `Priya Agent (2) → Admin Asha (1)` |
| `message_added` | reply or internal note | `→ public` / `→ internal` |

- **Atomic:** the change and its audit row commit in one transaction; if the audit insert fails, the change rolls back (tested).
- **Immutable:** no API writes to audit (PUT/DELETE → 405), the model only INSERTs, and SQLite triggers abort any UPDATE/DELETE.
- **System actions** use `actor_type = 'system'`, `actor_id = 0`.
- **Read:** `GET /api/tickets/{id}/audit` (one ticket, oldest first) and `GET /api/audit` with filters `ticket_id, actor_type, actor_id, action, since, until, limit, offset` (newest first). Staff only; agents see only their linked clients.
- **Reassign with a reason:** `POST /api/tickets/{id}/assign {"agent_id": 3, "note": "..."}` saves the note as an internal message and audits it.

## Errors

Every error has one shape:
```json
{ "error": "invalid_transition", "message": "Cannot move from open to closed" }
```

| Code | Meaning |
|---|---|
| 201 | Created |
| 200 | OK |
| 400 | Business rule broken |
| 401 | Unknown user |
| 403 | Role not allowed |
| 404 | Not found |
| 409 | Duplicate email |
| 422 | Invalid input |
| 500 | Unexpected error (logged, server keeps running) |

## Database (SQLite)
- `models.py` loads Mrudula's `backend/database.py` (foreign keys on, WAL mode) and runs `schema.sql` on startup (`CREATE TABLE IF NOT EXISTS`, safe every time).
- Seed demo data once: `python3 ../backend/seed.py` (wipes and refills the tables).
- Data survives a server restart (tested: create ticket + message, restart, still there; tokens still valid).
- Each request thread gets its own SQLite connection; writes run in `BEGIN IMMEDIATE` transactions, so parallel ticket creation never gives two tickets the same round-robin agent (tested with 8 at once).
- Current agent is `tickets.agent_id`; every assignment is also appended to `worksheet` (history).
- System actions (round-robin, escalation) are recorded with `actor_type = 'system'`, `actor_id = 0` in `audit`, and `assigned_by = NULL` in `worksheet`.
- The schema's `sender_type` / `sender_id` columns are returned as `author_type` / `author_id` (what the UI reads).

## Why status is a constant, not a table
Statuses never change while the app runs, and the rules about them (which moves are allowed) must live in code anyway.
So status is an Enum in `constants.py`, and the DB stores it as TEXT with
`CHECK (status IN ('open','pending','solved','closed'))` as a safety net.
A table would only make sense if admins could create custom statuses from the UI.

## Q&A cheat sheet
- **Where are invalid status moves blocked?** `rules.check_transition`, called by the controller before the Model.
- **How does round-robin work?** `rules.next_agent`: the next id after the last one, wrapping around.
- **What if two tickets arrive at once?** Assignment runs in one transaction, so the pointer stays consistent.
- **What if two agents change the same ticket at once?** Every write endpoint reads the ticket, checks the rule and writes inside one `BEGIN IMMEDIATE` transaction. The second request waits, sees the updated ticket and gets a clear 400 (e.g. "Ticket is already closed") instead of silently overwriting. Tested: two agents closing the same ticket at the same moment → one 200, one 400, one audit row. The escalation job re-checks each ticket under the same lock, so a manual run and the background job never escalate twice.
- **What if the input is wrong?** Pydantic returns 422 with the field name.
- **Why is the controller thin?** Rules live in `rules.py` and SQL lives in the Model, so each layer is easy to test and swap.
