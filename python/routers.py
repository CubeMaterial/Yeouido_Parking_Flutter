from __future__ import annotations

from fastapi import FastAPI

from auth import router as auth_router


def include_routers(app: FastAPI) -> None:
    app.include_router(auth_router)
