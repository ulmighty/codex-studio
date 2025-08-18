"""App awareness provider interface."""
from __future__ import annotations

from typing import Protocol


class AppAwarenessProvider(Protocol):
    """Protocol for active-application detection."""

    def active_app(self) -> str:
        """Return the name of the foreground application."""
