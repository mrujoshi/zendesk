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

2. **Client** (External Requesters / Customers filing tickets)
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
   * `actor_type` (TEXT: `'client'`, `'agent'`, `'admin'`)
   * `actor_id` (INTEGER, NOT NULL)
   * `action` (TEXT: `'created'`, `'assigned'`, `'status_change'`, `'message_added'`, `'escalated'`)
   * `old_value` (TEXT, NULLABLE)
   * `new_value` (TEXT, NULLABLE)
   * `created_at` (TIMESTAMP DEFAULT CURRENT_TIMESTAMP)

10. **System Settings** (Persistent runtime configuration)
   * `key` (TEXT, PK)
   * `value` (TEXT, NOT NULL)
   * *Used for:* `last_assigned_agent_id` for round-robin pointer persistence across server restarts.

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
