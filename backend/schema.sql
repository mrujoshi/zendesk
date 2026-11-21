-- Mini-Zendesk SQLite Relational Schema
-- Supports separate User, Client, Agent tables with encrypted passwords,
-- polymorphic sender_type messages, explicit status table, worksheet assignment queue, and audit trail.

PRAGMA foreign_keys = ON;

-- 1. General User Table
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    password_hash TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Client Table (Requesters / Customers filing tickets)
CREATE TABLE IF NOT EXISTS clients (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Agent Table (Support staff & Admins resolving tickets)
CREATE TABLE IF NOT EXISTS agents (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    role TEXT NOT NULL CHECK(role IN ('admin', 'agent')),
    password_hash TEXT NOT NULL,
    is_active INTEGER NOT NULL DEFAULT 1 CHECK(is_active IN (0, 1)),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Status Table (Defined lifecycle & SLA breach / escalation states)
CREATE TABLE IF NOT EXISTS statuses (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL
);

-- Seed static statuses
INSERT OR IGNORE INTO statuses (name) VALUES 
('open'), ('pending'), ('solved'), ('closed'), ('sla_breached'), ('escalated');

-- 5. Tickets Table (Core entity with explicit foreign keys to client & current agent)
CREATE TABLE IF NOT EXISTS tickets (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'open' CHECK(status IN ('open', 'pending', 'solved', 'closed', 'sla_breached', 'escalated')),
    priority TEXT NOT NULL DEFAULT 'normal' CHECK(priority IN ('low', 'normal', 'high', 'urgent')),
    client_id INTEGER NOT NULL,
    agent_id INTEGER,
    is_escalated INTEGER NOT NULL DEFAULT 0 CHECK(is_escalated IN (0, 1)),
    attachment_path TEXT,
    due_at TIMESTAMP,
    solved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE RESTRICT,
    FOREIGN KEY (agent_id) REFERENCES agents(id) ON DELETE SET NULL
);

-- 6. Messages Table (Ordered conversation thread with sender_type)
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
    actor_type TEXT NOT NULL, -- 'client', 'agent', 'admin'
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

-- Indexes for high performance
CREATE INDEX IF NOT EXISTS idx_tickets_status ON tickets(status);
CREATE INDEX IF NOT EXISTS idx_tickets_agent ON tickets(agent_id);
CREATE INDEX IF NOT EXISTS idx_tickets_client ON tickets(client_id);
CREATE INDEX IF NOT EXISTS idx_tickets_priority ON tickets(priority);
CREATE INDEX IF NOT EXISTS idx_messages_ticket_order ON messages(ticket_id, created_at ASC, id ASC);
CREATE INDEX IF NOT EXISTS idx_worksheet_ticket ON worksheet(ticket_id);
CREATE INDEX IF NOT EXISTS idx_worksheet_agent ON worksheet(agent_id);
CREATE INDEX IF NOT EXISTS idx_audit_ticket ON audit(ticket_id);
