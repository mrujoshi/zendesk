# Mini-Zendesk Project Notes

## Team & Roles
* **Mrunnayee** - Frontend / UI
* **Mrudula** - Backend (Data Model & SQLite Persistence)
* **Monali** - Backend (Controllers, Routing & Business Rules)

## Tech Stack
* **Frontend:** React
* **Backend:** Python (FastAPI)
* **Database:** SQLite (with WAL mode & Foreign Keys enabled)

---

## Data Model

### Tables

1. **User** (General / System users)
   * `id` (INTEGER, PK, AUTOINCREMENT)
   * `name` (TEXT, NOT NULL)
   * `category` (TEXT, NOT NULL)
   * `password_hash` (TEXT, NOT NULL - Encrypted/Hashed using SHA-256 / PBKDF2)
   * `created_at` (TIMESTAMP DEFAULT CURRENT_TIMESTAMP)

2. **Client** (External Requesters / Client Organizations)
   * `id` (INTEGER, PK, AUTOINCREMENT)
   * `name` (TEXT, NOT NULL)
   * `email` (TEXT, UNIQUE, NOT NULL)
   * `password_hash` (TEXT, NOT NULL - Encrypted password)
   * `created_at` (TIMESTAMP DEFAULT CURRENT_TIMESTAMP)

3. **Agent** (Internal Support Staff & Admins)
   * `id` (INTEGER, PK, AUTOINCREMENT)
   * `name` (TEXT, NOT NULL)
   * `email` (TEXT, UNIQUE, NOT NULL)
   * `role` (TEXT: `'admin'`, `'agent'`, NOT NULL)
   * `password_hash` (TEXT, NOT NULL - Encrypted password)
   * `is_active` (INTEGER, DEFAULT 1)
   * `client_id` (INTEGER, NULLABLE, FK -> Client.id)
   * `created_at` (TIMESTAMP DEFAULT CURRENT_TIMESTAMP)

4. **Status** (Ticket Lifecycle & SLA State Definitions)
   * `id` (INTEGER, PK, AUTOINCREMENT)
   * `name` (TEXT, UNIQUE, NOT NULL)
   * *Allowed Values:*
     * `open` (Agent action required)
     * `pending` (Waiting for client response)
     * `solved` (Resolved by agent, client can confirm or reopen)
     * `closed` (Final state, locked)
     * `sla_breached` (Resolution target missed)
     * `escalated` (Priority escalated to Tier 2 / Admin)

5. **Priority** (Ticket Severity & SLA Definitions)
   * `id` (INTEGER, PK, AUTOINCREMENT)
   * `name` (TEXT, UNIQUE, NOT NULL)
   * *Allowed Values:*
     * `low` (SLA: 48h)
     * `normal` (SLA: 24h)
     * `high` (SLA: 4h)
     * `urgent` (SLA: 1h)

6. **Tickets** (Core entity with explicit relational foreign keys)
   * `id` (INTEGER, PK, AUTOINCREMENT)
   * `title` (TEXT, NOT NULL)
   * `description` (TEXT, NOT NULL)
   * `status` (TEXT: `'open'`, `'pending'`, `'solved'`, `'closed'`, `'sla_breached'`, `'escalated'`, DEFAULT `'open'`)
   * `priority` (TEXT: `'low'`, `'normal'`, `'high'`, `'urgent'`, DEFAULT `'normal'`)
   * `client_id` (INTEGER, NOT NULL, FK -> Client.id ON DELETE RESTRICT)
   * `agent_id` (INTEGER, NULLABLE, FK -> Agent.id ON DELETE SET NULL - Current assigned agent)
   * `is_escalated` (INTEGER, DEFAULT 0)
   * `attachment_path` (TEXT, NULLABLE)
   * `due_at` (TIMESTAMP, SLA resolution deadline based on priority)
   * `solved_at` (TIMESTAMP, NULLABLE)
   * `created_at` (TIMESTAMP DEFAULT CURRENT_TIMESTAMP)
   * `updated_at` (TIMESTAMP DEFAULT CURRENT_TIMESTAMP)

7. **Messages** (Threaded conversation with polymorphic sender & chronological ordering)
   * `id` (INTEGER, PK, AUTOINCREMENT)
   * `ticket_id` (INTEGER, NOT NULL, FK -> Tickets.id ON DELETE CASCADE)
   * `sender_id` (INTEGER, NOT NULL)
   * `sender_type` (TEXT: `'client'`, `'agent'`, `'admin'`, `'user'`, NOT NULL - Identifies author table)
   * `text` (TEXT, NOT NULL)
   * `visibility` (TEXT: `'public'`, `'internal'`, DEFAULT `'public'`)
   * `created_at` (TIMESTAMP DEFAULT CURRENT_TIMESTAMP)
   * *Ordering:* Always queried with `ORDER BY created_at ASC, id ASC`.

