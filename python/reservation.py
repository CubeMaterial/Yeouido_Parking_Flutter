from __future__ import annotations

from contextlib import closing
from datetime import datetime
from typing import Any

import pymysql
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from sql_creator import CRUD, SQLBuilderError, build_sql


router = APIRouter(prefix="/reservation", tags=["reservation"])

# =========================
# 설정
# =========================

RESERVATION_TABLE = "reservation"

RESERVATION_CREATE_COLUMNS = [
    "reservation_start_date",
    "reservation_end_date",
    "reservation_state",
    "reservation_date",
    "user_id",
    "facility_id",
]

connection_factory: Any = None


# =========================
# Request 모델
# =========================

class ReservationCreateRequest(BaseModel):
    user_id: int
    facility_id: int
    start_date: datetime
    end_date: datetime


# =========================
# DB 연결
# =========================

def set_connection_factory(factory: Any) -> None:
    global connection_factory
    connection_factory = factory


def get_connection() -> pymysql.connections.Connection:
    if connection_factory is None:
        raise RuntimeError("DB 연결 팩토리가 설정되어 있지 않습니다.")
    return connection_factory()


# =========================
# 공통 실행 함수
# =========================

def execute_write(sql: str, params: list[Any]) -> int:
    try:
        with closing(get_connection()) as connection:
            with connection.cursor() as cursor:
                affected_rows = cursor.execute(sql, params)
            connection.commit()
            return affected_rows
    except pymysql.MySQLError as exc:
        raise HTTPException(status_code=500, detail=f"DB 작업 실패: {exc}") from exc


def execute_read(sql: str, params: list[Any]) -> list[dict]:
    try:
        with closing(get_connection()) as connection:
            with connection.cursor() as cursor:
                cursor.execute(sql, params)
                return cursor.fetchall()
    except pymysql.MySQLError as exc:
        raise HTTPException(status_code=500, detail=f"DB 조회 실패: {exc}") from exc


# =========================
# API
# =========================

# 1️⃣ 예약 생성
@router.post("", status_code=201)
def create_reservation(request: ReservationCreateRequest) -> dict[str, str]:
    try:
        sql, params = build_sql(
            CRUD.CREATE,
            RESERVATION_TABLE,
            attribute_name=RESERVATION_CREATE_COLUMNS,
            attribute_value=[
                request.start_date,
                request.end_date,
                1,  # 상태 (1 = 완료)
                datetime.now(),
                request.user_id,
                request.facility_id,
            ],
        )
    except SQLBuilderError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    execute_write(sql, params)
    return {"status": "created"}


# 2️⃣ 사용자 예약 목록 조회
@router.get("/user/{user_id}")
def get_reservations(user_id: int) -> list[dict]:
    try:
        sql, params = build_sql(
            CRUD.READ,
            RESERVATION_TABLE,
            condition_attribute_name=["user_id"],
            condition_attribute_value=[user_id],
        )
    except SQLBuilderError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    return execute_read(sql, params)


# 3️⃣ 예약 상세 조회
@router.get("/{reservation_id}")
def get_reservation_detail(reservation_id: int) -> dict:
    try:
        sql, params = build_sql(
            CRUD.READ,
            RESERVATION_TABLE,
            condition_attribute_name=["reservation_id"],
            condition_attribute_value=[reservation_id],
        )
    except SQLBuilderError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    rows = execute_read(sql, params)

    if not rows:
        raise HTTPException(status_code=404, detail="예약 없음")

    return rows[0]


# 4️⃣ 예약 삭제 (옵션)
@router.delete("/{reservation_id}")
def delete_reservation(reservation_id: int) -> dict[str, Any]:
    try:
        sql, params = build_sql(
            CRUD.DELETE,
            RESERVATION_TABLE,
            condition_attribute_name=["reservation_id"],
            condition_attribute_value=[reservation_id],
        )
    except SQLBuilderError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    affected = execute_write(sql, params)
    return {"status": "deleted", "affected_rows": affected}