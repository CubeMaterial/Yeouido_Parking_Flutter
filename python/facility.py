from __future__ import annotations

from contextlib import closing
from typing import Any

import pymysql
from fastapi import APIRouter, HTTPException

from sql_creator import CRUD, SQLBuilderError, build_sql


router = APIRouter(prefix="/facilities", tags=["facilities"])

FACILITY_TABLE = "facility"

connection_factory: Any = None


def set_connection_factory(factory: Any) -> None:
    global connection_factory
    connection_factory = factory


def get_connection() -> pymysql.connections.Connection:
    if connection_factory is None:
        raise RuntimeError("DB 연결 팩토리가 설정되어 있지 않습니다.")
    return connection_factory()


def execute_read(sql: str, params: list[Any]) -> list[dict]:
    try:
        with closing(get_connection()) as connection:
            with connection.cursor() as cursor:
                cursor.execute(sql, params)
                return cursor.fetchall()
    except pymysql.MySQLError as exc:
        raise HTTPException(status_code=500, detail=f"DB 조회 실패: {exc}") from exc


# 시설 탭용: 전체 시설 조회
@router.get("")
def get_all_facilities() -> list[dict]:
    try:
        sql, params = build_sql(
            CRUD.READ,
            FACILITY_TABLE,
            select_all_if_attribute_empty=True,
        )
    except SQLBuilderError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    return execute_read(sql, params)


# 예약 탭용: 예약 가능한 시설만 조회
@router.get("/reservable")
def get_reservable_facilities() -> list[dict]:
    try:
        sql, params = build_sql(
            CRUD.READ,
            FACILITY_TABLE,
            condition_attribute_name=["f_possible"],
            condition_attribute_value=[1],
            select_all_if_attribute_empty=True,
        )
    except SQLBuilderError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    return execute_read(sql, params)


@router.get("/{facility_id}")
def get_facility_detail(facility_id: int) -> dict:
    try:
        sql, params = build_sql(
            CRUD.READ,
            FACILITY_TABLE,
            condition_attribute_name=["f_id"],
            condition_attribute_value=[facility_id],
            select_all_if_attribute_empty=True,
        )
    except SQLBuilderError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    rows = execute_read(sql, params)

    if not rows:
        raise HTTPException(status_code=404, detail="시설 없음")

    return rows[0]