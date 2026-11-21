# Mini-Zendesk Entity-Relationship Diagram (ERD)

This document visualizes and describes the relational database architecture and the user flows of the **Mini-Zendesk** support ticketing system. It matches `backend/schema.sql` and the API in `backend-controller/`.

**The model in one line:** the **admin** sets everything up (clients, their users, agents, and which agents serve which client); **users** of a client raise tickets; **agents** linked to that client solve them; the **system** assigns and escalates automatically. Clients are companies and do not log in.

---

## 📊 Visual ERD (Mermaid)

```mermaid
erDiagram
    CLIENTS ||--o{ USERS : "employs (users.client_id)"
    CLIENTS ||--o{ TICKETS : "owns (tickets.client_id)"
    USERS ||--o{ TICKETS : "raises (tickets.user_id)"
    AGENTS ||--o{ TICKETS : "currently assigned (agent_id)"
    AGENTS ||--o{ AGENT_CLIENTS : "may serve"
    CLIENTS ||--o{ AGENT_CLIENTS : "served by"
    TICKETS ||--o{ MESSAGES : "contains (ticket_id)"
    TICKETS ||--o{ WORKSHEET : "assignment history (ticket_id)"
    AGENTS ||--o{ WORKSHEET : "assigned / assigned_by"
    TICKETS ||--o{ AUDIT : "change log (ticket_id)"
    USERS ||--o{ SESSIONS : "logs in (user_type=user)"
    AGENTS ||--o{ SESSIONS : "logs in (user_type=agent)"

    CLIENTS {
        int id PK "Auto Increment"
        string name "Company, e.g. Acme Corp"
        string email UK "Company contact email"
        string password_hash "Empty: clients do not log in"
        timestamp created_at "Created by admin"
    }

    USERS {
        int id PK "Auto Increment"
        int client_id FK "References CLIENTS.id (Restrict)"
        string name "Person at the client"
        string email UK "Login"
        string category "Job role, e.g. Manager"
        string password_hash "Salted PBKDF2"
        timestamp created_at "Created by admin"
    }

    AGENTS {
        int id PK "Auto Increment"
        string name "Support staff"
        string email UK "Login"
        string role "admin or agent"
        string password_hash "Salted PBKDF2"
        int is_active "1 = active, 0 = disabled"
        int client_id FK "Legacy, unused: access is AGENT_CLIENTS"
        timestamp created_at "Created by admin"
    }

    AGENT_CLIENTS {
        int agent_id PK "References AGENTS.id (Cascade)"
        int client_id PK "References CLIENTS.id (Cascade)"
        timestamp created_at "Link created by admin"
    }

    TICKETS {
        int id PK "Auto Increment"
        string title "Subject"
        string description "Issue details"
        string status "open, pending, solved, closed"
        string priority "low, normal, high, urgent"
        int client_id FK "References CLIENTS.id (Restrict)"
        int user_id FK "References USERS.id, who raised it"
        int agent_id FK "References AGENTS.id, current owner (nullable)"
        int is_escalated "0 or 1: escalation is a flag, not a status"
        string attachment_path "Nullable"
        timestamp due_at "SLA deadline = created_at + SLA"
        timestamp solved_at "Set on solve, cleared on reopen"
        timestamp created_at "Creation"
        timestamp updated_at "Last change"
    }

    MESSAGES {
        int id PK "Auto Increment"
        int ticket_id FK "References TICKETS.id (Cascade)"
        int sender_id "users.id or agents.id"
        string sender_type "user or agent"
        string text "Message content"
        string visibility "public or internal (staff only)"
        timestamp created_at "Ordered chronologically"
    }

    WORKSHEET {
        int id PK "Auto Increment"
        int ticket_id FK "References TICKETS.id (Cascade)"
        int agent_id FK "Agent who got the ticket"
        int assigned_by FK "Agent who did it, NULL = system"
        string reason "round_robin, manual_reassign, escalation"
        string status "Ticket status at handoff"
        timestamp created_at "Handoff time"
    }

    AUDIT {
        int id PK "Append-only: triggers block UPDATE and DELETE"
        int ticket_id FK "References TICKETS.id (Cascade)"
        string actor_type "user, agent, admin, system"
        int actor_id "0 for system"
        string action "created, assigned, status_change, priority_change, priority_bumped, escalated, message_added"
        string old_value "Before"
        string new_value "After"
        timestamp created_at "When"
    }

    SESSIONS {
        int id PK "Auto Increment"
        string token_hash UK "SHA-256 of bearer token"
        string user_type "user or agent"
        int user_id "users.id or agents.id"
        timestamp created_at "Login time"
        timestamp expires_at "Login time + 8 hours"
        timestamp revoked_at "Set on logout"
    }

    SYSTEM_SETTINGS {
        string key PK "e.g. last_assigned_agent_id"
        string value "Round-robin pointer"
    }
```

