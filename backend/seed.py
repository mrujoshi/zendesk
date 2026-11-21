"""
Seed script to populate Mini-Zendesk SQLite database.
Seeds 10 rows each in Users, Clients, Customers, and Agents with encrypted passwords,
along with sample Tickets, Messages, Worksheet, and Audit records.
"""

from datetime import datetime, timezone, timedelta
import hashlib
from pathlib import Path
from database import get_db_connection, init_db, DEFAULT_DB_PATH


def hash_password(password: str) -> str:
    """Encrypted/hashed password using SHA-256."""
    return hashlib.sha256(password.encode("utf-8")).hexdigest()


def seed_data(db_path: Path = DEFAULT_DB_PATH) -> None:
    init_db(db_path)
    conn = get_db_connection(db_path)
    cursor = conn.cursor()

    # Clear existing data in reverse dependency order
    cursor.execute("DELETE FROM audit;")
    cursor.execute("DELETE FROM worksheet;")
    cursor.execute("DELETE FROM messages;")
    cursor.execute("DELETE FROM tickets;")
    cursor.execute("DELETE FROM agents;")
    cursor.execute("DELETE FROM customers;")
    cursor.execute("DELETE FROM clients;")
    cursor.execute("DELETE FROM users;")
    cursor.execute("DELETE FROM system_settings;")

    default_pwd_hash = hash_password("password123")

    # 1. Seed 10 Users (General / Internal users)
    users = [
        ("Aarav Patel", "Employee", default_pwd_hash),
        ("Aditi Sharma", "Manager", default_pwd_hash),
        ("Rohan Gupta", "Support", default_pwd_hash),
        ("Sanya Verma", "Finance", default_pwd_hash),
        ("Vikram Malhotra", "HR", default_pwd_hash),
        ("Ananya Deshmukh", "Operations", default_pwd_hash),
        ("Karan Mehta", "Developer", default_pwd_hash),
        ("Pooja Kulkarni", "QA", default_pwd_hash),
        ("Siddharth Rao", "DevOps", default_pwd_hash),
        ("Neha Joshi", "Product", default_pwd_hash),
    ]
    cursor.executemany(
        "INSERT INTO users (name, category, password_hash) VALUES (?, ?, ?);",
        users
    )

    # 2. Seed 10 Clients (Companies / Accounts)
    clients = [
        ("Acme Corp", "support@acme.com", default_pwd_hash),
        ("Globex International", "it@globex.com", default_pwd_hash),
        ("Initech Systems", "help@initech.com", default_pwd_hash),
        ("Umbrella Health", "contact@umbrella.com", default_pwd_hash),
        ("Stark Industries", "support@stark.com", default_pwd_hash),
        ("Wayne Enterprises", "helpdesk@wayne.com", default_pwd_hash),
        ("Cyberdyne AI", "ops@cyberdyne.com", default_pwd_hash),
        ("Soylent Corp", "client@soylent.com", default_pwd_hash),
        ("Massive Dynamic", "contact@massivedynamic.com", default_pwd_hash),
        ("Hooli Cloud", "billing@hooli.com", default_pwd_hash),
    ]
    cursor.executemany(
        "INSERT INTO clients (name, email, password_hash) VALUES (?, ?, ?);",
        clients
    )

    # 3. Seed 10 Customers (End-user Requesters filing tickets)
    customers = [
        ("Ravi Kumar", "ravi@customer.com", default_pwd_hash),
        ("Alice Johnson", "alice@clientcorp.com", default_pwd_hash),
        ("Bob Smith", "bob@acme.com", default_pwd_hash),
        ("Charlie Brown", "charlie@globex.com", default_pwd_hash),
        ("Diana Prince", "diana@themyscira.com", default_pwd_hash),
        ("Ethan Hunt", "ethan@imf.org", default_pwd_hash),
        ("Fiona Gallagher", "fiona@chicago.com", default_pwd_hash),
        ("George Clark", "george@initech.com", default_pwd_hash),
        ("Hannah Abbott", "hannah@hogwarts.edu", default_pwd_hash),
        ("Ian Malcolm", "ian@ingen.com", default_pwd_hash),
    ]
    cursor.executemany(
        "INSERT INTO customers (name, email, password_hash) VALUES (?, ?, ?);",
        customers
    )

    # 4. Seed 10 Agents (Support staff and Admins)
    agents = [
        ("Admin Asha", "asha@demo.com", "admin", default_pwd_hash, 1),
        ("Priya Agent", "priya@demo.com", "agent", default_pwd_hash, 1),
        ("Rahul Agent", "rahul@demo.com", "agent", default_pwd_hash, 1),
        ("Mrudula", "mrudula@support.com", "agent", default_pwd_hash, 1),
        ("Monali", "monali@support.com", "agent", default_pwd_hash, 1),
        ("Mrunnayee", "mrunnayee@support.com", "admin", default_pwd_hash, 1),
        ("Amit Joshi", "amit@support.com", "agent", default_pwd_hash, 1),
        ("Sneha Patil", "sneha@support.com", "agent", default_pwd_hash, 1),
        ("Kunal Shinde", "kunal@support.com", "agent", default_pwd_hash, 1),
        ("Divya Nair", "divya@support.com", "agent", default_pwd_hash, 1),
    ]
    cursor.executemany(
        """
        INSERT INTO agents (name, email, role, password_hash, is_active)
        VALUES (?, ?, ?, ?, ?);
        """,
        agents
    )

    # Fetch IDs for seeding tickets and messages
    cursor.execute("SELECT id, name FROM agents;")
    agent_map = {row["name"]: row["id"] for row in cursor.fetchall()}

    cursor.execute("SELECT id, name FROM clients;")
    client_map = {row["name"]: row["id"] for row in cursor.fetchall()}

    # 5. Seed Tickets
    now = datetime.now(timezone.utc)
    tickets = [
        (
            "Cannot access admin dashboard",
            "Getting 403 Forbidden error on /admin route after password reset.",
            "open",
            "urgent",
            client_map["Acme Corp"],
            agent_map["Priya Agent"],
            0,
            (now + timedelta(hours=1)).isoformat()
        ),
        (
            "Invoice request for October subscription",
            "Please send the October consolidated invoice for our billing records.",
            "pending",
            "low",
            client_map["Globex International"],
            agent_map["Rahul Agent"],
            0,
            (now + timedelta(hours=48)).isoformat()
        ),
        (
            "Feature Request: Dark mode theme",
            "Would love to have an option to switch to dark mode in the customer portal.",
            "open",
            "normal",
            client_map["Initech Systems"],
            None,  # Unassigned
            0,
            (now + timedelta(hours=24)).isoformat()
        ),
        (
            "Password reset link expired immediately",
            "The link in the reset email expired within 2 minutes instead of 24 hours.",
            "solved",
            "high",
            client_map["Umbrella Health"],
            agent_map["Priya Agent"],
            0,
            (now + timedelta(hours=4)).isoformat()
        ),
    ]

    cursor.executemany(
        """
        INSERT INTO tickets (title, description, status, priority, client_id, agent_id, is_escalated, due_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?);
        """,
        tickets
    )

    cursor.execute("SELECT id, title FROM tickets ORDER BY id ASC;")
    ticket_rows = cursor.fetchall()
    t1_id = ticket_rows[0]["id"]
    t2_id = ticket_rows[1]["id"]
    t4_id = ticket_rows[3]["id"]

    # 6. Seed Messages with sender_id and sender_type
    messages = [
        (t1_id, client_map["Acme Corp"], "client", "We are blocked from checking our team settings.", "public"),
        (t1_id, agent_map["Priya Agent"], "agent", "Investigating the permission cache. Will update shortly.", "public"),
        (t1_id, agent_map["Priya Agent"], "agent", "Internal note: check Redis session token TTL.", "internal"),

        (t2_id, client_map["Globex International"], "client", "Can you email it to billing@globex.com directly?", "public"),
        (t2_id, agent_map["Rahul Agent"], "agent", "Generating the PDF invoice from our portal now.", "public"),

        (t4_id, client_map["Umbrella Health"], "client", "The link arrived but says 'token expired'.", "public"),
        (t4_id, agent_map["Priya Agent"], "agent", "We patched the expiration window. Please try the new link sent just now.", "public"),
        (t4_id, client_map["Umbrella Health"], "client", "All set! Thanks for resolving this so quickly.", "public"),
    ]

    cursor.executemany(
        """
        INSERT INTO messages (ticket_id, sender_id, sender_type, text, visibility)
        VALUES (?, ?, ?, ?, ?);
        """,
        messages
    )

    # 7. Seed Worksheet
    worksheet_rows = [
        (t1_id, agent_map["Priya Agent"], agent_map["Admin Asha"], "round_robin", "open"),
        (t2_id, agent_map["Rahul Agent"], agent_map["Admin Asha"], "round_robin", "pending"),
        (t4_id, agent_map["Priya Agent"], agent_map["Admin Asha"], "round_robin", "solved"),
    ]
    cursor.executemany(
        """
        INSERT INTO worksheet (ticket_id, agent_id, assigned_by, reason, status)
        VALUES (?, ?, ?, ?, ?);
        """,
        worksheet_rows
    )

    # 8. Seed Audit Trail
    audit_rows = [
        (t1_id, "client", client_map["Acme Corp"], "created", None, "open"),
        (t1_id, "agent", agent_map["Admin Asha"], "assigned", None, "Priya Agent"),
        (t2_id, "client", client_map["Globex International"], "created", None, "open"),
        (t2_id, "agent", agent_map["Rahul Agent"], "status_change", "open", "pending"),
        (t4_id, "agent", agent_map["Priya Agent"], "status_change", "open", "solved"),
    ]
    cursor.executemany(
        """
        INSERT INTO audit (ticket_id, actor_type, actor_id, action, old_value, new_value)
        VALUES (?, ?, ?, ?, ?, ?);
        """,
        audit_rows
    )

    # 9. Set Round-Robin Pointer
    cursor.execute(
        "INSERT INTO system_settings (key, value) VALUES (?, ?);",
        ("last_assigned_agent_id", str(agent_map["Rahul Agent"]))
    )

    conn.commit()
    conn.close()
    print("Database seeded successfully with 10 rows each in users, clients, customers, and agents!")


if __name__ == "__main__":
    seed_data()
