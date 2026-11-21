"""
Fixed values used across the app. These are constants, NOT database tables:
they never change while the app runs, and the rules about them live in code.
The DB stores them as TEXT (with a CHECK constraint for safety).
"""
from enum import Enum


class Status(str, Enum):
    OPEN = "open"          # agent must act
    PENDING = "pending"    # waiting on the client
    SOLVED = "solved"      # done, client can still reopen
    CLOSED = "closed"      # final, locked


class Priority(str, Enum):
    LOW = "low"
    NORMAL = "normal"
    HIGH = "high"
    URGENT = "urgent"


class AgentRole(str, Enum):
    ADMIN = "admin"
    AGENT = "agent"


class Visibility(str, Enum):
    PUBLIC = "public"
    INTERNAL = "internal"


# Allowed status moves (the lifecycle)
ALLOWED_TRANSITIONS = {
    Status.OPEN: {Status.PENDING, Status.SOLVED},
    Status.PENDING: {Status.OPEN, Status.SOLVED},
    Status.SOLVED: {Status.OPEN, Status.CLOSED},
    Status.CLOSED: set(),
}

# Statuses that still need work (used by escalation and reports)
ACTIVE_STATUSES = {Status.OPEN, Status.PENDING}

# SLA: how long each priority may stay unsolved (in SLA_UNIT, default hours)
SLA = {Priority.URGENT: 1, Priority.HIGH: 4, Priority.NORMAL: 24, Priority.LOW: 48}

# Escalation bumps priority one level
NEXT_PRIORITY = {
    Priority.LOW: Priority.NORMAL,
    Priority.NORMAL: Priority.HIGH,
    Priority.HIGH: Priority.URGENT,
    Priority.URGENT: Priority.URGENT,
}
