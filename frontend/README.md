# Mini-Zendesk: UI (V of MVC)

React + Vite frontend for the controller in `backend-controller/`. It follows the "For Mrunnayee (UI)" section of `backend-controller/CONTRACT.md`.

## Run

```bash
# 1. API (terminal 1)
cd backend-controller
python3 -m venv .venv && .venv/bin/pip install -r requirements.txt
.venv/bin/uvicorn main:app --reload --port 8000

# 2. UI (terminal 2) - the dev server sends /api requests on to :8000
cd frontend
npm install
npm run dev        # open http://localhost:5173
```

Demo logins (password `password123`, from `backend/seed.py`): `asha@demo.com` (admin), `priya@demo.com` / `rahul@demo.com` (agents) log in as **Agent / Admin**. `support@acme.com` (Acme Corp) logs in as **Client**. On the login page, one click on a demo card logs you in. New clients can sign up there too.

## UI features

- Inter font, light and dark mode (follows the system, toggle with the moon/sun button or **T**), works at phone width
- Clickable status stepper (Open → Pending → Solved → Closed): only the moves the API allows are clickable
- Chat-style thread with avatars, Public reply / Internal note tabs, **⌘/Ctrl+Enter** to send
- Live SLA chips (grey → amber under 2 h → red when overdue), list refreshes every 10 s with a "Live" indicator
- Toast messages for every action and error, loading skeletons, empty states, search highlighting
- Keyboard shortcuts (press **?**): **J/K** move between tickets, **/** search, **N** new ticket, **R** reply, **1–3** switch page, **Esc** close

## Files

| File | What it does |
|---|---|
| `src/api.js` | The only place that calls `fetch`. Adds `Authorization: Bearer <token>`, shows the `{error, message}` text, sends the user to login on 401. Also mirrors the status moves and SLAs from `constants.py` |
| `src/Login.jsx` | Login (`user_type` client/agent) and client sign-up (`POST /api/clients`) |
| `src/App.jsx` | Session, top bar, views by role. Loads `/agents` + `/clients` so staff see names (tickets only carry ids) |
| `src/TicketList.jsx` | Tabs and filters (`status`, `priority`, `escalated`, `agent_id`), search inside the loaded list, refreshes every 10 s, admin "Run escalation now" |
| `src/TicketDetail.jsx` | Thread, reply / internal note, status (`PATCH /status`), assign, audit trail |
| `src/NewTicketModal.jsx` | Create ticket (clients only) |
| `src/Report.jsx` | Daily report (`/reports/daily?day=`) |
| `src/AdminPanel.jsx` | Create agents/admins (`POST /api/agents`), list agents and clients |
| `src/ui.jsx` | Shared pieces: icons, avatar, status/priority badges, SLA chip, toasts, modal, keyboard shortcuts |
| `src/styles.css` | Design tokens (colours for light/dark mode, spacing, radius) and all styles |

Seeded data also contains the statuses `escalated` and `sla_breached`, which aren't part of the lifecycle. The UI shows them with their own colour, but the API can't move them to another status.

## What each role sees

- **Client**: only their own tickets, can create tickets and send public replies. Never sees internal notes or the audit trail.
- **Agent**: all tickets, change status, assign, internal notes, audit trail, daily report.
- **Admin**: everything an agent sees, plus the Team page and the manual escalation trigger.

## Not in the UI yet (no endpoint in the contract)

Changing priority, escalating a single ticket, search on the server, an "Unassigned" filter, disabling users.