8. **Worksheet** (Purpose: Active Agent Queue, Workload Management & Assignment History)
   * `id` (INTEGER, PK, AUTOINCREMENT)
   * `ticket_id` (INTEGER, NOT NULL, FK -> Tickets.id ON DELETE CASCADE)
   * `agent_id` (INTEGER, FK -> Agent.id ON DELETE SET NULL)
   * `assigned_by` (INTEGER, NULLABLE, FK -> Agent.id)
   * `reason` (TEXT: `'round_robin'`, `'manual_reassign'`, `'escalation'`)
   * `status` (TEXT, NOT NULL)
   * `created_at` (TIMESTAMP DEFAULT CURRENT_TIMESTAMP)
   * *Purpose & Recommendation:* Decouples current ticket status from assignment history. When a ticket is reassigned or escalated, a new row is appended to Worksheet. This guarantees a complete audit of who held the ticket, enables per-agent active workload calculations, and ensures tickets can be reassigned without losing historical context.

9. **Audit Trail** (Append-only compliance log)
   * `id` (INTEGER, PK, AUTOINCREMENT)
   * `ticket_id` (INTEGER, NOT NULL, FK -> Tickets.id ON DELETE CASCADE)
   * `actor_type` (TEXT: `'user'`, `'agent'`, `'admin'`, `'system'`)
   * `actor_id` (INTEGER, NOT NULL; `0` for `system`)
   * `action` (TEXT: `'created'`, `'assigned'`, `'status_change'`, `'priority_change'`, `'priority_bumped'`, `'escalated'`, `'message_added'`)
   * *Immutable:* SQLite triggers `audit_no_update` / `audit_no_delete` abort any UPDATE or DELETE.
   * `old_value` (TEXT, NULLABLE)
   * `new_value` (TEXT, NULLABLE)
   * `created_at` (TIMESTAMP DEFAULT CURRENT_TIMESTAMP)

10. **System Settings** (Persistent runtime configuration)
   * `key` (TEXT, PK)
   * `value` (TEXT, NOT NULL)
   * *Used for:* `last_assigned_agent_id` for round-robin pointer persistence across server restarts.

11. **Sessions** (Login tokens for clients and agents)
   * `id` (INTEGER, PK, AUTOINCREMENT)
   * `token_hash` (TEXT, UNIQUE, NOT NULL - SHA-256 of the token; the raw token is never stored)
   * `user_type` (TEXT: `'client'`, `'agent'`, NOT NULL - which table `user_id` points to)
   * `user_id` (INTEGER, NOT NULL - `clients.id` or `agents.id`; no FK because it can point to either table)
   * `created_at` (TIMESTAMP DEFAULT CURRENT_TIMESTAMP)
   * `expires_at` (TIMESTAMP, NOT NULL - login time + 8 hours)
   * `revoked_at` (TIMESTAMP, NULLABLE - set on logout; NULL means still valid)
   * *Index:* `idx_sessions_user ON sessions(user_type, user_id)`
   * *Flow:* `POST /api/auth/login` checks the password hash and creates a session, returning the raw token once. Every request sends `Authorization: Bearer <token>`; the API hashes it and looks up a session that is not revoked and not expired (agents must also have `is_active = 1`), otherwise `401`. `POST /api/auth/logout` sets `revoked_at`.
   * *SQL:*
     ```sql
     CREATE TABLE IF NOT EXISTS sessions (
         id          INTEGER PRIMARY KEY AUTOINCREMENT,
         token_hash  TEXT NOT NULL UNIQUE,
         user_type   TEXT NOT NULL CHECK (user_type IN ('client', 'agent')),
         user_id     INTEGER NOT NULL,
         created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
         expires_at  TIMESTAMP NOT NULL,
         revoked_at  TIMESTAMP
     );
     CREATE INDEX IF NOT EXISTS idx_sessions_user ON sessions(user_type, user_id);
     ```

---

## Functional Requirements

### 1. Authentication & Login-Based Access Control
* **Authentication:** Passwords must be encrypted/hashed (never stored in plain text).
* **Role-Based Access Permissions:**
  * **Client:**
    * Authenticated by Client table.
    * Can view, list, and search only their own tickets (`client_id = current_client.id`).
    * Can create tickets (`POST /api/tickets`).
    * Can post public replies (`POST /api/tickets/{id}/messages` with `visibility = 'public'`).
    * Forbidden (`403`) from posting or viewing internal agent notes.
  * **Agent:**
    * Authenticated by Agent table (`role = 'agent'`).
    * Can view assigned tickets and the unassigned queue.
    * Assigned tickets automatically via round-robin or manual reassignment.
    * Can post public replies and private internal notes (`visibility = 'internal'`).
    * Can transition ticket status (`open` -> `pending` -> `solved`).
  * **Admin:**
    * Authenticated by Agent table (`role = 'admin'`).
    * Unrestricted access across all tickets, agents, reports, and escalations.
    * Can reassign tickets and trigger SLA escalation runs (`POST /api/escalations/run`).

