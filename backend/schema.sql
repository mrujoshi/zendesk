-- Mini-Zendesk SQLite Relational Schema
-- Clients (companies), Users (people at a client), Agents (staff) with encrypted passwords,
-- agent<->client access,
-- polymorphic sender_type messages, explicit status table, worksheet assignment queue, and audit trail.

PRAGMA foreign_keys = ON;

-- 1. Client Table (Companies / accounts that raise tickets). Clients don't log in;
--    their users do. password_hash is kept for compatibility and left empty ('') for new clients.
CREATE TABLE IF NOT EXISTS clients (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. User Table (People who log in and raise tickets). Every user belongs to exactly one client,
--    and can only see that client's tickets.
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    client_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    category TEXT NOT NULL DEFAULT 'Employee',   -- job role at the client, e.g. 'Manager', 'Finance'
    password_hash TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE RESTRICT
);

-- 3. Agent Table (Support staff & Admins resolving tickets)
CREATE TABLE IF NOT EXISTS agents (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    role TEXT NOT NULL CHECK(role IN ('admin', 'agent')),
    password_hash TEXT NOT NULL,
    is_active INTEGER NOT NULL DEFAULT 1 CHECK(is_active IN (0, 1)),
    client_id INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL
);

-- 4. Status Table (Defined lifecycle & SLA breach / escalation states)
CREATE TABLE IF NOT EXISTS statuses (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL
);

-- Seed static statuses
INSERT OR IGNORE INTO statuses (name) VALUES 
('open'), ('pending'), ('solved'), ('closed'), ('sla_breached'), ('escalated');

-- 5. Priority Table (High, low, normal, urgent)
CREATE TABLE IF NOT EXISTS priorities (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL
);

-- Seed static priorities
INSERT OR IGNORE INTO priorities (name) VALUES 
('low'), ('normal'), ('high'), ('urgent');

-- 6. Tickets Table (Core entity with explicit foreign keys to client & current agent)
CREATE TABLE IF NOT EXISTS tickets (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'open' CHECK(status IN ('open', 'pending', 'solved', 'closed', 'sla_breached', 'escalated')),
    priority TEXT NOT NULL DEFAULT 'normal' CHECK(priority IN ('low', 'normal', 'high', 'urgent')),
    client_id INTEGER NOT NULL,              -- the client (company) the ticket belongs to
    user_id INTEGER,                         -- the user who raised it (NULL for legacy rows)
    agent_id INTEGER,
    is_escalated INTEGER NOT NULL DEFAULT 0 CHECK(is_escalated IN (0, 1)),
    attachment_path TEXT,
    due_at TIMESTAMP,
    solved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE RESTRICT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (agent_id) REFERENCES agents(id) ON DELETE SET NULL
);

-- 7. Messages Table (Ordered conversation thread with sender_type)
CREATE TABLE IF NOT EXISTS messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    ticket_id INTEGER NOT NULL,
    sender_id INTEGER NOT NULL,
    sender_type TEXT NOT NULL CHECK(sender_type IN ('client', 'agent', 'admin', 'user')),
    text TEXT NOT NULL,
    visibility TEXT NOT NULL DEFAULT 'public' CHECK(visibility IN ('public', 'internal')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ticket_id) REFERENCES tickets(id) ON DELETE CASCADE
);

-- 7. Worksheet Table (Active Agent Queue, Workload Tracking & Assignment History)
CREATE TABLE IF NOT EXISTS worksheet (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    ticket_id INTEGER NOT NULL,
    agent_id INTEGER,
    assigned_by INTEGER,
    reason TEXT, -- e.g. 'round_robin', 'manual_reassign', 'escalation'
    status TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ticket_id) REFERENCES tickets(id) ON DELETE CASCADE,
    FOREIGN KEY (agent_id) REFERENCES agents(id) ON DELETE SET NULL,
    FOREIGN KEY (assigned_by) REFERENCES agents(id) ON DELETE SET NULL
);

