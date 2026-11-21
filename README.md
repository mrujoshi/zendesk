# Mini-Zendesk: Support Ticketing System

> **Zendesk Pune Developer Workshop — One-Day Coding Challenge (Nov 21, 2026)**  
> A lightweight, production-grade support ticketing platform built with **React**, **Python (FastAPI)**, and **SQLite**.

---

## 👥 Team & Ownership

| Name | Role | Responsibilities |
| :--- | :--- | :--- |
| **Mrunnayee** | **Frontend (UI)** | React agent workspace, customer portal, ticket timeline, live filters, dashboards. |
| **Mrudula** | **Backend (Model)** | SQLite schema design, connection pooling (WAL mode), relational integrity, indexes, seeding. |
| **Monali** | **Backend (Controller)** | FastAPI controllers, Pydantic validation, auth/session tokens, business rules, SLA escalation. |

---

## 🏛️ System Architecture (MVC)

The system enforces strict separation of concerns across layers:

```
┌────────────────────────────────┐
│      React Frontend (View)     │  Served in browser, pure HTTP consumer
└───────────────┬────────────────┘
                │  Authorization: Bearer <token>
                ▼
┌────────────────────────────────┐
│    FastAPI Controller (C)      │  Input validation (Pydantic), Auth (RBAC),
│                                │  Business Rules (rules.py), Escalation worker
└───────────────┬────────────────┘
                │  Function Calls via Contract (CONTRACT.md)
                ▼
┌────────────────────────────────┐
│       SQLite Model (M)         │  PRAGMA foreign_keys = ON, WAL mode,
│                                │  Append-only Audit Trail, Threaded Messages
└────────────────────────────────┘
```

---

## 🚀 Core Features (Challenge Baseline)

1. **Ticket Creation:** Clients file tickets with title, description, and priority. The system calculates SLA `due_at` and assigns an agent via atomic round-robin.
2. **Assign & Reassign:** Tickets are assigned to active agents. Reassignments are tracked in the **Worksheet** and logged to the **Audit Trail**.
3. **Status Lifecycle:** Validated state transitions:
   $$\text{open} \rightleftharpoons \text{pending} \rightarrow \text{solved} \rightarrow \text{closed}$$
   Invalid transitions (e.g., `open` $\rightarrow$ `closed`) are rejected with `400 Bad Request`.
4. **Threaded Conversation:** Ordered back-and-forth messages (`public` replies and private `internal` agent notes) with automatic status triggers:
   * **Agent replies** $\rightarrow$ status auto-updates to `pending` (waiting on client).
   * **Client replies** $\rightarrow$ status auto-updates to `open` (needs agent action).

---

## 🎯 Implemented Stretch Goals

* 🛡️ **Audit Trail (Append-Only):** Every creation, assignment, status change, and escalation writes an immutable row with `actor_type`, `actor_id`, `action`, `old_value`, and `new_value`. Queryable via `GET /api/tickets/{id}/audit`.
* 🔑 **Token-Based Session Authentication:** Hashed Bearer tokens (SHA-256), 8-hour expiry, logout revocation (`POST /api/auth/logout`), and soft-disable check on every request.
* ⏱️ **SLA & Background Escalation Engine:** Periodic background task (every 60s) checks for overdue tickets (`due_at < NOW`), bumps priority (`low` $\rightarrow$ `normal` $\rightarrow$ `high` $\rightarrow$ `urgent`), flags `is_escalated = 1`, and reassigns to an Admin with an audit log.
* 📊 **Daily Manager Report:** `GET /api/reports/daily?day=YYYY-MM-DD` returns ticket counts (created, solved, open, escalated) and active load per agent.
* 🌱 **Demo-Ready Seed Data:** Pre-populated with **10 rows each** across Users, Clients, Customers, and Agents.

---

## 🗄️ Database Schema & Data Model

SQLite datastore located at `backend/zendesk.db` configured with `WAL` journal mode for zero read/write lock contention.

| Table | Purpose | Key Columns |
| :--- | :--- | :--- |
| **`clients`** | External companies / requesters | `id`, `name`, `email`, `password_hash`, `created_at` |
| **`customers`** | End-user customer accounts | `id`, `name`, `email`, `password_hash`, `created_at` |
| **`agents`** | Internal support staff and admins | `id`, `name`, `email`, `role` (`admin`/`agent`), `password_hash`, `is_active` |
| **`users`** | General internal directory | `id`, `name`, `category`, `password_hash`, `created_at` |
| **`tickets`** | Core ticket entity | `id`, `title`, `description`, `status`, `priority`, `client_id`, `agent_id`, `due_at`, `is_escalated`, `solved_at` |
| **`messages`** | Chronological conversation thread | `id`, `ticket_id`, `sender_id`, `sender_type` (`client`/`agent`), `text`, `visibility` (`public`/`internal`) |
| **`worksheet`** | Agent assignment queue & handoffs | `id`, `ticket_id`, `agent_id`, `assigned_by`, `reason`, `status`, `created_at` |
| **`audit`** | Immutable append-only audit trail | `id`, `ticket_id`, `actor_type`, `actor_id`, `action`, `old_value`, `new_value`, `created_at` |
| **`sessions`** | Active login sessions | `id`, `token_hash` (SHA-256), `user_type`, `user_id`, `expires_at`, `revoked_at` |
| **`statuses`** | Static lifecycle definitions | `open`, `pending`, `solved`, `closed`, `sla_breached`, `escalated` |
| **`priorities`** | Priority SLAs | `low` (48h), `normal` (24h), `high` (4h), `urgent` (1h) |
| **`system_settings`** | Runtime state persistence | `last_assigned_agent_id` for round-robin continuity across restarts |

