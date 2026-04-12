from __future__ import annotations

from contextlib import closing
from datetime import datetime, timedelta
from typing import Any

import pymysql
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, model_validator

from sql_creator import CRUD, SQLBuilderError, build_sql


router = APIRouter(prefix="/reservation", tags=["reservation"])

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


class ReservationCreateRequest(BaseModel):
    user_id: int
    facility_id: int
    start_date: datetime
    end_date: datetime

    @model_validator(mode="after")
    def validate_dates(self) -> "ReservationCreateRequest":
        now = datetime.now()

        if self.start_date <= now:
            raise ValueError("예약 시작 시간은 현재 시간 이후여야 합니다.")

        if self.end_date <= self.start_date:
            raise ValueError("예약 종료 시간은 시작 시간보다 늦어야 합니다.")

        if self.end_date - self.start_date > timedelta(hours=24):
            raise ValueError("예약은 최대 24시간까지만 가능합니다.")

        return self


def set_connection_factory(factory: Any) -> None:
    global connection_factory
    connection_factory = factory


def get_connection() -> pymysql.connections.Connection:
    if connection_factory is None:
        raise RuntimeError("DB 연결 팩토리가 설정되어 있지 않습니다.")
    return connection_factory()


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


def has_overlapping_reservation(
    facility_id: int,
    start_date: datetime,
    end_date: datetime,
) -> bool:
    """
    겹침 조건:
    기존.start < 새.end AND 기존.end > 새.start
    """
    try:
        with closing(get_connection()) as connection:
            with connection.cursor() as cursor:
                cursor.execute(
                    """
                    SELECT COUNT(*) AS cnt
                    FROM reservation
                    WHERE facility_id = %s
                      AND reservation_state = 1
                      AND reservation_start_date < %s
                      AND reservation_end_date > %s
                    """,
                    (facility_id, end_date, start_date),
                )
                row = cursor.fetchone()
                return (row or {}).get("cnt", 0) > 0
    except pymysql.MySQLError as exc:
        raise HTTPException(status_code=500, detail=f"예약 중복 확인 실패: {exc}") from exc


@router.post("", status_code=201)
def create_reservation(request: ReservationCreateRequest) -> dict:
    if has_overlapping_reservation(
        facility_id=request.facility_id,
        start_date=request.start_date,
        end_date=request.end_date,
    ):
        raise HTTPException(status_code=400, detail="해당 시간대에 이미 예약이 있습니다.")

    try:
        created_at = datetime.now()

        sql, params = build_sql(
            CRUD.CREATE,
            RESERVATION_TABLE,
            attribute_name=RESERVATION_CREATE_COLUMNS,
            attribute_value=[
                request.start_date,
                request.end_date,
                1,  # 완료/활성 예약
                created_at,
                request.user_id,
                request.facility_id,
            ],
        )
    except SQLBuilderError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    try:
        with closing(get_connection()) as connection:
            with connection.cursor() as cursor:
                cursor.execute(sql, params)
                reservation_id = cursor.lastrowid
            connection.commit()
    except pymysql.MySQLError as exc:
        raise HTTPException(status_code=500, detail=f"예약 생성 실패: {exc}") from exc

    return {
        "reservation_id": reservation_id,
        "reservation_start_date": request.start_date,
        "reservation_end_date": request.end_date,
        "reservation_state": 1,
        "reservation_date": created_at,
        "user_id": request.user_id,
        "facility_id": request.facility_id,
    }


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


@router.get("/{reservation_id}")
def get_reservation_detail(reservation_id: int) -> dict:
    try:
        with closing(get_connection()) as connection:
            with connection.cursor() as cursor:
                cursor.execute(
                    """
                    SELECT 
                        r.reservation_id,
                        r.reservation_start_date,
                        r.reservation_end_date,
                        r.reservation_state,
                        r.reservation_date,
                        r.user_id,
                        r.facility_id,
                        f.f_name AS facility_name,
                        f.f_info AS facility_info,
                        f.f_image AS facility_image
                    FROM reservation r
                    JOIN facility f ON r.facility_id = f.f_id
                    WHERE r.reservation_id = %s
                    """,
                    (reservation_id,),
                )
                row = cursor.fetchone()

        if not row:
            raise HTTPException(status_code=404, detail="예약 없음")

        return row

    except pymysql.MySQLError as exc:
        raise HTTPException(status_code=500, detail=f"예약 상세 조회 실패: {exc}") from exc


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