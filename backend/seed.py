"""
Seed script to populate Mini-Zendesk with realistic initial data.
Matches schema.sql and notes.md specifications.
"""

from datetime import datetime, timezone, timedelta
import hashlib
from pathlib import Path
from database import get_db_connection, init_db, DEFAULT_DB_PATH


def hash_password(password: str) -> str:
    # Standard SHA-256 hash for fast, zero-dependency demo authentication
    return hashlib.sha256(password.encode("utf-8")).hexdigest()


def seed_data(db_path: Path = DEFAULT_DB_PATH) -> None:
    # Ensure tables exist
    init_db(db_path)

    conn = get_db_connection(db_path)
    cursor = conn.cursor()

    # Clear existing demo data in reverse dependency order
    cursor.execute("DELETE FROM system_settings;")
    cursor.execute("DELETE FROM ticket_events;")
    cursor.execute("DELETE FROM worksheet;")
    cursor.execute("DELETE FROM messages;")
    cursor.execute("DELETE FROM tickets;")
    cursor.execute("DELETE FROM users;")

    # 1. Insert Users (Agents, Admin, and Clients)
    # Default password for all seed accounts: 'password123'
    default_pwd_hash = hash_password("password123")

    users = [
        ("Mrudula", "mrudula@support.com", default_pwd_hash, "agent", 1),
        ("Monali", "monali@support.com", default_pwd_hash, "agent", 1),
        ("Mrunnayee", "mrunnayee@support.com", default_pwd_hash, "admin", 1),
        ("Alice Johnson", "alice@clientcorp.com", default_pwd_hash, "client", 1),
        ("Bob Smith", "bob@acme.com", default_pwd_hash, "client", 1),
        ("Charlie Brown", "charlie@globex.com", default_pwd_hash, "client", 1),
    ]

    cursor.executemany(
        """
        INSERT INTO users (name, email, password_hash, role, is_active)
        VALUES (?, ?, ?, ?, ?);
        """,
        users
    )

    # Fetch user IDs
    cursor.execute("SELECT id, name FROM users;")
    user_map = {row["name"]: row["id"] for row in cursor.fetchall()}

    # 2. Insert Tickets with SLA Due Dates
    now = datetime.now(timezone.utc)
    tickets = [
        (
            "Cannot access admin dashboard",
            "Getting 403 Forbidden error on /admin route after password reset.",
            "open",
            "urgent",
            user_map["Alice Johnson"],
            user_map["Mrudula"],
            (now + timedelta(hours=4)).isoformat()
        ),
        (
            "Invoice request for October subscription",
            "Please send the October consolidated invoice for our billing records.",
            "pending",
            "low",
            user_map["Bob Smith"],
            user_map["Monali"],
            (now + timedelta(hours=48)).isoformat()
        ),
        (
            "Feature Request: Dark mode theme",
            "Would love to have an option to switch to dark mode in the customer portal.",
            "open",
            "medium",
            user_map["Charlie Brown"],
            None,  # Unassigned
            (now + timedelta(hours=24)).isoformat()
        ),
        (
            "Password reset link expired immediately",
            "The link in the reset email expired within 2 minutes instead of 24 hours.",
            "solved",
            "high",
            user_map["Alice Johnson"],
            user_map["Mrudula"],
            (now + timedelta(hours=8)).isoformat()
        ),
    ]

    cursor.executemany(
        """
        INSERT INTO tickets (title, description, status, priority, requester_id, assignee_id, due_at)
        VALUES (?, ?, ?, ?, ?, ?, ?);
        """,
        tickets
    )

    # Fetch ticket IDs
    cursor.execute("SELECT id, title FROM tickets ORDER BY id ASC;")
    ticket_rows = cursor.fetchall()
    t1_id = ticket_rows[0]["id"]
    t2_id = ticket_rows[1]["id"]
    t4_id = ticket_rows[3]["id"]

    # 3. Insert Messages / Conversation Threads
    messages = [
        # Ticket 1 thread
        (t1_id, user_map["Alice Johnson"], "I am blocked from checking my team settings.", "public"),
        (t1_id, user_map["Mrudula"], "Investigating the permission cache. Will update shortly.", "public"),
        (t1_id, user_map["Mrudula"], "Internal note: check Redis session token TTL.", "internal"),

        # Ticket 2 thread
        (t2_id, user_map["Bob Smith"], "Can you email it to billing@acme.com directly?", "public"),
        (t2_id, user_map["Monali"], "Generating the PDF invoice from our portal now.", "public"),

        # Ticket 4 thread
        (t4_id, user_map["Alice Johnson"], "The link arrived but says 'token expired'.", "public"),
        (t4_id, user_map["Mrudula"], "We patched the expiration window. Please try the new link sent just now.", "public"),
        (t4_id, user_map["Alice Johnson"], "All set! Thanks for resolving this so quickly.", "public"),
    ]

    cursor.executemany(
        "INSERT INTO messages (ticket_id, sender_id, text, visibility) VALUES (?, ?, ?, ?);",
        messages
    )

    # 4. Insert Worksheet Rows (Active Agent Queues)
    worksheet_rows = [
        (t1_id, user_map["Mrudula"], "open"),
        (t2_id, user_map["Monali"], "pending"),
        (t4_id, user_map["Mrudula"], "solved"),
    ]
    cursor.executemany(
        "INSERT INTO worksheet (ticket_id, agent_id, status) VALUES (?, ?, ?);",
        worksheet_rows
    )

    # 5. Insert Audit Trail Events
    events = [
        (t1_id, user_map["Alice Johnson"], "created", None, "open"),
        (t1_id, user_map["Mrunnayee"], "assigned", None, "Mrudula"),
        (t2_id, user_map["Bob Smith"], "created", None, "open"),
        (t2_id, user_map["Monali"], "status_change", "open", "pending"),
        (t4_id, user_map["Mrudula"], "status_change", "open", "solved"),
    ]

    cursor.executemany(
        """
        INSERT INTO ticket_events (ticket_id, user_id, event_type, old_value, new_value)
        VALUES (?, ?, ?, ?, ?);
        """,
        events
    )

    # 6. Initialize Round-Robin Pointer in system_settings
    # Pointer points to the last assigned agent ID (Mrudula)
    cursor.execute(
        "INSERT INTO system_settings (key, value) VALUES (?, ?);",
        ("last_assigned_agent_id", str(user_map["Mrudula"]))
    )

    conn.commit()
    conn.close()
    print("Database successfully seeded with realistic sample data!")


if __name__ == "__main__":
    seed_data()