---

### 2. Core Workflows & Business Rules

#### 1. User & Client Registration
* `POST /api/clients` with `name`, `email`, `password`. Validates input, encrypts password, returns 201.
* `POST /api/agents` (Admin only) with `name`, `email`, `password`, `role`. Returns 201.

#### 2. Create Ticket (Core)
* `POST /api/tickets` with `title`, `description`, `priority`.
* Calculates SLA `due_at` from priority:
  * `urgent`: 1 hour
  * `high`: 4 hours
  * `normal`: 24 hours
  * `low`: 48 hours
* Assigns next active agent via round-robin.
* Records ticket, inserts initial Worksheet row, writes Audit log (`action: 'created'`), returns 201.

#### 3. Assign / Reassign via Worksheet
* **Round-robin:** Cycles through active agents in ascending ID order, updating pointer in settings.
* **Manual Reassignment:** `POST /api/tickets/{id}/assign` with `agent_id`. Validates ticket is not closed, inserts new Worksheet row, updates ticket `agent_id`, writes Audit log. Pointer does not move.

#### 4. Threaded Conversation & Auto-Status
* `POST /api/tickets/{id}/messages` with `text`, `visibility`.
* Records `sender_type` (`client` vs `agent`).
* **Auto-Status Rules:**
  * Agent reply $\rightarrow$ auto-transitions status to `'pending'`.
  * Client reply $\rightarrow$ auto-transitions status to `'open'`.
  * Reply to `'closed'` ticket $\rightarrow$ rejected with `400 Bad Request`.
* Messages ordered strictly chronologically (`ORDER BY created_at ASC, id ASC`).

#### 5. SLA Breach & Escalation
* Periodic check or on-demand `POST /api/escalations/run`.
* For tickets where `due_at < NOW` and status is `'open'` or `'pending'`:
  * Updates status to `'sla_breached'` or `'escalated'`.
  * Bumps priority one level (`low` $\rightarrow$ `normal` $\rightarrow$ `high` $\rightarrow$ `urgent`).
  * Reassigns to Admin agent.
  * Records new Worksheet row and Audit entry.

---

## 3. Audit Trail: Deep Dive & Architectural Discussion

### Architecture & Design Philosophy
The **Audit Trail** was selected and prioritized as the core backend stretch goal for several key architectural reasons:
1. **Compliance & Non-Repudiation:** Enterprise support systems (such as Zendesk, ServiceNow) require strict accountability. Every state transition, ownership change, and escalation must have a verifiable author and timestamp.
2. **Separation of Operational State vs. Historical Ledger:** 
   - The `tickets` table represents current mutable state (`status`, `agent_id`, `priority`, `updated_at`).
   - The `audit` table functions as an **append-only, immutable event ledger**.
   - This prevents race conditions and makes system state verifiable from first principles.
3. **Debugging & Operational Visibility:** When troubleshooting routing anomalies or SLA escalations, developers and team leads can reconstruct the complete lifecycle of any ticket step-by-step.

---

### The 5 Core Audit Trail Elements
Every entry in the `audit` table records the following structured fields:

1. **`ticket_id` (INTEGER, FK -> Tickets.id):**
   - Links the event to the target ticket. Configured with `ON DELETE CASCADE` for referential integrity.
2. **`actor_type` (TEXT: `'client'`, `'agent'`, `'admin'`, `'system'`):**
   - Polymorphic indicator defining which subsystem or entity initiated the change.
   - `'system'` distinguishes automated cron jobs/daemons from human operators.
3. **`actor_id` (INTEGER):**
   - Identifier of the actor. Points to `clients.id` or `agents.id`.
   - Automated jobs (like the background SLA escalation worker) use `actor_id = 0`.
4. **`action` (TEXT):**
   - Explicit event taxonomy:
     - `'created'`: Initial ticket creation.
     - `'assigned'`: Round-robin or manual agent reassignment.
     - `'status_change'`: State lifecycle progression (`open`, `pending`, `solved`, `closed`).
     - `'priority_change'`: Manual priority change by an agent/admin (SLA deadline recalculated).
     - `'priority_bumped'`: Dynamic SLA elevation (system, when the SLA is breached).
     - `'escalated'`: Tier-2 or Admin reassignment due to breach.
     - `'message_added'`: Public reply or internal note (`new_value` = `public` / `internal`).
