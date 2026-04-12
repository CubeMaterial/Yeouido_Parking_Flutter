from __future__ import annotations

from fastapi import FastAPI

from auth import router as auth_router
from reservation import router as reservation_router
from facility import router as facility_router


def include_routers(app: FastAPI) -> None:
    app.include_router(auth_router)
    app.include_router(reservation_router)
    app.include_router(facility_router)