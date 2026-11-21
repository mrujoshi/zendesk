# Mini-Zendesk Entity-Relationship Diagram (ERD)

This document visualizes and describes the complete relational database architecture for the **Mini-Zendesk** support ticketing system.

---

## 📊 Visual ERD (Mermaid)

```mermaid
erDiagram
    CLIENTS ||--o{ TICKETS : "files (client_id)"
    AGENTS ||--o{ TICKETS : "assigned to (agent_id)"
    CLIENTS ||--o{ AGENTS : "dedicated agent (client_id)"
    TICKETS ||--o{ MESSAGES : "contains (ticket_id)"
    TICKETS ||--o{ WORKSHEET : "tracked in (ticket_id)"
    AGENTS ||--o{ WORKSHEET : "assigned to (agent_id)"
    TICKETS ||--o{ AUDIT : "logged in (ticket_id)"
    CLIENTS ||--o{ SESSIONS : "authenticates (user_type=client)"
    AGENTS ||--o{ SESSIONS : "authenticates (user_type=agent)"

    CLIENTS {
        int id PK "Auto Increment"
        string name "Company / Organization"
        string email UK "Unique Login"
        string password_hash "Encrypted Password"
        timestamp created_at "Registration time"
    }

    AGENTS {
        int id PK "Auto Increment"
        string name "Support Staff Name"
        string email UK "Unique Login"
        string role "admin | agent"
        string password_hash "Encrypted Password"
        int is_active "1=Active, 0=Disabled"
        int client_id FK "References CLIENTS.id (Nullable)"
        timestamp created_at "Registration time"
    }

    USERS {
        int id PK "Auto Increment"
        string name "Internal User Name"
        string category "Department / Role"
        string password_hash "Encrypted Password"
        timestamp created_at "Registration time"
    }

    STATUSES {
        int id PK "Auto Increment"
        string name UK "open, pending, solved, closed, sla_breached, escalated"
    }

    PRIORITIES {
        int id PK "Auto Increment"
        string name UK "low (48h), normal (24h), high (4h), urgent (1h)"
    }

    TICKETS {
        int id PK "Auto Increment"
        string title "Subject"
        string description "Issue details"
        string status "open, pending, solved, closed, etc."
        string priority "low, normal, high, urgent"
        int client_id FK "References CLIENTS.id"
        int agent_id FK "References AGENTS.id (Nullable)"
        int is_escalated "0=Normal, 1=Escalated"
        string attachment_path "Nullable path"
        timestamp due_at "SLA Target Deadline"
        timestamp solved_at "Nullable resolution timestamp"
        timestamp created_at "Creation timestamp"
        timestamp updated_at "Last mutation timestamp"
    }

    MESSAGES {
        int id PK "Auto Increment"
        int ticket_id FK "References TICKETS.id (Cascade)"
        int sender_id "Polymorphic Sender ID"
        string sender_type "client | agent | admin | user"
        string text "Message content"
        string visibility "public | internal"
        timestamp created_at "Ordered chronologically"
    }

    WORKSHEET {
        int id PK "Auto Increment"
        int ticket_id FK "References TICKETS.id (Cascade)"
        int agent_id FK "References AGENTS.id"
        int assigned_by FK "References AGENTS.id"
        string reason "round_robin | manual_reassign | escalation"
        string status "Ticket status at handoff"
        timestamp created_at "Handoff timestamp"
    }

    AUDIT {
        int id PK "Auto Increment (Immutable)"
        int ticket_id FK "References TICKETS.id (Cascade)"
        string actor_type "client | agent | admin | system"
        int actor_id "Actor ID (0 for system)"
        string action "created | assigned | status_change | escalated"
        string old_value "Nullable state before mutation"
        string new_value "Nullable state after mutation"
        timestamp created_at "Event timestamp"
    }

    SESSIONS {
        int id PK "Auto Increment"
        string token_hash UK "SHA-256 of Bearer Token"
        string user_type "client | agent"
        int user_id "Polymorphic ID (clients.id or agents.id)"
        timestamp created_at "Login time"
        timestamp expires_at "Login time + 8 hours"
        timestamp revoked_at "Nullable (Set on logout)"
    }

    SYSTEM_SETTINGS {
        string key PK "Configuration Key"
        string value "Configuration Value"
    }
```

