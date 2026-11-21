"""
Seed script to populate Mini-Zendesk SQLite database.
Seeds:
- 10 Clients (companies) and 12 Users (people who log in; each belongs to one client)
- 10 rows in Customers
- 10 rows in Agents
- 100 realistic Tickets with varied statuses and priorities
- Conversation Messages, Worksheet records, and Audit log history
"""

from datetime import datetime, timezone, timedelta
import hashlib
from pathlib import Path
from database import get_db_connection, init_db, DEFAULT_DB_PATH


def hash_password(password: str) -> str:
    """Encrypted/hashed password using SHA-256."""
    return hashlib.sha256(password.encode("utf-8")).hexdigest()


# 20 realistic ticket templates (cycled with variations to reach 100 unique tickets)
TICKET_TEMPLATES = [
    ("SSO login failure with Okta integration", "Users in EU region cannot authenticate via SAML 2.0; receiving 'Invalid SAML response' error on callback.", "urgent", "open"),
    ("Payment gateway returned error 502 on renewal", "Annual subscription failed during automated Stripe charge. Need invoice reissued.", "high", "pending"),
    ("Need bulk export of customer contact records", "Please provide a complete CSV dump of our company contacts created before Q3.", "low", "solved"),
    ("Webhook delivery latency exceeding 5 seconds", "Event callbacks for ticket.updated are delayed by up to 10 minutes during peak hours.", "normal", "open"),
    ("Two-factor authentication code not received via SMS", "Team members on Vodafone network in Mumbai report OTP SMS messages are not arriving.", "urgent", "open"),
    ("Invoice for October missing tax deduction breakdown", "The latest consolidated invoice does not show the GST breakdown required by our accounting department.", "low", "closed"),
    ("Feature Request: Add dark mode toggle in portal", "Would greatly appreciate a system-level dark theme for our agents working night shifts.", "low", "open"),
    ("API rate limit reached unexpectedly on /tickets endpoint", "Our integration script received 429 Too Many Requests despite staying within the 100 req/min limit.", "normal", "pending"),
    ("Dashboard widget charts failing to load on Safari", "Analytics graphs render blank in Safari 17.2, though they display properly in Chrome and Firefox.", "normal", "open"),
    ("Unable to invite new team members with Admin role", "When sending invite email to new supervisor, the role dropdown resets to Agent.", "high", "solved"),
    ("SSL certificate warning on custom domain setup", "Visiting support.acme.com shows NET::ERR_CERT_COMMON_NAME_INVALID error.", "urgent", "escalated"),
    ("Password reset email link expired immediately", "The link sent to our director expired within 2 minutes instead of the documented 24 hours.", "high", "solved"),
    ("Slow query response on ticket search with multiple tags", "Full-text search queries take over 4 seconds when searching with 3 or more tags.", "normal", "open"),
    ("Need SOC2 Type II compliance report for annual audit", "Our security team requires your latest SOC2 compliance summary for our vendor review.", "low", "solved"),
    ("CSV import failing with invalid character encoding", "Importing user list fails on row 142 due to non-ASCII accented characters in customer names.", "normal", "pending"),
    ("Email notification not sent when ticket is assigned", "Agent assignment notifications stopped firing around 09:00 UTC this morning.", "high", "open"),
    ("Mobile responsive view breaks on conversation thread", "Long code snippets in message threads overflow the viewport on iOS Safari.", "normal", "closed"),
    ("Session timeout logging agents out every 10 minutes", "Staff are repeatedly prompted to log in while drafting responses to customers.", "urgent", "sla_breached"),
    ("Cannot download PDF attachments larger than 10MB", "Attempting to download architecture diagrams returns HTTP 413 Payload Too Large.", "normal", "pending"),
    ("Requesting sandbox environment reset for QA testing", "Please flush the staging database and seed fresh demo tickets for our upcoming demo.", "low", "closed"),
]

# SLA durations by priority
SLA_HOURS = {
    "urgent": 1,
    "high": 4,
    "normal": 24,
    "low": 48
}


ALL_TABLES = ["sessions", "audit", "worksheet", "messages", "tickets", "users", "customers",
              "agents", "clients", "statuses", "priorities", "system_settings"]