5. **Delta Tracking (`old_value` $\rightarrow$ `new_value`):**
   - Captures previous and new values explicitly (e.g., `old_value: "open"`, `new_value: "pending"` or `old_value: "Agent Priya (2)"`, `new_value: "Agent Rahul (3)"`).
   - Provides clear diffs without requiring queries against external snapshots.
6. **`created_at` (TIMESTAMP DEFAULT CURRENT_TIMESTAMP):**
   - Immutable ISO-8601 UTC timestamp of the transaction commit.

---

### Edge Handling, Concurrency & Q&A Defense

| Question / Challenge | Engineering Solution & Architectural Defense |
| :--- | :--- |
| **How do you guarantee atomicity?** | **Single SQLite Transaction:** Every state change and its corresponding audit record are wrapped inside the same database transaction (`BEGIN ... COMMIT`). If the audit write fails, the ticket mutation rolls back completely, ensuring zero drift between ticket state and audit history. |
| **How is audit immutability enforced?** | **Three layers:** (1) the API exposes **zero** `PUT`, `PATCH` or `DELETE` endpoints for audit (they return 405); (2) the Model layer only ever `INSERT`s into `audit`; (3) **the database itself** rejects changes: SQLite triggers `audit_no_update` / `audit_no_delete` abort any UPDATE or DELETE, even from a manual SQL session. |
| **Is it queryable?** | **Yes:** `GET /api/audit?ticket_id=&actor_type=&actor_id=&action=&since=&until=&limit=&offset=` (staff; agents only see their linked clients), newest first, with `actor_name` and `ticket_title` on every row. |
| **How are automated system actions tracked?** | **Explicit System Attribution:** Background cron jobs and the 60-second SLA escalation worker execute with `actor_type = 'system'` and `actor_id = 0`, ensuring transparent distinction between human agent actions and automated triggers. |
| **Who can view the audit trail (RBAC)?** | **Staff-Only Access:** The endpoint `GET /api/tickets/{id}/audit` is protected by role-based session middleware. Only authenticated `agent` and `admin` roles can query audit logs; client requesters are restricted with `403 Forbidden` to safeguard internal operational metrics and reassignment notes. |
| **What about read/write lock contention?** | **SQLite WAL Mode (`PRAGMA journal_mode = WAL`):** Enables continuous concurrent reads while background writes append new audit records without database locking bottlenecks. |

---

### 90-Second Demo Walkthrough Script

For evaluation and panel presentation, follow this crisp 90-second workflow to demonstrate the Audit Trail in action:

1. **Step 1: Create Ticket (0:00 - 0:15)**
   - Log in as client user (`aditi@acme.com`).
   - File a ticket: *"Payment gateway timeout on checkout"*, Priority: `urgent`.
   - **Show Audit Log:** Displays `action: 'created'`, `actor_type: 'client'`, `actor_id: 1`, assigned via round-robin to next active agent.

2. **Step 2: Agent Response & Auto-Status (0:15 - 0:35)**
   - Log in as assigned agent (`priya@demo.com`).
   - Post reply: *"Investigating server logs now. Can you share the transaction ID?"*
   - **Show Auto-Status:** Status automatically transitions from `open` $\rightarrow$ `pending`.
   - **Show Audit Log:** New audit entry logged: `action: 'status_change'`, `old_value: 'open'`, `new_value: 'pending'`.

3. **Step 3: Manual Reassignment (0:35 - 0:50)**
   - Reassign ticket from `Priya` to `Rahul` (`agent_id: 3`) with note *"Requires backend database inspection"*.
   - **Show Worksheet & Audit:** `action: 'assigned'`, `old_value: 'Priya (2)'`, `new_value: 'Rahul (3)'`. Worksheet logs new routing row.

4. **Step 4: SLA Escalation Trigger (0:50 - 1:10)**
   - Fast-forward or trigger escalation worker: `POST /api/escalations/run`.
   - **Show Background Attribution:** Ticket is flagged escalated (`is_escalated = 1`; status stays open/pending), priority bumps, ticket reassigns to Admin.
   - **Show Audit Log:** Entries `priority_bumped` (e.g. `high → urgent`) and `escalated` (`Priya Agent (2) → Admin Asha (1)`), both `actor_type: 'system'`, `actor_id: 0`.

5. **Step 5: Final Resolution & Audit Ledger Review (1:10 - 1:30)**
   - Agent resolves ticket (`solved`).
   - Open Audit Trail timeline view: demonstrate full chronological history showing the exact sequence of actors, timestamps, and state transitions from creation to resolution.