---

## 🔗 Key Relationships & Relational Design

### 1. Tickets $\leftrightarrow$ Clients & Agents
* **`CLIENTS` (1) $\rightarrow$ `TICKETS` (N):** Every ticket must be created by a valid client (`client_id` with `FOREIGN KEY ... ON DELETE RESTRICT`).
* **`AGENTS` (1) $\rightarrow$ `TICKETS` (N):** Tickets are assigned to support agents (`agent_id` with `FOREIGN KEY ... ON DELETE SET NULL`). `agent_id` is nullable to cleanly represent unassigned tickets in the incoming queue.
* **`CLIENTS` (1) $\rightarrow$ `AGENTS` (N):** An agent can have a dedicated primary client assigned via `client_id` (`FOREIGN KEY ... ON DELETE SET NULL`). Nullable for general/global pool agents.

### 2. Threaded Messages (`TICKETS` $\rightarrow$ `MESSAGES`)
* **`TICKETS` (1) $\rightarrow$ `MESSAGES` (N):** A ticket contains an ordered stream of back-and-forth messages (`ticket_id` with `ON DELETE CASCADE`).
* **Polymorphic Sender:** Uses composite `(sender_id, sender_type)` to identify whether the author is a Client, Agent, or Admin without identity collisions.
* **Indexed Ordering:** Indexed on `(ticket_id, created_at ASC, id ASC)` to guarantee lightning-fast conversation rendering.

### 3. Queue & Assignment History (`TICKETS` $\rightarrow$ `WORKSHEET`)
* **Append-Only Assignment Queue:** Rather than overwriting assignments destructively, every assignment change appends a row to `WORKSHEET`.
* Tracks `assigned_by`, `reason` (`'round_robin'`, `'manual_reassign'`, `'escalation'`), and `status` at the moment of assignment, enabling live agent workload calculations.

### 4. Append-Only Audit Trail (`TICKETS` $\rightarrow$ `AUDIT`)
* **Complete Event Sourcing:** Logs every ticket creation, status transition, agent reassignment, and SLA escalation with `old_value` $\rightarrow$ `new_value` diffs.
* **System Actors:** Automatically records `actor_type = 'system'`, `actor_id = 0` for automated background jobs (round-robin assignment and SLA escalation), because `actor_id` is `NOT NULL`.

### 5. Token Authentication Sessions (`SESSIONS`)
* **Hashed Storage:** Stores only the SHA-256 `token_hash` of the bearer token; raw tokens are never persisted in the database.
* **Polymorphic Link:** Authenticates both Clients and Agents (including Admins) via `user_type` and `user_id`.
* **State Invalidation:** Fast verification via `token_hash` where `revoked_at IS NULL AND expires_at > NOW`.

---

## 👥 Role Associations

How each role connects to the data. A **client** raises tickets, an **agent** owns them, an **admin** receives escalations, and the **system** assigns and escalates automatically.

