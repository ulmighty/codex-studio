"""Windows foreground window detection (mock)."""
from __future__ import annotations

from .base import AppAwarenessProvider


class Win32ForegroundProvider(AppAwarenessProvider):
    """Return a static application name for tests."""

    def active_app(self) -> str:
        return "default_app"
