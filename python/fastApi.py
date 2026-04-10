from contextlib import closing

import pymysql
from fastapi import FastAPI, HTTPException


app = FastAPI(
    title="Yeouido Parking DB Connector",
    description="Simple FastAPI service for checking MySQL connectivity.",
    version="1.0.0",
)


DB_CONFIG = {
    "host": "ep-cycle.chaeqe2g4mnm.ap-northeast-2.rds.amazonaws.com",
    "port": 3306,
    "user": "admin",
    "password": "0513webapp!",
    "charset": "utf8mb4",
    "connect_timeout": 5,
    "read_timeout": 5,
    "write_timeout": 5,
    "cursorclass": pymysql.cursors.DictCursor,
}


def get_connection() -> pymysql.connections.Connection:
    return pymysql.connect(**DB_CONFIG)


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
