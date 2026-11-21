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

Demo logins (password `password123`, from `backend/seed.py`): `asha@demo.com` (admin), `priya@demo.com` / `rahul@demo.com` (agents) log in as **Agent / Admin**. `aditi@acme.com` (Acme Corp) and `rohan@globex.com` (Globex) log in as **User**. On the login page, one click on a demo card logs you in.

**Clients and users:** a client is a company; a user belongs to one client and sees only that client's tickets. Agents see only the clients linked to them. Admins manage clients, users and agent access on the **Team** page (no open sign-up).

**AI assistant:** agents and admins get a panel with summary, sentiment, steps and a suggested reply on every ticket. Set `ANTHROPIC_API_KEY` before starting the backend for real AI; without it the panel shows a labelled offline estimate.

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
| `src/Login.jsx` | Login (`user_type` user/agent), one-click demo accounts |
| `src/App.jsx` | Session, top bar (shows a user's client), views by role. Staff load `/agents` for audit names |
| `src/TicketList.jsx` | Tabs and filters (`status`, `priority`, `escalated`, `agent_id`), search inside the loaded list, refreshes every 10 s, admin "Run escalation now" |
| `src/TicketDetail.jsx` | Thread, reply / internal note, status (`PATCH /status`), priority (`PATCH /priority`), assign (only agents linked to the ticket's client, `GET /clients/{id}/agents`), audit trail |
| `src/NewTicketModal.jsx` | Create ticket (users only; the ticket belongs to their client) |
| `src/Report.jsx` | Daily report (`/reports/daily?day=`) |
| `src/AdminPanel.jsx` | Team page: Users (`POST/GET /api/users`), Clients (`POST/GET /api/clients`), Staff (`POST /api/agents`) and each agent's client access (`GET/PUT /api/agents/{id}/clients`) |
| `src/AssistPanel.jsx` | AI assistant panel (`GET /api/tickets/{id}/assist`): summary, sentiment, confidence, step checklist, suggested reply with "Edit before sending" / "Send reply" |
| `src/ui.jsx` | Shared pieces: icons, avatar, status/priority badges, SLA chip, toasts, modal, keyboard shortcuts |
| `src/styles.css` | Design tokens (colours for light/dark mode, spacing, radius) and all styles |

## What each role sees

- **User** (belongs to a client): all of their client's tickets ("Raised by me" tab for their own), can create tickets and send public replies. Never sees internal notes, the audit trail or the AI assistant.
- **Agent**: tickets of the clients an admin linked them to; change status and priority, assign, internal notes, audit trail, AI assistant, daily report.
- **Admin**: every client's tickets, plus the Team page (users, clients, agent access) and the manual escalation trigger.

## Not in the UI yet (no endpoint in the contract)

Escalating a single ticket, search on the server, an "Unassigned" filter, disabling users.
