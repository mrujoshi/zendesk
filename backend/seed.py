"""
Seed script to populate Mini-Zendesk with realistic initial data.
Useful for local development and live hackathon demos.
"""

from pathlib import Path
from database import get_db_connection, init_db, DEFAULT_DB_PATH


def seed_data(db_path: Path = DEFAULT_DB_PATH) -> None:
    # Ensure tables exist
    init_db(db_path)

    conn = get_db_connection(db_path)
    cursor = conn.cursor()

    # Clear existing demo data
    cursor.execute("DELETE FROM ticket_events;")
    cursor.execute("DELETE FROM messages;")
    cursor.execute("DELETE FROM tickets;")
    cursor.execute("DELETE FROM users;")

    # 1. Insert Users (Agents & Customers)
    users = [
        ("Mrudula", "mrudula@support.com", "agent"),
        ("Monali", "monali@support.com", "agent"),
        ("Mrunnayee", "mrunnayee@support.com", "admin"),
        ("Alice Johnson", "alice@clientcorp.com", "customer"),
        ("Bob Smith", "bob@acme.com", "customer"),
        ("Charlie Brown", "charlie@globex.com", "customer"),
    ]

    cursor.executemany(
        "INSERT INTO users (name, email, role) VALUES (?, ?, ?);",
        users
    )

    # Fetch user IDs for foreign keys
    cursor.execute("SELECT id, name FROM users;")
    user_map = {row["name"]: row["id"] for row in cursor.fetchall()}

    # 2. Insert Tickets
    tickets = [
        (
            "Cannot access admin dashboard",
            "Getting 403 Forbidden error on /admin route after password reset.",
            "open",
            "urgent",
            user_map["Alice Johnson"],
            user_map["Mrudula"]
        ),
        (
            "Invoice request for October subscription",
            "Please send the October consolidated invoice for our billing records.",
            "pending",
            "low",
            user_map["Bob Smith"],
            user_map["Monali"]
        ),
        (
            "Feature Request: Dark mode theme",
            "Would love to have an option to switch to dark mode in the customer portal.",
            "open",
            "medium",
            user_map["Charlie Brown"],
            None  # Unassigned
        ),
        (
            "Password reset link expired immediately",
            "The link in the reset email expired within 2 minutes instead of 24 hours.",
            "solved",
            "high",
            user_map["Alice Johnson"],
            user_map["Mrudula"]
        ),
    ]

    cursor.executemany(
        """
        INSERT INTO tickets (title, description, status, priority, requester_id, assignee_id)
        VALUES (?, ?, ?, ?, ?, ?);
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

    # 4. Insert Initial Audit Trail Events
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

    conn.commit()
    conn.close()
    print("Database successfully seeded with realistic sample data!")


if __name__ == "__main__":
    seed_data()
