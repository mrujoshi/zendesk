"""Request bodies (V/C contract). Pydantic rejects bad input with 422 automatically."""
from pydantic import BaseModel, EmailStr, Field

from constants import AgentRole, Priority, Status, Visibility  # noqa: F401 (re-exported)


class ClientCreate(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    email: EmailStr


class AgentCreate(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    email: EmailStr
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
