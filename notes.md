# Mini-Zendesk Project Notes

## Team & Roles
* **Mrunnayee** - Frontend / UI
* **Mrudula** - Backend
* **Monali** - Backend

## Tech Stack
* **Frontend:** React
* **Backend:** Python (FastAPI)
* **Database:** SQLite (with WAL mode & Foreign Keys enabled)

---

## Data Model

### Tables

1. **Users / Identity**
   * `id` (INTEGER, PK, AUTOINCREMENT)
   * `name` (TEXT, NOT NULL)
   * `email` (TEXT, UNIQUE, NOT NULL)
   * `password_hash` (TEXT, NOT NULL)
   * `role` (TEXT: `'client'`, `'agent'`, `'admin'`)
   * `is_active` (INTEGER, DEFAULT 1)
   * `created_at` (TIMESTAMP DEFAULT CURRENT_TIMESTAMP)

2. **Tickets**
   * `id` (INTEGER, PK, AUTOINCREMENT)
   * `title` (TEXT, NOT NULL)
   * `description` (TEXT, NOT NULL)
   * `status` (TEXT: `'open'`, `'pending'`, `'solved'`, `'closed'`, DEFAULT `'open'`)
   * `priority` (TEXT: `'low'`, `'medium'`, `'high'`, `'urgent'`, DEFAULT `'medium'`)
   * `requester_id` (INTEGER, FK -> users.id)
   * `assignee_id` (INTEGER, FK -> users.id, NULLABLE)
   * `due_at` (TIMESTAMP, calculated based on priority SLA)
   * `attachment_url` (TEXT, NULLABLE)
   * `created_at` (TIMESTAMP DEFAULT CURRENT_TIMESTAMP)
   * `updated_at` (TIMESTAMP DEFAULT CURRENT_TIMESTAMP)

3. **Messages**
   * `id` (INTEGER, PK, AUTOINCREMENT)
   * `ticket_id` (INTEGER, FK -> tickets.id)
   * `sender_id` (INTEGER, FK -> users.id)
   * `text` (TEXT, NOT NULL)
   * `visibility` (TEXT: `'public'`, `'internal'`, DEFAULT `'public'`)
   * `created_at` (TIMESTAMP DEFAULT CURRENT_TIMESTAMP)

4. **Worksheet** (Active agent queue & workload tracking)
   * `id` (INTEGER, PK, AUTOINCREMENT)
   * `ticket_id` (INTEGER, FK -> tickets.id)
   * `agent_id` (INTEGER, FK -> users.id)
   * `status` (TEXT)
   * `assigned_at` (TIMESTAMP DEFAULT CURRENT_TIMESTAMP)

5. **Audit Trail / Ticket Events** (Append-only change log)
   * `id` (INTEGER, PK, AUTOINCREMENT)
   * `ticket_id` (INTEGER, FK -> tickets.id)
   * `user_id` (INTEGER, FK -> users.id, NULLABLE)
   * `event_type` (TEXT: `'created'`, `'assigned'`, `'reassigned'`, `'status_change'`, `'message_added'`, `'escalated'`)
   * `old_value` (TEXT, NULLABLE)
   * `new_value` (TEXT, NULLABLE)
   * `created_at` (TIMESTAMP DEFAULT CURRENT_TIMESTAMP)

---

## Functional Requirements

### 1. Authentication & Login-Based Access Control (RBAC)
* **Login Endpoint:** `POST /api/auth/login` with email and password, returning user info and session token/role.
* **Role-Based Access Permissions:**
  * **Client / Requester:**
    * Can view, search, and list only tickets where `requester_id = current_user.id`.
    * Can create tickets (`POST /api/tickets`).
    * Can post public replies (`POST /api/tickets/{id}/messages` with `visibility = 'public'`).
    * Forbidden (`403`) from posting or viewing internal agent notes.
  * **Agent:**
    * Can view assigned tickets and the general ticket queue.
    * Can be assigned tickets automatically (round-robin) or manually.
    * Can post public replies (to client) and private internal notes (`visibility = 'internal'`).
    * Can update ticket status (`open` -> `pending` -> `solved`).
  * **Admin:**
    * Full system access: manage users/agents, reassign tickets, view full worksheets and audit logs.
    * Can trigger ticket escalations and modify closed tickets if necessary.

---

### 2. Core Workflows & API Specifications

#### 1. Create User / Agent
1. `POST /api/users` (or `POST /api/clients`, `POST /api/agents`) with `name`, `email`, `password`, and `role` (`'client'`, `'agent'`, `'admin'`).
2. Validate non-empty name, valid email, and acceptable role.
3. Check email uniqueness; return `409 Conflict` if email already exists.
4. Save with `is_active = 1` and return `201 Created`.

#### 2. Create Ticket (Core)
1. `POST /api/tickets` with `title`, `description`, `priority` (and authenticated requester).
2. Validate input; invalid input returns `422 Unprocessable Entity`.
3. Set initial status to `'open'` and calculate `due_at` from SLA priority (`urgent` < `high` < `medium` < `low`).
4. Assign agent via round-robin.
5. Create Worksheet record, write an Audit row (`event_type: 'created'`), and return `201 Created`.

#### 3. Assign / Reassign: Round-Robin (Core)
1. Fetch active agents sorted by `id`, check last assigned agent pointer.
2. Select next agent, wrapping around at the end. If no active agents exist, leave `assignee_id = NULL`.
3. Save Worksheet row, update ticket `assignee_id`, update pointer, and record an audit row in one transaction.
4. **Manual Reassign:** `POST /api/tickets/{id}/assign` with `agent_id`. Verify ticket is not closed and target agent is active; record Worksheet and audit log.

#### 4. Add Messages / Comments (Core)
1. `POST /api/tickets/{id}/messages` with `text` and `visibility` (`'public'` or `'internal'`).
2. Return `404 Not Found` if ticket does not exist; return `403 Forbidden` if a client attempts to add an internal note.
3. Persist the message with timestamp and `sender_id`.
4. **Auto-Status Transition:**
   * Agent reply $\rightarrow$ auto-update status to `'pending'` (waiting on customer).
   * Client reply $\rightarrow$ auto-update status to `'open'` (needs agent attention).
   * If ticket is `'closed'` $\rightarrow$ reject with `400 Bad Request`.
5. Write an audit row recording message addition and any status transition; return `201 Created`.

---

### 3. Stretch Goals & Non-Functional Requirements
1. **Filters & Views:** Filter tickets by status (`open`, `pending`, `solved`, `closed`), priority, or assigned agent.
2. **Escalation Flow:** Detect overdue tickets (`due_at < NOW`) and auto-escalate priority to `'urgent'` or reassign to admin.
3. **Audit Trail:** Append-only event history queryable via `GET /api/tickets/{id}/audit`.
4. **Performance:** Sub-millisecond SQLite queries using WAL mode and composite indexes.
5. **Data Persistence:** Complete persistence across server restarts using SQLite.
