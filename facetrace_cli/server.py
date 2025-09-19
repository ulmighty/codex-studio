"""Minimal ASGI app for the FaceTrace CLI."""

from __future__ import annotations

import json
import time
from typing import Any, Dict


async def app(scope: Dict[str, Any], receive, send) -> None:  # type: ignore[override]
    """Serve a simple JSON response for health checks.

    The CLI only requires a lightweight ASGI application so that the
    ``facetrace serve`` command can expose a heartbeat endpoint when uvicorn
    boots. The implementation is intentionally dependency-free.
    """

    if scope.get("type") != "http":
        raise RuntimeError("facetrace_cli.server.app only handles HTTP requests")

    await receive()  # Drain the initial request event.

    body = json.dumps(
        {
            "status": "ok",
            "service": "facetrace",
            "timestamp": time.time(),
        }
    ).encode("utf-8")

    await send(
        {
            "type": "http.response.start",
            "status": 200,
            "headers": [(b"content-type", b"application/json; charset=utf-8")],
        }
    )
    await send({"type": "http.response.body", "body": body, "more_body": False})