`statuses` and `priorities` lookup tables also exist in the schema; the API uses the fixed lists in `backend-controller/constants.py`.

---

## 🔗 Key Relationships & Relational Design

### 1. Clients, users and tickets
* **`CLIENTS` (1) → `USERS` (N):** every user belongs to exactly one client (`users.client_id`, `ON DELETE RESTRICT`).
* **`CLIENTS` (1) → `TICKETS` (N):** a ticket belongs to the client of the user who raised it; colleagues at the same client can see it too.
* **`USERS` (1) → `TICKETS` (N):** `tickets.user_id` records who raised it.

### 2. Agent ↔ client access (`AGENT_CLIENTS`)
* **Many-to-many:** an agent can serve many clients, a client can have many agents. Only the admin changes it (`PUT /api/agents/{id}/clients`).
* An agent sees and works only on tickets of linked clients; anything else is **404**. Admins see everything.
* Round-robin and manual reassign only pick agents linked to the ticket's client. No linked agent → the ticket stays unassigned for the admin.
* `agents.client_id` is a leftover column; the API does not use it.

### 3. Threaded messages (`TICKETS` → `MESSAGES`)
* Ordered back-and-forth, indexed on `(ticket_id, created_at, id)`.
* `(sender_type, sender_id)` says whether a user or an agent wrote it. Internal notes are never shown to users.

### 4. Assignment history (`TICKETS` → `WORKSHEET`)
* The current owner is `tickets.agent_id`; every assignment also appends a `WORKSHEET` row with `reason` and `assigned_by` (NULL = system).

### 5. Append-only audit trail (`TICKETS` → `AUDIT`)
* Every change is written in the **same transaction** as the change itself; if the audit insert fails, the change rolls back.
* SQLite triggers `audit_no_update` / `audit_no_delete` abort any UPDATE or DELETE.
* System actions (round-robin, escalation) use `actor_type = 'system'`, `actor_id = 0`.

### 6. Sessions
* Only the SHA-256 hash of the token is stored; tokens expire after 8 hours and logout revokes them.
* `user_type` is `user` or `agent` (admins are agents with `role = 'admin'`).
* 5 wrong passwords for an account → **429** for 15 minutes.

---

## 👥 Role Associations

How each role connects to the data. The **admin** sets up clients, users, agents and access; **users** raise tickets for their client; **agents** work on their linked clients' tickets; the **system** assigns and escalates automatically.

```mermaid
flowchart LR
    subgraph Roles
        AD["🛡️ Admin<br/>(Asha)"]
        U["👤 User<br/>(Aditi @ Acme)"]
        A["🎧 Agent<br/>(Priya)"]
        SYS["⚙️ System<br/>(server, id 0)"]
    end

    subgraph Setup["Set up by the admin"]
        CL[("CLIENTS<br/>Acme, Globex")]
        US[("USERS")]
        AG[("AGENTS")]
        AC[("AGENT_CLIENTS")]
    end

    subgraph Work["Ticket data"]
        T[("TICKETS")]
        M[("MESSAGES")]
        W[("WORKSHEET")]
        AU[("AUDIT")]
    end

    AD -- "creates" --> CL
    AD -- "creates users for a client" --> US
    AD -- "creates" --> AG
    AD -- "links agents to clients" --> AC
    AD -- "sees all, gets escalations" --> T

    US -- "belongs to" --> CL
    U -- "logs in as user" --> US
    U -- "raises for own client" --> T
    U -- "public replies" --> M

    A -- "logs in as agent" --> AG
    AC -- "decides which tickets" --> A
    A -- "status, priority, reassign" --> T
    A -- "replies + internal notes" --> M

    SYS -- "round-robin among linked agents" --> W
    SYS -- "escalates overdue every 60 s" --> T

    T -- "1 : N" --> M
    T -- "1 : N" --> W
    T -- "1 : N every change" --> AU
```

### Role permissions

