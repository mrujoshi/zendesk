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
| `deps.py` | Current actor from headers, role checks |
| `rules.py` | Pure business rules (no DB, no FastAPI) |
| `models.py` | **Temporary in-memory stub.** Replaced by the SQLite Model at merge |
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

## Identity (demo)

Every request sends two headers:
- `X-Actor-Type`: `client`, `agent` or `admin`
- `X-Actor-Id`: the user's id

Seeded demo users: admin **1** (Admin Asha), agents **2** (Priya) and **3** (Rahul), client **1** (Ravi).
In production this would be a real login (token / session).

## Endpoints

| Method | URL | Who | Purpose |
|---|---|---|---|
| POST | `/api/clients` | anyone | Register a client |
| POST | `/api/agents` | admin | Create an agent |
| GET | `/api/agents`, `/api/clients` | staff | Lists for dropdowns |
| POST | `/api/tickets` | client | Create ticket + auto-assign round-robin |
| GET | `/api/tickets?status=&priority=&escalated=&agent_id=&limit=&offset=` | all | List + filters (clients see only their own) |
| GET | `/api/tickets/{id}` | all | Detail with message thread |
| PATCH | `/api/tickets/{id}/status` | staff | Change status (validated) |
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

## Merge plan
1. **Model:** Mrudula's SQLite `models.py` replaces the stub with the same function names (see `CONTRACT.md`).
2. **UI:** React calls `/api/...` and sends the two headers.
3. **Check:** create a ticket, restart the server, and confirm the data is still there.

## Why status is a constant, not a table
Statuses never change while the app runs, and the rules about them (which moves are allowed) must live in code anyway.
So status is an Enum in `constants.py`, and the DB stores it as TEXT with
`CHECK (status IN ('open','pending','solved','closed'))` as a safety net.
A table would only make sense if admins could create custom statuses from the UI.

## Q&A cheat sheet
- **Where are invalid status moves blocked?** `rules.check_transition`, called by the controller before the Model.
- **How does round-robin work?** `rules.next_agent`: the next id after the last one, wrapping around.
- **What if two tickets arrive at once?** Assignment runs in one transaction, so the pointer stays consistent.
- **What if the input is wrong?** Pydantic returns 422 with the field name.
- **Why is the controller thin?** Rules live in `rules.py` and SQL lives in the Model, so each layer is easy to test and swap.
