from contextlib import closing
from contextlib import asynccontextmanager
import os
from pathlib import Path
from typing import Any

import pymysql
from fastapi import FastAPI, HTTPException
from dotenv import load_dotenv

from auth import set_connection_factory
from routers import include_routers


load_dotenv(Path(__file__).with_name("py.env"))


def get_required_env(name: str) -> str:
    value = os.getenv(name)
    if value is None or not value.strip():
        raise RuntimeError(f"{name} 환경 변수가 설정되어 있지 않습니다.")
    return value


DB_CONFIG = {
    "host": get_required_env("DB_HOST"),
    "port": int(os.getenv("DB_PORT", "3306")),
    "user": get_required_env("DB_USER"),
    "password": get_required_env("DB_PASSWORD"),
    "database": get_required_env("DB_NAME"),
    "charset": "utf8mb4",
    "connect_timeout": int(os.getenv("DB_CONNECT_TIMEOUT", "5")),
    "read_timeout": int(os.getenv("DB_READ_TIMEOUT", "5")),
    "write_timeout": int(os.getenv("DB_WRITE_TIMEOUT", "5")),
    "cursorclass": pymysql.cursors.DictCursor,
}


DENIED_COLUMNS = {
    "password",
    "user_password",
    "token",
    "code_hash",
}

ALLOWED_TABLES: set[str] = set()
ALLOWED_COLUMNS: dict[str, set[str]] = {}


def get_connection() -> pymysql.connections.Connection:
    return pymysql.connect(**DB_CONFIG)


def load_allowed_schema() -> None:
    global ALLOWED_TABLES, ALLOWED_COLUMNS

    with closing(get_connection()) as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                """
                SELECT TABLE_NAME, COLUMN_NAME
                FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA = DATABASE()
                ORDER BY TABLE_NAME, ORDINAL_POSITION
                """
            )
            rows = cursor.fetchall()

    allowed_columns: dict[str, set[str]] = {}

    for row in rows:
        table_name = row["TABLE_NAME"]
        column_name = row["COLUMN_NAME"]

        if column_name.lower() in DENIED_COLUMNS:
            continue

        allowed_columns.setdefault(table_name, set()).add(column_name)

    ALLOWED_TABLES = set(allowed_columns)
    ALLOWED_COLUMNS = allowed_columns


def validate_table_name(table_name: str) -> None:
    if table_name not in ALLOWED_TABLES:
        raise HTTPException(status_code=400, detail="허용되지 않은 테이블입니다.")


def validate_column_names(table_name: str, column_names: list[str]) -> None:
    validate_table_name(table_name)

    allowed_columns = ALLOWED_COLUMNS.get(table_name, set())
    invalid_columns = sorted(set(column_names) - allowed_columns)

    if invalid_columns:
        raise HTTPException(
            status_code=400,
            detail=f"허용되지 않은 컬럼입니다: {', '.join(invalid_columns)}",
        )


@asynccontextmanager
async def lifespan(app: FastAPI) -> Any:
    load_allowed_schema()
    yield


app = FastAPI(
    title="Yeouido Parking DB Connector",
    description="Simple FastAPI service for checking MySQL connectivity.",
    version="1.0.0",
    lifespan=lifespan,
)
set_connection_factory(get_connection)
include_routers(app)


@app.get("/", summary="Service status")
def read_root() -> dict[str, str]:
    return {
        "message": "FastAPI is running.",
        "docs": "/docs",
        "openapi": "/openapi.json",
    }


@app.get("/db-check", summary="Check MySQL connection")
def db_check() -> dict[str, str]:
    try:
        with closing(get_connection()) as connection:
            with connection.cursor() as cursor:
                cursor.execute("SELECT VERSION() AS mysql_version")
                row = cursor.fetchone()

        return {
            "status": "connected",
            "mysql_version": row["mysql_version"] if row else "unknown",
        }
    except pymysql.MySQLError as exc:
        raise HTTPException(
            status_code=500, detail=f"MySQL connection failed: {exc}"
        ) from exc


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("fastApi:app", host="0.0.0.0", port=8000, reload=False)
