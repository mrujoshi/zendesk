"""Request bodies (V/C contract). Pydantic rejects bad input with 422 automatically."""
from enum import Enum
from typing import Annotated

from pydantic import BaseModel, EmailStr, Field, StringConstraints

from constants import AgentRole, Priority, Status, Visibility  # noqa: F401 (re-exported)


# Text that must contain something real: leading/trailing spaces are stripped BEFORE the
# length check, so "   " is rejected with 422. (Passwords are deliberately NOT stripped.)
Name = Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=100)]
Title = Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=200)]
Body = Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=10_000)]


class UserType(str, Enum):
    CLIENT = "client"
    AGENT = "agent"  # agents and admins both log in as 'agent'; role decides admin


class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=1)
    user_type: UserType


class ClientCreate(BaseModel):
    name: Name
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)


class AgentCreate(BaseModel):
    name: Name
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    role: AgentRole = AgentRole.AGENT


class TicketCreate(BaseModel):
    title: Title
    description: Body
    priority: Priority = Priority.NORMAL


class StatusUpdate(BaseModel):
    status: Status


class PriorityUpdate(BaseModel):
    priority: Priority


class AssignRequest(BaseModel):
    agent_id: int


class AgentClientsUpdate(BaseModel):
    """The full list of clients this agent may access (replaces the old list). [] = none."""
    client_ids: list[int] = Field(max_length=1000)


class MessageCreate(BaseModel):
    text: Body
    visibility: Visibility = Visibility.PUBLIC