---

## 🔌 API Endpoints (Contract)

### Authentication & Users
| Method | Endpoint | Access | Purpose |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/auth/login` | Public | Log in (`email`, `password`, `user_type`), returns Bearer token |
| `POST` | `/api/auth/logout` | Authenticated | Revoke current Bearer token |
| `GET` | `/api/auth/me` | Authenticated | Get current authenticated user details |
| `POST` | `/api/clients` | Public | Register client account |
| `POST` | `/api/agents` | Admin | Create agent account |
| `GET` | `/api/agents` | Staff | List active agents for assignment dropdowns |

### Tickets & Workflow
| Method | Endpoint | Access | Purpose |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/tickets` | Client | Create ticket + auto-assign round-robin |
| `GET` | `/api/tickets` | Authenticated | List tickets with filters (`status`, `priority`, `agent_id`, `escalated`, pagination) |
| `GET` | `/api/tickets/{id}` | Authenticated | Ticket detail with message thread |
| `PATCH` | `/api/tickets/{id}/status` | Staff | Change ticket status (enforces lifecycle rules) |
| `POST` | `/api/tickets/{id}/assign` | Staff | Manual reassign to agent (updates Worksheet & Audit) |
| `POST` | `/api/tickets/{id}/messages`| Authenticated | Add message (`public` or `internal`; triggers auto-status) |
| `GET` | `/api/tickets/{id}/audit` | Staff | View complete append-only audit trail |
| `GET` | `/api/reports/daily` | Staff | Daily metrics breakdown (`?day=YYYY-MM-DD`) |
| `POST` | `/api/escalations/run` | Admin | Trigger SLA escalation check manually (demo shortcut) |

---

## 🛠️ How to Run Locally

### 1. Backend Setup (Terminal 1)
```bash
cd backend-controller

# Create and activate virtual environment
python3 -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Start FastAPI server
uvicorn main:app --reload --port 8000
```

* **Interactive OpenAPI Swagger Docs:** [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)
* **Fast Demo Mode (Short SLA in minutes):**
  ```bash
  SLA_UNIT=minutes uvicorn main:app --reload --port 8000
  ```

### 2. Frontend Setup (Terminal 2)
```bash
cd frontend

# Install Node dependencies
npm install

# Start Vite React development server (proxies /api to :8000)
npm run dev
```

* **Browser UI:** [http://localhost:5173](http://localhost:5173)

### 3. Database Seeding & Standalone Dumps
To re-initialize and seed 10 rows in user/client/customer/agent tables plus 100 tickets:
```bash
python3 ../backend/seed.py
```

* **Standalone SQLite Database:** [`backend/dummyticketdataquery.db`](file:///Users/mrudula/Projects/Zendesk/zendesk/backend/dummyticketdataquery.db) (pre-seeded with 100 tickets).
* **SQL Query Dump:** [`backend/dummyticketdataquery.sql`](file:///Users/mrudula/Projects/Zendesk/zendesk/backend/dummyticketdataquery.sql) (raw SQL statements to recreate and populate the full database).

### 4. Demo Credentials
* **All seed accounts use password:** `password123`
* **Admin:** `asha@demo.com` (`user_type`: `agent`)
* **Agents:** `priya@demo.com`, `rahul@demo.com`, `mrudula@support.com`, `monali@support.com` (`user_type`: `agent`)
* **Client:** `ravi@demo.com`, `support@acme.com` (`user_type`: `client`)

---

## 🧪 API Testing with Bruno

A complete, Git-friendly **Bruno API Testing Collection** is included in [`/bruno`](file:///Users/mrudula/Projects/Zendesk/zendesk/bruno).

### Using the Collection in Bruno:
1. Open the [Bruno app](https://www.usebruno.com/).
2. Click **Open Collection** and select the [`bruno`](file:///Users/mrudula/Projects/Zendesk/zendesk/bruno) directory in this repo.
3. Select the **Local** environment (top-right dropdown).
4. Run `Auth / Login (Agent)` or `Auth / Login (Client)`. The Bearer `token` variable is **automatically captured** and passed into subsequent requests!

### Organized Test Suites:
* **`Auth/`**: Login as Client, Agent, Admin; Who Am I (`/me`); Logout token revocation.
* **`Tickets/`**: Create Ticket (auto-assigns agent), Filter Tickets, Ticket Detail, Status Transitions, Manual Reassignment.
* **`Messages/`**: Post public reply (auto-sets `pending`), post internal note, get conversation thread.
* **`Audit/`**: Get immutable audit trail for ticket.
* **`Reports & Escalations/`**: Daily breakdown metrics, trigger SLA escalation job.
* **`Users & Directory/`**: Register Client, Create Agent, List Agents & Clients.
