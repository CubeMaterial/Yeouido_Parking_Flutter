from __future__ import annotations

from contextlib import closing
from datetime import datetime
import secrets
from typing import Any

import pymysql
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, EmailStr, Field

from sql_creator import CRUD, SQLBuilderError, build_sql


router = APIRouter(prefix="/auth", tags=["auth"])

USER_TABLE = "user"
USER_LOGIN_COLUMNS = [
    "user_id",
    "user_email",
    "user_password",
    "user_date",
    "user_name",
    "user_phone",
]
USER_CREATE_COLUMNS = [
    "user_email",
    "user_password",
    "user_date",
    "user_name",
    "user_phone",
]

ADMIN_TABLE = "admin"
ADMIN_LOGIN_COLUMNS = [
    "admin_id",
    "admin_email",
    "admin_password",
    "admin_name",
]

connection_factory: Any = None


class UserLoginRequest(BaseModel):
    user_email: EmailStr | None = None
    user_password: str | None = Field(default=None, min_length=1, max_length=128)
    email: EmailStr | None = None
    password: str | None = Field(default=None, min_length=1, max_length=128)


class UserSignupRequest(BaseModel):
    user_email: EmailStr
    user_password: str = Field(min_length=8, max_length=128)
    user_name: str | None = Field(default=None, max_length=45)
    user_phone: str = Field(min_length=1, max_length=45)


class AdminLoginRequest(BaseModel):
    admin_email: EmailStr | None = None
    admin_password: str | None = Field(default=None, min_length=1, max_length=128)
    email: EmailStr | None = None
    password: str | None = Field(default=None, min_length=1, max_length=128)


def set_connection_factory(factory: Any) -> None:
    global connection_factory
    connection_factory = factory


def get_auth_connection() -> pymysql.connections.Connection:
    if connection_factory is None:
        raise RuntimeError("DB 연결 팩토리가 설정되어 있지 않습니다.")
    return connection_factory()


def request_user_email(request: UserLoginRequest) -> str:
    user_email = request.user_email or request.email
    if user_email is None:
        raise HTTPException(status_code=422, detail="이메일이 필요합니다.")
    return str(user_email).strip().lower()


def request_user_password(request: UserLoginRequest) -> str:
    user_password = request.user_password or request.password
    if user_password is None:
        raise HTTPException(status_code=422, detail="비밀번호가 필요합니다.")
    return user_password


def request_admin_email(request: AdminLoginRequest) -> str:
    admin_email = request.admin_email or request.email
    if admin_email is None:
        raise HTTPException(status_code=422, detail="관리자 이메일이 필요합니다.")
    return str(admin_email).strip().lower()


def request_admin_password(request: AdminLoginRequest) -> str:
    admin_password = request.admin_password or request.password
    if admin_password is None:
        raise HTTPException(status_code=422, detail="관리자 비밀번호가 필요합니다.")
    return admin_password


def execute_read_one(sql: str, params: list[Any]) -> dict[str, Any] | None:
    try:
        with closing(get_auth_connection()) as connection:
            with connection.cursor() as cursor:
                cursor.execute(sql, params)
                return cursor.fetchone()
    except pymysql.MySQLError as exc:
        raise HTTPException(status_code=500, detail=f"DB 조회에 실패했습니다: {exc}") from exc


def get_user_by_email(user_email: str) -> dict[str, Any] | None:
    try:
        sql, params = build_sql(
            CRUD.READ,
            USER_TABLE,
            attribute_name=USER_LOGIN_COLUMNS,
            condition_attribute_name=["user_email"],
            condition_attribute_value=[user_email],
        )
    except SQLBuilderError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    return execute_read_one(sql, params)


def get_admin_by_email(admin_email: str) -> dict[str, Any] | None:
    try:
        sql, params = build_sql(
            CRUD.READ,
            ADMIN_TABLE,
            attribute_name=ADMIN_LOGIN_COLUMNS,
            condition_attribute_name=["admin_email"],
            condition_attribute_value=[admin_email],
        )
    except SQLBuilderError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    return execute_read_one(sql, params)


@router.post("/login")
def login_user(request: UserLoginRequest) -> dict[str, Any]:
    user_email = request_user_email(request)
    user_password = request_user_password(request)
    user = get_user_by_email(user_email)

    if user is None:
        raise HTTPException(status_code=404, detail="등록된 사용자 계정이 아닙니다.")

    stored_password = str(user["user_password"])
    if not secrets.compare_digest(
        user_password.encode("utf-8"),
        stored_password.encode("utf-8"),
    ):
        raise HTTPException(
            status_code=401,
            detail="이메일 또는 비밀번호가 올바르지 않습니다.",
        )

    return {
        "status": "authenticated",
        "user_id": user["user_id"],
        "user_email": user["user_email"],
        "user_name": user["user_name"],
        "user_phone": user["user_phone"],
        "user_date": user["user_date"],
    }


@router.post("/users", status_code=201)
def create_user(request: UserSignupRequest) -> dict[str, Any]:
    user_email = str(request.user_email).strip().lower()
    user_phone = request.user_phone.strip()
    user_name = request.user_name.strip() if request.user_name else None

    if not user_phone:
        raise HTTPException(status_code=422, detail="전화번호가 필요합니다.")

    if get_user_by_email(user_email) is not None:
        raise HTTPException(status_code=409, detail="이미 가입된 이메일입니다.")

    created_at = datetime.now()

    try:
        sql, params = build_sql(
            CRUD.CREATE,
            USER_TABLE,
            attribute_name=USER_CREATE_COLUMNS,
            attribute_value=[
                user_email,
                request.user_password,
                created_at,
                user_name,
                user_phone,
            ],
        )
    except SQLBuilderError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    try:
        with closing(get_auth_connection()) as connection:
            with connection.cursor() as cursor:
                cursor.execute(sql, params)
                user_id = cursor.lastrowid
            connection.commit()
    except pymysql.MySQLError as exc:
        raise HTTPException(status_code=500, detail=f"회원가입에 실패했습니다: {exc}") from exc

    return {
        "status": "created",
        "user_id": user_id,
        "user_email": user_email,
        "user_name": user_name,
        "user_phone": user_phone,
        "user_date": created_at,
    }


@router.post("/admin/login")
def login_admin(request: AdminLoginRequest) -> dict[str, Any]:
    admin_email = request_admin_email(request)
    admin_password = request_admin_password(request)
    admin = get_admin_by_email(admin_email)

    if admin is None:
        raise HTTPException(status_code=404, detail="등록된 관리자 계정이 아닙니다.")

    stored_password = str(admin["admin_password"])
    if not secrets.compare_digest(
        admin_password.encode("utf-8"),
        stored_password.encode("utf-8"),
    ):
        raise HTTPException(
            status_code=401,
            detail="관리자 이메일 또는 비밀번호가 올바르지 않습니다.",
        )

    return {
        "status": "authenticated",
        "admin_id": admin["admin_id"],
        "admin_email": admin["admin_email"],
        "admin_name": admin["admin_name"],
    }
