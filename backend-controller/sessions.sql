-- Add to backend/schema.sql (Model). Login sessions for clients and agents.
-- clients and agents are separate tables, so user_type says which one user_id points to
-- (that is why there is no FOREIGN KEY on user_id).

CREATE TABLE IF NOT EXISTS sessions (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    token_hash  TEXT NOT NULL UNIQUE,      -- SHA-256 of the token; the raw token is never stored
    user_type   TEXT NOT NULL CHECK (user_type IN ('client', 'agent')),
    user_id     INTEGER NOT NULL,          -- clients.id or agents.id
    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at  TIMESTAMP NOT NULL,        -- login time + 8 hours
    revoked_at  TIMESTAMP                  -- set on logout; NULL = still valid
);

CREATE INDEX IF NOT EXISTS idx_sessions_user ON sessions(user_type, user_id);

-- Lookup used on every request (agents must also be active):
-- SELECT * FROM sessions
--  WHERE token_hash = ? AND revoked_at IS NULL AND expires_at > ?;
