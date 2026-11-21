"""Request bodies (V/C contract). Pydantic rejects bad input with 422 automatically."""
from enum import Enum

from pydantic import BaseModel, EmailStr, Field

from constants import AgentRole, Priority, Status, Visibility  # noqa: F401 (re-exported)


class UserType(str, Enum):
    USER = "user"    # a person who belongs to a client (company)
    AGENT = "agent"  # agents and admins both log in as 'agent'; role decides admin


class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=1)
    user_type: UserType


class ClientCreate(BaseModel):
    """A client is a company. It doesn't log in; its users do."""
    name: str = Field(min_length=1, max_length=100)
    email: EmailStr


class UserCreate(BaseModel):
    """A person who logs in for a client. They only ever see that client's tickets."""
    client_id: int
    name: str = Field(min_length=1, max_length=100)
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    category: str = Field("Employee", min_length=1, max_length=50)


class AgentCreate(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    role: AgentRole = AgentRole.AGENT


class TicketCreate(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    description: str = Field(min_length=1)
    priority: Priority = Priority.NORMAL


class StatusUpdate(BaseModel):
    status: Status


class AssignRequest(BaseModel):
    agent_id: int


class MessageCreate(BaseModel):
    text: str = Field(min_length=1)
    visibility: Visibility = Visibility.PUBLIC
