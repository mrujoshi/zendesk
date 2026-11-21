"""Request bodies (V/C contract). Pydantic rejects bad input with 422 automatically."""
from enum import Enum

from pydantic import BaseModel, EmailStr, Field

from constants import AgentRole, Priority, Status, Visibility  # noqa: F401 (re-exported)


class UserType(str, Enum):
    CLIENT = "client"
    AGENT = "agent"  # agents and admins both log in as 'agent'; role decides admin


class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=1)
    user_type: UserType


class ClientCreate(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)


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
