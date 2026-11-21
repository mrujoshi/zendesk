# Mini-Zendesk Product Manual & User Guide

> **Zendesk Pune Developer Workshop — Version 1.0 (Nov 2026)**  
> **Official Product Operations, Agent Workspace, and Administration Manual**

---

## 📖 Table of Contents
1. [Introduction & Product Overview](#1-introduction--product-overview)
2. [User Roles & Access Control (RBAC)](#2-user-roles--access-control-rbac)
3. [Getting Started & Authentication](#3-getting-started--authentication)
4. [End-User Guide (Client Users)](#4-end-user-guide-client-users)
5. [Support Agent Operations Guide](#5-support-agent-operations-guide)
6. [AI Support Assistant](#6-ai-support-assistant)
7. [Administrator & Team Management Guide](#7-administrator--team-management-guide)
8. [Ticket Lifecycle, SLAs & Background Escalations](#8-ticket-lifecycle-slas--background-escalations)
9. [Audit Trail & Compliance Ledger](#9-audit-trail--compliance-ledger)
10. [Daily Reports & Operational Analytics](#10-daily-reports--operational-analytics)
11. [Keyboard Shortcuts Reference](#11-keyboard-shortcuts-reference)
12. [API & Integration Reference](#12-api--integration-reference)
13. [Troubleshooting & FAQs](#13-troubleshooting--faqs)

---

## 1. Introduction & Product Overview

**Mini-Zendesk** is a multi-tenant, lightweight support ticketing platform engineered for fast-paced customer support teams and enterprise service desks. It provides a clean, responsive web interface backed by a high-performance Python FastAPI backend and a transactional SQLite database running in Write-Ahead Logging (`WAL`) mode.

### Key Capabilities
* **Multi-Tenant Data Isolation:** Customer companies (*Clients*) are partitioned. Individual customer staff (*Users*) can only view and interact with tickets belonging to their organization.
* **Deterministic SLA Management:** Automated due-date calculation per priority tier with a background escalation engine that monitors breaches and auto-escalates to senior staff.
* **Intelligent Routing & Assignment:** Atomic round-robin load distribution with manual reassignment tracking recorded in a dedicated **Worksheet** table.
* **Interactive Agent Workspace:** Complete ticket lifecycle stepper (`open` $\rightleftharpoons$ `pending` $\rightarrow$ `solved` $\rightarrow$ `closed`), threaded messaging, private internal notes, and hotkey navigation.
* **AI Support Assistant:** Integrated real-time summary, customer sentiment analysis, troubleshooting suggestions, and 1-click reply drafting (with fallback offline heuristics).
* **Immutable Audit Trail:** Append-only transaction log recording every state transition, assignment change, priority bump, and automated system event for enterprise compliance.

---

## 2. User Roles & Access Control (RBAC)

The platform enforces strict role-based authorization across three distinct user personas:

| Capability / Permission | Client User (`user`) | Support Agent (`agent`) | System Administrator (`admin`) |
| :--- | :---: | :---: | :---: |
| **Login Identity** | `user_type: user` | `user_type: agent` | `user_type: agent` |
| **File New Tickets** | ✅ Yes | ❌ No | ❌ No |
| **View Organization Tickets** | ✅ Only own client | ❌ Restricted to linked clients | ✅ All system tickets |
| **Post Public Replies** | ✅ Yes | ✅ Yes | ✅ Yes |
| **Post Internal Notes** | ❌ Forbidden (403) | ✅ Yes | ✅ Yes |
| **Change Ticket Status** | ❌ (Replies auto-reopen) | ✅ Validated transitions | ✅ Validated transitions |
| **Reassign Ticket Agent** | ❌ Forbidden | ✅ To linked staff | ✅ To any active agent |
| **View Audit Trail** | ❌ Hidden | ✅ Yes | ✅ Yes |
| **Access AI Assistant** | ❌ Hidden | ✅ Yes | ✅ Yes |
| **View Daily Reports** | ❌ Hidden | ✅ Yes | ✅ Yes |
| **Manage Clients & Users** | ❌ Hidden | ❌ Hidden | ✅ Full access |
| **Assign Agent Client Access** | ❌ Hidden | ❌ Hidden | ✅ Full access |
| **Trigger SLA Escalation** | ❌ Hidden | ❌ Hidden | ✅ Yes |

> [!NOTE]
> **Client vs. User Entity Distinction:** A *Client* represents the corporate account or company entity (e.g., Acme Corp, Globex). Individual people who log in and create tickets are *Users* tied to that Client. Colleagues within the same Client can review each other's tickets.

---

## 3. Getting Started & Authentication

### 3.1 Session Security
Mini-Zendesk utilizes stateless Bearer token authentication stored as salted SHA-256 hashes in the `sessions` table.
* **Token Lifetime:** 8 hours from issue time.
* **Revocation:** Explicitly invalidated on logout (`POST /api/auth/logout`).
* **Active Status Verification:** Inactive staff accounts (`is_active = 0`) are rejected immediately, even if a token has not expired.

### 3.2 Demo Accounts Reference
All pre-seeded demo accounts share the standard password: `password123`.

* **System Administrators:**
  * `asha@demo.com` (`user_type`: `agent`)
* **Support Agents:**
  * `priya@demo.com` (`user_type`: `agent`)
  * `rahul@demo.com` (`user_type`: `agent`)
  * `mrudula@support.com` (`user_type`: `agent`)
  * `monali@support.com` (`user_type`: `agent`)
* **Client Users:**
  * `aditi@acme.com` (Acme Corp — `user_type`: `user`)
  * `aarav@acme.com` (Acme Corp — `user_type`: `user`)
  * `rohan@globex.com` (Globex — `user_type`: `user`)
  * `sanya@globex.com` (Globex — `user_type`: `user`)

---

## 4. End-User Guide (Client Users)

### 4.1 Submitting a Support Ticket
1. Click the **"New ticket"** button in the header bar or press shortcut key <kbd>N</kbd>.
2. Fill in the required fields:
   * **Title:** Concise summary of the issue.
   * **Description:** Detailed explanation, reproducing steps, error codes, and context.
   * **Priority:** Select expected impact:
     * `Low` (48-hour resolution target)
     * `Normal` (24-hour resolution target)
     * `High` (4-hour resolution target)
     * `Urgent` (1-hour resolution target)
3. Click **"Submit Ticket"** (or press <kbd>⌘</kbd> + <kbd>Enter</kbd>).
4. The ticket is immediately registered, an agent is assigned via round-robin, and your SLA countdown begins.

### 4.2 Tracking & Replying
* Use the left navigation panel to view all open, pending, and resolved tickets filed by your company.
* Search tickets instantly by pressing <kbd>/</kbd> and typing keywords.
* When replying to a ticket:
  * Simply type in the reply box at the bottom of the conversation thread.
  * **Auto-Reopen Mechanism:** If a ticket was previously in `pending` or `solved` status, sending a reply automatically updates the ticket status to `open`, notifying the support staff.

---

## 5. Support Agent Operations Guide

### 5.1 Navigating the Agent Workspace
The Agent Workspace provides a unified two-column layout:
* **Left Column (Ticket Queue):** Displays tickets with client tags, priority indicators, current status, and dynamic SLA deadline chips.
* **Right Column (Ticket Detail & Actions):** Shows full conversation history, interactive status stepper, reassignment tools, internal notes, audit trail, and the AI Support Assistant.

### 5.2 Status Stepper & Allowed Lifecycle Moves
The interactive stepper visualizes allowed status transitions. Only legitimate state progressions are clickable:

$$\text{open} \rightleftharpoons \text{pending} \rightarrow \text{solved} \rightarrow \text{closed}$$

1. **`open`:** Ticket needs agent attention.
2. **`pending`:** Support agent has responded; waiting on client clarification.
3. **`solved`:** Issue resolved. Client can review or reply to reopen.
4. **`closed`:** Terminal state. Ticket is permanently locked against further changes or messages.

> [!WARNING]
> Illegal state transitions (e.g. attempting to jump directly from `open` to `closed`) are blocked by controller validation and return `400 Bad Request`.

### 5.3 Public Replies vs. Internal Notes
* **Public Reply (Default):** Sent to the customer. Moves ticket status to `pending`.
* **Internal Note:** Marked with a yellow border and lock icon. Visible **only** to staff members. Allows agents to collaborate, note diagnostic details, or leave handover instructions without notifying the client. Internal notes do **not** change ticket status.

### 5.4 Reassigning Tickets
Agents can transfer tickets to another active colleague:
1. Open the **Assignee** dropdown in the ticket header.
2. Select the destination agent (only agents with explicit access to this client are shown).
3. Confirm assignment.
4. The system logs a new row in the **Worksheet** table and writes an audit event (`action: 'assigned'`).

---

## 6. AI Support Assistant

When staff inspect a ticket, the AI Support Assistant panel renders on the right side of the workspace.

### Features:
1. **Ticket Summary & Categorization:** Automatically extracts core technical issues and categorizes them (e.g., *Billing*, *Authentication*, *Infrastructure*, *Bug*).
2. **Sentiment Analysis:** Gauges customer emotional tone (`Angry`, `Neutral`, `Positive`) with explicit reasoning.
3. **Troubleshooting Steps:** Provides an interactive diagnostic checklist tailored to the ticket's conversation history. Agents can check off items as they verify them.
4. **Suggested Reply Generator:**
   * **Insert to Composer:** Click *"Edit"* to transfer the generated response into your reply composer for review.
   * **Instant Send:** Click *"Send"* to dispatch the response immediately.

### AI Engine & Offline Fallback
* **Online Mode:** Powered by Claude when `ANTHROPIC_API_KEY` is configured in `backend-controller`. Results are cached per ticket until new messages arrive.
* **Offline Mode:** If no API key is provided, the panel gracefully displays a rule-based **Offline Estimate**, ensuring zero downtime or UI crashes.

---

## 7. Administrator & Team Management Guide

Accessible via the **Team** navigation tab (`/admin`) for users with `role: admin`.

### 7.1 Managing Staff (Agents & Admins)
* Create new agents with designated roles (`agent` or `admin`).
* Activate or deactivate staff. Deactivating an agent removes them from round-robin queues and revokes active login sessions immediately.

### 7.2 Managing Clients & Customer Organizations
* Register new client organizations with unique company emails and domains.
* View total associated users and tickets per client.

### 7.3 Managing Client Users
* Provision individual customer users under specific client organizations.
* Because users are scoped strictly to their parent client, open self-registration is disabled to prevent tenant spoofing.

### 7.4 Client Access Scoping (`agent_clients`)
* Admins can restrict support agents to specific client accounts (e.g., dedicated Tier-1 teams for Enterprise clients).
* Click **"Edit access"** on any agent in the Staff tab to toggle authorized clients.
* Admins always retain unrestricted visibility across all clients.

---

## 8. Ticket Lifecycle, SLAs & Background Escalations

### 8.1 Priority Tiers & SLA Deadlines

| Priority | Default SLA Target | Fast Demo Mode (`SLA_UNIT=minutes`) |
| :--- | :---: | :---: |
| **`urgent`** | 1 hour | 1 minute |
| **`high`** | 4 hours | 4 minutes |
| **`normal`** | 24 hours | 24 minutes |
| **`low`** | 48 hours | 48 minutes |

### 8.2 Background Escalation Engine
A non-blocking background daemon runs every 60 seconds on the backend:
1. Scans for tickets where `due_at < CURRENT_TIMESTAMP` and status is `'open'` or `'pending'`.
2. Marks the ticket `is_escalated = 1`.
3. Sets status to `'escalated'` or `'sla_breached'`.
4. Automatically bumps priority by one tier (`low` $\rightarrow$ `normal` $\rightarrow$ `high` $\rightarrow$ `urgent`).
5. Reassigns the ticket to an Administrator for emergency review.
6. Commits an immutable audit record attributed to `actor_type: 'system'`, `actor_id: 0`.

> [!TIP]
> **Manual Escalation for Demos:** Administrators can trigger the escalation sweep on demand via `POST /api/escalations/run`.

---

## 9. Audit Trail & Compliance Ledger

The **Audit Trail** provides an immutable record of every action performed on a ticket. Staff can inspect the audit log directly at the bottom of the Ticket Detail pane or via `GET /api/tickets/{id}/audit`.

### Tracked Event Types
* **`created`:** Ticket creation and initial round-robin assignment.
* **`assigned`:** Agent reassignments (showing previous and new agent).
* **`status_change`:** Lifecycle changes (showing `old_value` $\rightarrow$ `new_value`).
* **`priority_bumped`:** Manual or automatic SLA adjustments.
* **`escalated`:** Automated background SLA breach interventions.

```
┌─────────────────────────────────────────────────────────────┐
│                      AUDIT TIMELINE                         │
├─────────────────────────────────────────────────────────────┤
│ 15:02:10 - Client Aditi created ticket (Priority: High)     │
│ 15:02:11 - System assigned ticket to Agent Priya (RR)       │
│ 15:04:30 - Agent Priya posted public reply                  │
│ 15:04:30 - Status changed: open -> pending                  │
│ 15:08:45 - Agent Priya reassigned to Agent Rahul            │
│ 15:10:00 - System Escalation: Priority High -> Urgent       │
└─────────────────────────────────────────────────────────────┘
```

---

## 10. Daily Reports & Operational Analytics

Accessible to staff via the **Report** navigation tab (`/report`).

### Analytics Metrics Provided:
* **Created Today:** Total volume of incoming tickets.
* **Solved Today:** Volume of tickets successfully brought to resolution.
* **Currently Open:** Backlog of active tickets requiring response.
* **Escalated:** Count of tickets that breached SLA commitments.
* **Agent Workload Distribution:** Visual load bars showing active open tickets assigned per agent, highlighting imbalances across the support floor.
* **Historical Date Picker:** Inspect performance metrics for any previous date.

---

## 11. Keyboard Shortcuts Reference

Work efficiently in the agent workspace without reaching for your mouse:

| Shortcut | Action | Scope |
| :---: | :--- | :--- |
| <kbd>J</kbd> | Move to next ticket in list | Workspace |
| <kbd>K</kbd> | Move to previous ticket in list | Workspace |
| <kbd>/</kbd> | Focus ticket search input | Workspace |
| <kbd>N</kbd> | Open New Ticket modal | Client Users |
| <kbd>R</kbd> | Focus message reply composer | Ticket Detail |
| <kbd>⌘</kbd> + <kbd>Enter</kbd> | Send reply or submit dialog | Composer / Forms |
| <kbd>1</kbd> | Navigate to Tickets view | Global |
| <kbd>2</kbd> | Navigate to Report view | Staff |
| <kbd>3</kbd> | Navigate to Team Admin view | Administrators |
| <kbd>T</kbd> | Toggle Dark / Light visual theme | Global |
| <kbd>Esc</kbd> | Close active modal or clear search | Global |
| <kbd>?</kbd> | Open Keyboard Shortcuts cheat-sheet | Global |

---

## 12. API & Integration Reference

The FastAPI service generates interactive OpenAPI documentation at `http://127.0.0.1:8000/docs`.

### Primary Endpoints Summary:
* `POST /api/auth/login` — Authenticate and receive session Bearer token.
* `POST /api/auth/logout` — Revoke active token.
* `GET /api/auth/me` — Retrieve active session user profile.
* `GET /api/tickets` — Query tickets with filters (`status`, `priority`, `agent_id`, `client_id`, `escalated`).
* `POST /api/tickets` — Create a new ticket (Client users only).
* `GET /api/tickets/{id}` — Get ticket details and conversation thread.
* `PATCH /api/tickets/{id}/status` — Transition ticket status.
* `POST /api/tickets/{id}/assign` — Reassign ticket to an agent.
* `POST /api/tickets/{id}/messages` — Append public reply or private note.
* `GET /api/tickets/{id}/audit` — Retrieve immutable audit trail (Staff only).
* `GET /api/tickets/{id}/assist` — Retrieve AI summary, sentiment, and suggestions.
* `GET /api/reports/daily?day=YYYY-MM-DD` — Daily performance metrics.
* `POST /api/escalations/run` — Run background SLA escalation sweep.

---

## 13. Troubleshooting & FAQs

### Q: Why can't a user see tickets from another company?
**A:** Multi-tenant client isolation is enforced at the database query level. Users are strictly bound to their `client_id`. Only system administrators and assigned staff can see across client boundaries.

### Q: Why does a ticket reject my status change to "closed"?
**A:** Tickets must follow the validated lifecycle: `open` $\rightarrow$ `pending` $\rightarrow$ `solved` $\rightarrow$ `closed`. A ticket must first be marked `solved` before it can be closed.

### Q: What happens if an agent replies to a solved ticket?
**A:** When an agent replies publicly, the ticket moves to `pending`. When a client user replies to a `solved` ticket, the ticket automatically re-opens (`open`). Once a ticket is `closed`, no further messages can be posted.

### Q: How do I rebuild or re-seed the test database?
**A:** Run the seed script:
```bash
cd backend && python3 seed.py
```
This drops and regenerates all tables according to `schema.sql`, creating 10 clients, 12 users, 10 agents, and 100 realistic tickets with conversation messages and audit logs.
