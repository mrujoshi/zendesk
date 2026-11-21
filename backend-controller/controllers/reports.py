"""Daily report + manual escalation trigger (handy for the demo)."""
from datetime import date

from fastapi import APIRouter, Depends

import models
from controllers.tickets import escalate_overdue
from deps import Actor, current_actor, require_admin, require_staff

router = APIRouter(tags=["reports"])


@router.get("/reports/daily", summary="Created / solved / open / escalated / per agent")
def daily_report(day: date | None = None, actor: Actor = Depends(current_actor)):
    require_staff(actor)
    return models.daily_report((day or date.today()).isoformat())


@router.post("/escalations/run", summary="Run the escalation check now (admin)")
def run_escalation(actor: Actor = Depends(current_actor)):
    require_admin(actor)
    return {"escalated": escalate_overdue()}