```mermaid
flowchart LR
    subgraph Roles
        C["👤 Client<br/>(Acme Corp)"]
        A["🎧 Agent<br/>(Priya)"]
        AD["🛡️ Admin<br/>(Asha)"]
        SYS["⚙️ System<br/>(server, id 0)"]
    end

    subgraph Data
        S[("SESSIONS")]
        T[("TICKETS")]
        M[("MESSAGES")]
        W[("WORKSHEET")]
        AU[("AUDIT")]
        SET[("SYSTEM_SETTINGS")]
    end

    C -- "login (user_type=client)" --> S
    A -- "login (user_type=agent)" --> S
    AD -- "login (user_type=agent)" --> S

    C -- "raises · client_id" --> T
    C -- "public replies on own tickets" --> M

    A -- "owns · agent_id (round-robin)" --> T
    A -- "public replies + internal notes" --> M
    A -- "status · priority · reassign" --> T

    AD -- "receives escalated tickets" --> T
    AD -- "everything an agent can + create agents" --> T

    SYS -- "round-robin pointer" --> SET
    SYS -- "auto-assign on create" --> W
    SYS -- "escalate every 60 s" --> T

    T -- "1 : N" --> M
    T -- "1 : N assignment history" --> W
    T -- "1 : N change log" --> AU
```

### Role permissions

| Action | Client | Agent | Admin | System |
|---|:---:|:---:|:---:|:---:|
| Log in | ✅ | ✅ | ✅ | — |
| See tickets | own only | all | all | — |
| Create ticket | ✅ | ❌ | ❌ | — |
| Public reply | ✅ own | ✅ | ✅ | — |
| Internal note | ❌ | ✅ | ✅ | — |
| Change status | ❌ | ✅ | ✅ | — |
| Change priority | ❌ | ✅ | ✅ | ✅ escalation |
| Assign / reassign | ❌ | ✅ | ✅ | ✅ round-robin |
| Receives tickets | — | round-robin | escalations | — |
| Audit trail & daily report | ❌ | ✅ | ✅ | — |
| Create agents | ❌ | ❌ | ✅ | — |
| Run escalation | ❌ | ❌ | ✅ | ✅ every 60 s |

Enforced in `backend-controller/deps.py` (`require_staff`, `require_admin`). A client requesting another client's ticket gets **404**, so the API never reveals that it exists.

---

## 🔄 User Flow

One ticket from creation to close, showing who does what and how Mini-Zendesk reacts.

```mermaid
sequenceDiagram
    autonumber
    actor C as Client (Acme)
    participant MZ as Mini-Zendesk<br/>(React → FastAPI → SQLite)
    actor A as Agent (Priya)
    actor AD as Admin (Asha)

    C->>MZ: Log in (email, password, user_type=client)
    MZ-->>C: Bearer token (8 h session)
    C->>MZ: Create ticket (title, description, priority)
    MZ->>MZ: status = open, due_at = now + SLA
    MZ->>A: Round-robin: assign to next active agent
    A->>MZ: Public reply "Please send a screenshot"
    MZ->>MZ: status = pending (waiting on client)
    C->>MZ: Reply with screenshot
    MZ->>MZ: status = open (agent's turn)
    A->>MZ: Internal note (client never sees it)

    alt SLA deadline passes
        MZ->>MZ: Escalation job: priority +1, is_escalated = 1
        MZ->>AD: Move ticket to admin
        AD->>MZ: Reply and mark solved
    else Solved in time
        A->>MZ: Mark solved
    end
    MZ->>MZ: status = solved, solved_at set

    opt Client says it is still broken
        C->>MZ: Reply on solved ticket
        MZ->>MZ: status = open (reopened, solved_at cleared)
    end

    A->>MZ: Close ticket
    MZ->>MZ: status = closed (final, no more replies)
    Note over MZ: Every step is appended to AUDIT (who, what, old → new, when)
```

### Ticket lifecycle

```mermaid
stateDiagram-v2
    [*] --> open: client creates
    open --> pending: agent replies / sets pending
    pending --> open: client replies / agent sets open
    open --> solved: agent solves
    pending --> solved: agent solves
    solved --> open: client replies (reopen)
    solved --> closed: agent closes
    closed --> [*]

    note right of open
        Escalation is a flag (is_escalated),
        not a status: priority +1, moved to admin
        when due_at passes on open / pending.
    end note
```

Any move not shown is rejected with **400**. A reply on a closed ticket is rejected as well.
