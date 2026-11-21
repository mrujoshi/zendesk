"""
Database initialization and connection management for Mini-Zendesk.
Uses standard Python sqlite3 with WAL mode and foreign key enforcement.
"""

import os
import sqlite3
from pathlib import Path

# Default database file path (persisted in backend directory)
BACKEND_DIR = Path(__file__).resolve().parent
DEFAULT_DB_PATH = BACKEND_DIR / "zendesk.db"
SCHEMA_PATH = BACKEND_DIR / "schema.sql"


def get_db_connection(db_path: Path = DEFAULT_DB_PATH) -> sqlite3.Connection:
    """
    Returns an open SQLite connection configured for:
    1. Row access by column name (Row factory)
    2. Foreign key constraint enforcement
    3. WAL journal mode for high concurrency and read performance
    """
    conn = sqlite3.connect(str(db_path))
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON;")
    conn.execute("PRAGMA journal_mode = WAL;")
    return conn


def init_db(db_path: Path = DEFAULT_DB_PATH, schema_path: Path = SCHEMA_PATH) -> None:
    """
    Initializes database schema from schema.sql.
    Safe to run repeatedly (uses CREATE TABLE IF NOT EXISTS).
    """
    with open(schema_path, "r", encoding="utf-8") as f:
        schema_sql = f.read()

    with get_db_connection(db_path) as conn:
        conn.executescript(schema_sql)
        conn.commit()


if __name__ == "__main__":
    print(f"Initializing database at: {DEFAULT_DB_PATH}")
    init_db()
    print("Database initialized successfully!")
