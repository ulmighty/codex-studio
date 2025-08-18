"""Mouse and keyboard provider interface."""
from __future__ import annotations

from typing import Protocol


class MouseKeyboardProvider(Protocol):
    """Protocol for emitting mouse and keyboard events."""

    def move(self, x: int, y: int) -> None:
        """Move cursor to absolute coordinates."""

    def click(self, button: str = "left") -> None:
        """Trigger a mouse click."""