def seed_data(db_path: Path = DEFAULT_DB_PATH) -> None:
    # Rebuild from schema.sql so schema changes (e.g. users.client_id) reach an existing DB file.
    conn = get_db_connection(db_path)
    conn.execute("PRAGMA foreign_keys = OFF;")
    for table in ALL_TABLES:
        conn.execute(f"DROP TABLE IF EXISTS {table};")
    conn.commit()
    conn.close()

    init_db(db_path)
    conn = get_db_connection(db_path)
    cursor = conn.cursor()

    # Clear existing data in reverse dependency order
    cursor.execute("DELETE FROM sessions;")
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

    # 1. Seed 10 Clients (companies). Clients don't log in, so no password.
    clients = [
        ("Acme Corp", "support@acme.com"),
        ("Globex International", "it@globex.com"),
        ("Initech Systems", "help@initech.com"),
        ("Umbrella Health", "contact@umbrella.com"),
        ("Stark Industries", "support@stark.com"),
        ("Wayne Enterprises", "helpdesk@wayne.com"),
        ("Cyberdyne AI", "ops@cyberdyne.com"),
        ("Soylent Corp", "client@soylent.com"),
        ("Massive Dynamic", "contact@massivedynamic.com"),
        ("Hooli Cloud", "billing@hooli.com"),
    ]
    cursor.executemany("INSERT INTO clients (name, email, password_hash) VALUES (?, ?, '');", clients)
    cursor.execute("SELECT id, email FROM clients ORDER BY id ASC;")
    client_rows = cursor.fetchall()

    # 2. Seed 12 Users, each belonging to one client (email on the client's domain).
    #    Acme and Globex have two users each, to show colleagues sharing their company's tickets.
    users = [
        # (client index, name, category)
        (0, "Aarav Patel", "Employee"),
        (0, "Aditi Sharma", "Manager"),
        (1, "Rohan Gupta", "Support"),
        (1, "Sanya Verma", "Finance"),
        (2, "Vikram Malhotra", "HR"),
        (3, "Ananya Deshmukh", "Operations"),
        (4, "Karan Mehta", "Developer"),
        (5, "Pooja Kulkarni", "QA"),
        (6, "Siddharth Rao", "DevOps"),
        (7, "Meera Iyer", "Procurement"),
        (8, "Arjun Nair", "Engineering"),
        (9, "Neha Joshi", "Product"),
    ]
    user_rows = []
    for idx, name, category in users:
        client = client_rows[idx]
        domain = client["email"].split("@", 1)[1]
        email = f"{name.split()[0].lower()}@{domain}"
        user_rows.append((client["id"], name, email, category, default_pwd_hash))
    cursor.executemany(
        "INSERT INTO users (client_id, name, email, category, password_hash) VALUES (?, ?, ?, ?, ?);",
        user_rows,
    )
    cursor.execute("SELECT id, client_id FROM users ORDER BY id ASC;")
    users_by_client = {}
    for row in cursor.fetchall():
        users_by_client.setdefault(row["client_id"], []).append(row["id"])

    # 3. Seed 10 Customers (legacy table, not used by the API)
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
    cursor.executemany("INSERT INTO customers (name, email, password_hash) VALUES (?, ?, ?);", customers)

    # 4. Seed 10 Agents
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
        "INSERT INTO agents (name, email, role, password_hash, is_active) VALUES (?, ?, ?, ?, ?);",
        agents
    )

    # Fetch IDs
    cursor.execute("SELECT id FROM clients ORDER BY id ASC;")
    client_ids = [row["id"] for row in cursor.fetchall()]

    cursor.execute("SELECT id FROM agents WHERE role = 'agent' ORDER BY id ASC;")
    agent_ids = [row["id"] for row in cursor.fetchall()]

    cursor.execute("SELECT id FROM agents WHERE role = 'admin' ORDER BY id ASC;")
    admin_ids = [row["id"] for row in cursor.fetchall()]
    admin_id = admin_ids[0]

    # 5. Generate Exactly 100 Realistic Tickets
    # Distribution of statuses:
    #   open: ~35, pending: ~25, solved: ~20, closed: ~10, sla_breached: ~5, escalated: ~5
    # Distribution of priorities:
    #   urgent: ~12, high: ~22, normal: ~46, low: ~20
    now = datetime.now(timezone.utc)
    ticket_rows = []

    statuses_pool = (
        ["open"] * 35 +
        ["pending"] * 25 +
        ["solved"] * 20 +
        ["closed"] * 10 +
        ["sla_breached"] * 5 +
        ["escalated"] * 5
    )

    priorities_pool = (
        ["urgent"] * 12 +
        ["high"] * 22 +
        ["normal"] * 46 +
        ["low"] * 20
    )

    for i in range(100):
        tmpl_idx = i % len(TICKET_TEMPLATES)
        base_title, base_desc, default_prio, _ = TICKET_TEMPLATES[tmpl_idx]

        # Vary title to make all 100 distinct
        variant_num = (i // len(TICKET_TEMPLATES)) + 1
        title = f"{base_title} (Batch #{variant_num})" if variant_num > 1 else base_title

        status = statuses_pool[i]
        priority = priorities_pool[i]
        client_id = client_ids[i % len(client_ids)]
        # The ticket is raised by one of that client's users (alternating when there are several).
        client_users = users_by_client[client_id]
        user_id = client_users[(i // len(client_ids)) % len(client_users)]

        # Assign agent: leave ~10 tickets unassigned (agent_id = None) to test Unassigned views
        if i % 10 == 0 and status in ("open", "pending"):
            agent_id = None
        elif status == "escalated":
            agent_id = admin_id  # Escalated tickets assigned to admin
        else:
            agent_id = agent_ids[i % len(agent_ids)]

        is_escalated = 1 if status in ("escalated", "sla_breached") else 0

        # Create timestamps spread across the last 5 days
        hours_ago = (100 - i) * 1.2
        created_at = (now - timedelta(hours=hours_ago)).isoformat()
        updated_at = (now - timedelta(hours=max(0.5, hours_ago - 2))).isoformat()

        # Due date based on priority SLA
        due_at = (now - timedelta(hours=hours_ago) + timedelta(hours=SLA_HOURS[priority])).isoformat()

        # Solved timestamp
        solved_at = updated_at if status in ("solved", "closed") else None

        ticket_rows.append((
            title,
            base_desc,
            status,
            priority,
            client_id,
            user_id,
            agent_id,
            is_escalated,
            due_at,
            solved_at,
            created_at,
            updated_at
        ))

    cursor.executemany(
        """
        INSERT INTO tickets (
            title, description, status, priority, client_id, user_id, agent_id,
            is_escalated, due_at, solved_at, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """,
        ticket_rows
    )

    # 6. Fetch created ticket IDs to attach Worksheet, Messages, and Audit rows
    cursor.execute("SELECT id, client_id, user_id, agent_id, status, priority, created_at FROM tickets ORDER BY id ASC;")
    all_tickets = cursor.fetchall()

    worksheet_rows = []
    audit_rows = []
    message_rows = []

    for t in all_tickets:
        t_id = t["id"]
        u_id = t["user_id"]
        a_id = t["agent_id"]
        st = t["status"]
        pr = t["priority"]
        cr_at = t["created_at"]

        # Initial audit row: created by the client's user
        audit_rows.append((t_id, "user", u_id, "created", None, "open", cr_at))

        # Initial message from that user (ticket opening statement)
        message_rows.append((t_id, u_id, "user", "Hello support team, please assist with this issue as soon as possible.", "public", cr_at))

        if a_id:
            # Worksheet entry
            reason = "escalation" if st == "escalated" else "round_robin"
            assigned_by = admin_id if st == "escalated" else a_id
            worksheet_rows.append((t_id, a_id, assigned_by, reason, st, cr_at))
            audit_rows.append((t_id, "system", a_id, "assigned", None, str(a_id), cr_at))

            # Threaded response if ticket progressed
            if st in ("pending", "solved", "closed"):
                reply_time = (datetime.fromisoformat(cr_at) + timedelta(minutes=45)).isoformat()
                message_rows.append((t_id, a_id, "agent", "We have investigated and applied the initial configuration patch. Please verify.", "public", reply_time))
                message_rows.append((t_id, a_id, "agent", "Internal note: verified logs, database latency is back to normal.", "internal", reply_time))

            if st == "solved":
                audit_rows.append((t_id, "agent", a_id, "status_change", "open", "solved", cr_at))
            elif st == "closed":
                audit_rows.append((t_id, "agent", a_id, "status_change", "solved", "closed", cr_at))
            elif st == "escalated":
                audit_rows.append((t_id, "system", admin_id, "escalated", pr, "urgent", cr_at))

    cursor.executemany(
        "INSERT INTO worksheet (ticket_id, agent_id, assigned_by, reason, status, created_at) VALUES (?, ?, ?, ?, ?, ?);",
        worksheet_rows
    )

    cursor.executemany(
        "INSERT INTO audit (ticket_id, actor_type, actor_id, action, old_value, new_value, created_at) VALUES (?, ?, ?, ?, ?, ?, ?);",
        audit_rows
    )

    cursor.executemany(
        "INSERT INTO messages (ticket_id, sender_id, sender_type, text, visibility, created_at) VALUES (?, ?, ?, ?, ?, ?);",
        message_rows
    )

    # 7. Initialize Round-Robin Pointer
    cursor.execute(
        "INSERT INTO system_settings (key, value) VALUES (?, ?);",
        ("last_assigned_agent_id", str(agent_ids[0]))
    )

    conn.commit()
    conn.close()
    print("Database seeded successfully with 100 realistic tickets and supporting records!")


if __name__ == "__main__":
    seed_data()
