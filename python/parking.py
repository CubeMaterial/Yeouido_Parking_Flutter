from __future__ import annotations

from datetime import datetime, timezone
import logging
import os
import re
import socket
import ssl

import certifi
import httpx
from bs4 import BeautifulSoup
from fastapi import APIRouter, HTTPException


router = APIRouter(prefix="/parking", tags=["parking"])

REGION8_URL = "https://www.ihangangpark.kr/parking/region/region8"

logger = logging.getLogger(__name__)


def _upstream_verify_setting() -> str | bool | ssl.SSLContext:
    ca_bundle = os.getenv("UPSTREAM_CA_BUNDLE")
    if ca_bundle:
        return ca_bundle
    if os.getenv("UPSTREAM_INSECURE_SKIP_VERIFY") == "1":
        return False
    return certifi.where()


def _parse_int(text: str) -> int:
    digits = re.sub(r"[^0-9]", "", text or "")
    if not digits:
        return 0
    try:
        return int(digits)
    except ValueError:
        return 0


@router.get("/region8")
async def region8() -> dict:
    try:
        async with httpx.AsyncClient(
            timeout=httpx.Timeout(15.0, connect=5.0),
            verify=_upstream_verify_setting(),
            trust_env=False,
            headers={
                "User-Agent": "Mozilla/5.0 (YeouidoParkingFastAPI)",
                "Accept": "text/html,application/xhtml+xml",
                "Accept-Language": "ko-KR,ko;q=0.9,en-US;q=0.8,en;q=0.7",
                "Referer": "https://www.ihangangpark.kr/",
            },
            follow_redirects=True,
        ) as client:
            response = await client.get(REGION8_URL)
            response.raise_for_status()
    except httpx.HTTPStatusError as exc:
        upstream_status = exc.response.status_code
        logger.warning(
            "Upstream returned error status=%s url=%s",
            upstream_status,
            REGION8_URL,
            exc_info=True,
        )
        raise HTTPException(
            status_code=502,
            detail={
                "message": "Upstream returned non-2xx status",
                "upstream_status": upstream_status,
                "source_url": REGION8_URL,
            },
        ) from exc
    except httpx.ConnectError as exc:
        cause = exc.__cause__
        errno = getattr(cause, "errno", None)
        is_dns_error = isinstance(cause, socket.gaierror)
        is_ssl_verify_error = isinstance(cause, ssl.SSLCertVerificationError)
        logger.warning("Upstream connect failed url=%s", REGION8_URL, exc_info=True)
        raise HTTPException(
            status_code=502,
            detail={
                "message": "Upstream connect failed",
                "error": str(exc),
                "errno": errno,
                "hint": (
                    "DNS lookup failed"
                    if is_dns_error
                    else "TLS cert verify failed (set UPSTREAM_CA_BUNDLE or UPSTREAM_INSECURE_SKIP_VERIFY=1)"
                    if is_ssl_verify_error
                    else None
                ),
                "source_url": REGION8_URL,
            },
        ) from exc
    except httpx.HTTPError as exc:
        logger.warning("Upstream request failed url=%s", REGION8_URL, exc_info=True)
        raise HTTPException(
            status_code=502,
            detail={
                "message": f"Upstream request failed ({type(exc).__name__})",
                "error": str(exc),
                "source_url": REGION8_URL,
            },
        ) from exc

    soup = BeautifulSoup(response.text, "html.parser")
    tab = soup.select_one("#regionTab01")
    rows = tab.select("table tbody tr") if tab else []

    lots: list[dict] = []
    for row in rows:
        cells = [td.get_text(strip=True) for td in row.select("td")]
        if len(cells) < 4:
            continue

        name = cells[0].strip() or "주차장"
        total = _parse_int(cells[1])
        used = _parse_int(cells[2])
        available = _parse_int(cells[3])

        if used == 0 and total > 0 and available > 0:
            used = max(0, total - available)

        lots.append(
            {
                "name": name,
                "total": total,
                "used": used,
                "available": available,
                "raw": cells[:4],
            }
        )

    return {
        "source_url": REGION8_URL,
        "fetched_at": datetime.now(timezone.utc).isoformat(),
        "lots": lots,
    }