| Action | User | Agent | Admin | System |
|---|:---:|:---:|:---:|:---:|
| Log in | ✅ (`user`) | ✅ (`agent`) | ✅ (`agent`) | — |
| Create clients, users, agents | ❌ | ❌ | ✅ | — |
| Link agents to clients | ❌ | ❌ | ✅ | — |
| See tickets | own client's | linked clients' | all | — |
| Create ticket | ✅ | ❌ | ❌ | — |
| Public reply | ✅ | ✅ | ✅ | — |
| Internal note | ❌ | ✅ | ✅ | — |
| Change status | ❌ | ✅ | ✅ | — |
| Change priority | ❌ | ✅ | ✅ | ✅ when SLA breached |
| Assign / reassign | ❌ | ✅ linked agents only | ✅ linked agents only | ✅ round-robin |
| Receives tickets | — | round-robin | escalations | — |
| Audit trail | ❌ | ✅ linked clients only | ✅ all | — |
| Daily report | ❌ | ✅ (company-wide numbers) | ✅ | — |
| Run escalation now | ❌ | ❌ | ✅ | ✅ every 60 s |

Enforced in `backend-controller/deps.py` (`require_staff`, `require_admin`) and `scope_client_ids` / `get_or_404` in `controllers/tickets.py`. A ticket outside your scope returns **404**, so the API never reveals that it exists.

---

## 🛠️ Setup Flow (admin)

What has to exist before a user can raise a ticket.

```mermaid
sequenceDiagram
    autonumber
    actor AD as Admin (Asha)
    participant MZ as Mini-Zendesk API

    AD->>MZ: POST /api/clients (Acme Corp)
    AD->>MZ: POST /api/users (Aditi, client = Acme)
    AD->>MZ: POST /api/agents (Priya, role = agent)
    AD->>MZ: PUT /api/agents/{priya}/clients [Acme, ...]
    Note over MZ: Acme is now served by Priya.<br/>A client with no linked agent: tickets wait unassigned for the admin.
```

---

## 🔄 User Flow

One ticket from creation to close, showing who does what and how Mini-Zendesk reacts.

```mermaid
sequenceDiagram
    autonumber
    actor U as User (Aditi @ Acme)
    participant MZ as Mini-Zendesk<br/>(React → FastAPI → SQLite)
    actor A as Agent (Priya, linked to Acme)
    actor AD as Admin (Asha)

    U->>MZ: Log in (email, password, user_type = user)
    MZ-->>U: Bearer token (8 h); 5 wrong passwords = 429 for 15 min
    U->>MZ: Create ticket (title, description, priority)
    MZ->>MZ: status = open, due_at = now + SLA
    MZ->>A: Round-robin among agents linked to Acme
    A->>MZ: Public reply "Can you share the transaction ID?"
    MZ->>MZ: status = pending (waiting on the user)
    U->>MZ: Reply "TXN-12345"
    MZ->>MZ: status = open (agent's turn)
    A->>MZ: Internal note (the user never sees it)

    alt SLA deadline passes
        MZ->>MZ: Escalation job: priority +1, is_escalated = 1
        MZ->>AD: Move ticket to admin
        AD->>MZ: Reply and mark solved
    else Solved in time
        A->>MZ: Mark solved
    end
    MZ->>MZ: status = solved, solved_at set

    opt User says it is still broken
        U->>MZ: Reply on solved ticket
        MZ->>MZ: status = open (reopened, solved_at cleared)
    end

    A->>MZ: Close ticket
    MZ->>MZ: status = closed (final, no more replies)
    Note over MZ: Every step is one AUDIT row: who, what, old → new, when
```

### Ticket lifecycle

```mermaid
stateDiagram-v2
    [*] --> open: user creates
    open --> pending: agent replies / sets pending
    pending --> open: user replies / agent sets open
    open --> solved: agent solves
    pending --> solved: agent solves
    solved --> open: user replies (reopen)
    solved --> closed: agent closes
    closed --> [*]

    note right of open
        Escalation is a flag (is_escalated),
        not a status: priority +1, moved to admin
        when due_at passes on open / pending.
    end note
```

Any move not shown is rejected with **400**. A reply on a closed ticket is rejected as well. If two agents change the same ticket at the same moment, the second gets a clear **400** (the read, rule check and write run in one locked transaction).

### Audit trail of the flow above

| Actor | action | old → new |
|---|---|---|
| Aditi (user) | `created` | → open |
| System (0) | `assigned` | → Priya Agent (2) |
| Priya (agent) | `message_added` | → public |
| Priya (agent) | `status_change` | open → pending |
| Aditi (user) | `message_added` | → public |
| Aditi (user) | `status_change` | pending → open |
| Priya (agent) | `message_added` | → internal |
| System (0) | `priority_bumped` | high → urgent |
| System (0) | `escalated` | Priya Agent (2) → Admin Asha (1) |
| Asha (admin) | `status_change` | open → solved |
