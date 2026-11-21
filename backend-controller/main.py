"""App entry. Run: .venv/bin/uvicorn main:app --reload  -> http://127.0.0.1:8000/docs"""
import asyncio
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

import models
from controllers import reports, tickets, users
from rules import RuleError

log = logging.getLogger("mini-zendesk")


async def escalation_loop():
    while True:
        await asyncio.sleep(60)
        try:
            ids = tickets.escalate_overdue()
            if ids:
                log.info("escalated %s", ids)
        except Exception:
            log.exception("escalation job failed")


@asynccontextmanager
async def lifespan(_: FastAPI):
    models.init()
    task = asyncio.create_task(escalation_loop())
    yield
    task.cancel()


app = FastAPI(title="Mini-Zendesk API", lifespan=lifespan)

app.add_middleware(  # Vite dev server
    CORSMiddleware,
    allow_origins=["http://localhost:5173", "http://127.0.0.1:5173"],
    allow_methods=["*"],
    allow_headers=["*"],
)

for r in (users.router, tickets.router, reports.router):
    app.include_router(r, prefix="/api")


# One error format everywhere: {"error": code, "message": text}
@app.exception_handler(RuleError)
def rule_error(_: Request, e: RuleError):
    return JSONResponse(status_code=e.status, content={"error": e.code, "message": e.message})


@app.exception_handler(RequestValidationError)
def validation_error(_: Request, e: RequestValidationError):
    first = e.errors()[0]
    field = ".".join(str(x) for x in first["loc"][1:])
    return JSONResponse(status_code=422, content={
        "error": "validation_error", "message": f"{field}: {first['msg']}"})


@app.exception_handler(Exception)
def unexpected(_: Request, e: Exception):
    log.exception("unhandled error")
    return JSONResponse(status_code=500, content={"error": "server_error", "message": "Something went wrong"})
