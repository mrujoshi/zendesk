# Team & Roles

* Mrunnayee - UI
* Mrudula - Backend
* Monali - Backend

## Tech Stack
* **Frontend:** React
* **Backend:** Python
* **Database:** SQLite

---

## Data Model

### Tables

1. **User**
   * `id`
   * `name`
   * `category`

2. **Client**
   * `id`
   * `name`

3. **Agent**
   * `id`
   * `name`
   * `role` (admin, agent)

4. **Tickets**
   * `id`
   * `creation`
   * `title`
   * `status`
   * `attachment`
   * `Description`
   * `priority`

5. **Status**
   * `status` (open, pending, closed)

6. **Message**
   * `id`
   * `text`
   * `visibility`

7. **Worksheet**
   * `agent`
   * `ticket id`
   * `status`

---

## Requirements

1. Create user
2. Add messages on tickets
3. List of tickets
4. Filters based on status
5. Escalation flow
6. Site should load quickly
7. Error handling
8. Persist all messages and status
-----------------------------------------------------------------------------------------
1. Create user

1. POST /api/clients or POST /api/agents with name, email and role.
2. Validate that the name isn't empty, the email is valid, and the role is admin or agent.
3. Check the email isn't already used; if it is, return 409.
4. Save it with is_active = 1 and return 201.

2. Create ticket (core)

1. POST /api/tickets with title, description and priority.
2. Validate the input; bad input gets 422.
3. Save it with status open and work out due_at from the priority.
4. Assign it round-robin (requirement 3).
5. Write an audit row and return 201.

3. Assign / reassign: round-robin (core)

1. Get the active agents sorted by id, then read the last assigned agent.
2. Pick the next agent, wrapping around at the end. If there are no agents, leave it unassigned.
3. Save a worksheet row, update the pointer and write an audit row, all in one transaction.
4. Manual reassign: POST /tickets/{id}/assign. Check the ticket isn't closed and the agent is active, then save the row and the audit entry. The pointer doesn't change.

4. Add messages on tickets

1. POST /api/tickets/{id}/messages with text and visibility.
2. Return 404 if the ticket doesn't exist and 403 if a client tries to add an internal note.
3. Save the message.
4. Auto status: an agent reply → pending, a client reply → open, closed → 400.
5. Write an audit row if the status changed, then return 201.
