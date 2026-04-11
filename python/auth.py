from __future__ import annotations

from contextlib import closing
from datetime import datetime
import base64
import hashlib
import secrets
from typing import Any

import pymysql
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, EmailStr, Field

from sql_creator import CRUD, SQLBuilderError, build_sql


router = APIRouter(prefix="/auth", tags=["auth"])

PASSWORD_HASH_ALGORITHM = "pbkdf2_sha256"
PASSWORD_HASH_ITERATIONS = 260_000
PASSWORD_SALT_BYTES = 16

USER_TABLE = "user"
USER_CREATE_COLUMNS = ["user_email", "user_password", "user_date", "user_name"]
USER_UPDATE_COLUMNS = {"user_email", "user_password", "user_name"}

connection_factory: Any = None


class UserCreateRequest(BaseModel):
    user_email: EmailStr
    user_password: str = Field(min_length=8, max_length=128)
    user_name: str | None = Field(default=None, max_length=45)


class UserUpdateRequest(BaseModel):
    user_email: EmailStr | None = None
    user_password: str | None = Field(default=None, min_length=8, max_length=128)
    user_name: str | None = Field(default=None, max_length=45)


def set_connection_factory(factory: Any) -> None:
    global connection_factory
    connection_factory = factory


def get_auth_connection() -> pymysql.connections.Connection:
    if connection_factory is None:
        raise RuntimeError("DB 연결 팩토리가 설정되어 있지 않습니다.")
    return connection_factory()


def hash_password(raw_password: str) -> str:
    salt = secrets.token_bytes(PASSWORD_SALT_BYTES)
    digest = hashlib.pbkdf2_hmac(
        "sha256",
        raw_password.encode("utf-8"),
        salt,
        PASSWORD_HASH_ITERATIONS,
    )
    salt_text = base64.urlsafe_b64encode(salt).decode("ascii").rstrip("=")
    digest_text = base64.urlsafe_b64encode(digest).decode("ascii").rstrip("=")
    return (
        f"{PASSWORD_HASH_ALGORITHM}"
        f"${PASSWORD_HASH_ITERATIONS}"
        f"${salt_text}"
        f"${digest_text}"
    )


def verify_password(raw_password: str, stored_password: str) -> bool:
    try:
        algorithm, iterations_text, salt_text, digest_text = stored_password.split("$")
        iterations = int(iterations_text)
    except ValueError:
        return False

    if algorithm != PASSWORD_HASH_ALGORITHM:
        return False

    salt = base64.urlsafe_b64decode(salt_text + "=" * (-len(salt_text) % 4))
    expected_digest = base64.urlsafe_b64decode(digest_text + "=" * (-len(digest_text) % 4))
    actual_digest = hashlib.pbkdf2_hmac(
        "sha256",
        raw_password.encode("utf-8"),
        salt,
        iterations,
    )
    return secrets.compare_digest(actual_digest, expected_digest)


def execute_write(sql: str, params: list[Any]) -> int:
    try:
        with closing(get_auth_connection()) as connection:
            with connection.cursor() as cursor:
                affected_rows = cursor.execute(sql, params)
            connection.commit()
            return affected_rows
    except pymysql.MySQLError as exc:
        raise HTTPException(status_code=500, detail=f"DB 작업에 실패했습니다: {exc}") from exc


@router.post("/users", status_code=201)
def create_user(request: UserCreateRequest) -> dict[str, str]:
    hashed_password = hash_password(request.user_password)

    try:
        sql, params = build_sql(
            CRUD.CREATE,
            USER_TABLE,
            attribute_name=USER_CREATE_COLUMNS,
            attribute_value=[
                request.user_email,
                hashed_password,
                datetime.now(),
                request.user_name,
            ],
        )
    except SQLBuilderError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    execute_write(sql, params)
    return {"status": "created"}


@router.patch("/users/{user_id}")
def update_user(user_id: int, request: UserUpdateRequest) -> dict[str, str | int]:
    update_data = request.model_dump(exclude_unset=True)

    if not update_data:
        raise HTTPException(status_code=400, detail="수정할 값이 없습니다.")

    if "user_password" in update_data:
        update_data["user_password"] = hash_password(update_data["user_password"])

    invalid_columns = sorted(set(update_data) - USER_UPDATE_COLUMNS)
    if invalid_columns:
        raise HTTPException(
            status_code=400,
            detail=f"허용되지 않은 컬럼입니다: {', '.join(invalid_columns)}",
        )

    try:
        sql, params = build_sql(
            CRUD.UPDATE,
            USER_TABLE,
            attribute_name=list(update_data.keys()),
            attribute_value=list(update_data.values()),
            condition_attribute_name=["user_id"],
            condition_attribute_value=[user_id],
        )
    except SQLBuilderError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    affected_rows = execute_write(sql, params)
    return {"status": "updated", "affected_rows": affected_rows}


@router.delete("/users/{user_id}")
def delete_user(user_id: int) -> dict[str, str | int]:
    try:
        sql, params = build_sql(
            CRUD.DELETE,
            USER_TABLE,
            condition_attribute_name=["user_id"],
            condition_attribute_value=[user_id],
        )
    except SQLBuilderError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    affected_rows = execute_write(sql, params)
    return {"status": "deleted", "affected_rows": affected_rows}
