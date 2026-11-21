-- Mini-Zendesk SQLite Schema
-- High-performance relational ticketing schema with foreign keys enabled

PRAGMA foreign_keys = ON;

-- 1. Users Table (Identity, Login, Roles)
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL DEFAULT '',
    role TEXT NOT NULL CHECK(role IN ('client', 'agent', 'admin')),
    is_active INTEGER NOT NULL DEFAULT 1 CHECK(is_active IN (0, 1)),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Tickets Table
CREATE TABLE IF NOT EXISTS tickets (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'open' CHECK(status IN ('open', 'pending', 'solved', 'closed')),
    priority TEXT NOT NULL DEFAULT 'medium' CHECK(priority IN ('low', 'medium', 'high', 'urgent')),
    requester_id INTEGER NOT NULL,
    assignee_id INTEGER,
    due_at TIMESTAMP,
    attachment_url TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (requester_id) REFERENCES users(id) ON DELETE RESTRICT,
    FOREIGN KEY (assignee_id) REFERENCES users(id) ON DELETE SET NULL
);

-- 3. Messages / Comments Table (Threaded conversation per ticket)
CREATE TABLE IF NOT EXISTS messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    ticket_id INTEGER NOT NULL,
    sender_id INTEGER NOT NULL,
    text TEXT NOT NULL,
    visibility TEXT NOT NULL DEFAULT 'public' CHECK(visibility IN ('public', 'internal')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ticket_id) REFERENCES tickets(id) ON DELETE CASCADE,
    FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE RESTRICT
);

-- 4. Worksheet Table (Active agent assignment & workload queue)
CREATE TABLE IF NOT EXISTS worksheet (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    ticket_id INTEGER NOT NULL,
    agent_id INTEGER,
    status TEXT NOT NULL,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ticket_id) REFERENCES tickets(id) ON DELETE CASCADE,
    FOREIGN KEY (agent_id) REFERENCES users(id) ON DELETE SET NULL
);

-- 5. Audit Trail / Ticket Events (Append-only change log)
CREATE TABLE IF NOT EXISTS ticket_events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    ticket_id INTEGER NOT NULL,
    user_id INTEGER,
    event_type TEXT NOT NULL, -- 'created', 'assigned', 'reassigned', 'status_change', 'message_added', 'escalated'
    old_value TEXT,
    new_value TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ticket_id) REFERENCES tickets(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

-- 6. System Settings (e.g. tracks last_assigned_agent_id for persistent round-robin)
CREATE TABLE IF NOT EXISTS system_settings (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_tickets_status ON tickets(status);
CREATE INDEX IF NOT EXISTS idx_tickets_assignee ON tickets(assignee_id);
CREATE INDEX IF NOT EXISTS idx_tickets_requester ON tickets(requester_id);
CREATE INDEX IF NOT EXISTS idx_tickets_priority ON tickets(priority);
CREATE INDEX IF NOT EXISTS idx_messages_ticket ON messages(ticket_id);
CREATE INDEX IF NOT EXISTS idx_worksheet_agent ON worksheet(agent_id);
CREATE INDEX IF NOT EXISTS idx_events_ticket ON ticket_events(ticket_id);