-- 8. Audit Trail Table (Append-only change log)
CREATE TABLE IF NOT EXISTS audit (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    ticket_id INTEGER NOT NULL,
    actor_type TEXT NOT NULL, -- 'user', 'agent', 'admin', 'system'
    actor_id INTEGER NOT NULL,
    action TEXT NOT NULL,     -- 'created', 'assigned', 'status_change', 'message_added', 'escalated'
    old_value TEXT,
    new_value TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ticket_id) REFERENCES tickets(id) ON DELETE CASCADE
);

-- 9. System Settings Table (Key-value store, e.g. last_assigned_agent_id)
CREATE TABLE IF NOT EXISTS system_settings (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
);

-- 10. Sessions Table (Login Bearer Tokens for Clients and Agents)
CREATE TABLE IF NOT EXISTS sessions (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    token_hash  TEXT NOT NULL UNIQUE,      -- SHA-256 of the token; raw token never stored
    user_type   TEXT NOT NULL CHECK (user_type IN ('user', 'agent')),
    user_id     INTEGER NOT NULL,          -- references users.id or agents.id
    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at  TIMESTAMP NOT NULL,        -- login time + 8 hours
    revoked_at  TIMESTAMP                  -- set on logout; NULL = active
);

-- 11. Agent <-> Client access (many-to-many, configured by admins)
-- An agent (role 'agent') sees and works only on tickets of clients linked here.
-- Admins are not limited. A client with no linked agents: tickets stay unassigned for the admin.
CREATE TABLE IF NOT EXISTS agent_clients (
    agent_id    INTEGER NOT NULL,
    client_id   INTEGER NOT NULL,
    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (agent_id, client_id),
    FOREIGN KEY (agent_id) REFERENCES agents(id) ON DELETE CASCADE,
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE
);

-- Audit trail is append-only, enforced by the database itself (not just by the API):
-- any UPDATE or DELETE on an audit row is aborted. (seed.py rebuilds tables with DROP, which is allowed.)
CREATE TRIGGER IF NOT EXISTS audit_no_update BEFORE UPDATE ON audit
BEGIN
    SELECT RAISE(ABORT, 'audit trail is append-only: rows cannot be updated');
END;
CREATE TRIGGER IF NOT EXISTS audit_no_delete BEFORE DELETE ON audit
BEGIN
    SELECT RAISE(ABORT, 'audit trail is append-only: rows cannot be deleted');
END;

-- Indexes for high performance
CREATE INDEX IF NOT EXISTS idx_tickets_status ON tickets(status);
CREATE INDEX IF NOT EXISTS idx_tickets_agent ON tickets(agent_id);
CREATE INDEX IF NOT EXISTS idx_tickets_client ON tickets(client_id);
CREATE INDEX IF NOT EXISTS idx_tickets_user ON tickets(user_id);
CREATE INDEX IF NOT EXISTS idx_users_client ON users(client_id);
CREATE INDEX IF NOT EXISTS idx_tickets_priority ON tickets(priority);
CREATE INDEX IF NOT EXISTS idx_messages_ticket_order ON messages(ticket_id, created_at ASC, id ASC);
CREATE INDEX IF NOT EXISTS idx_worksheet_ticket ON worksheet(ticket_id);
CREATE INDEX IF NOT EXISTS idx_worksheet_agent ON worksheet(agent_id);
CREATE INDEX IF NOT EXISTS idx_audit_ticket ON audit(ticket_id);
CREATE INDEX IF NOT EXISTS idx_audit_created ON audit(created_at);
CREATE INDEX IF NOT EXISTS idx_sessions_user ON sessions(user_type, user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_lookup ON sessions(token_hash, revoked_at, expires_at);
CREATE INDEX IF NOT EXISTS idx_agent_clients_client ON agent_clients(client_id);
CREATE INDEX IF NOT EXISTS idx_agents_client ON agents(client_id);
