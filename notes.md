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
