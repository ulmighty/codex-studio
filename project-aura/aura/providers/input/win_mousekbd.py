"""Windows mouse/keyboard provider (mock)."""
from __future__ import annotations

from .base import MouseKeyboardProvider


class WinMouseKeyboardProvider(MouseKeyboardProvider):
    """Mock provider storing last action for verification in tests."""

    def __init__(self) -> None:
        self.last_move = (0, 0)
        self.last_click = ""

    def move(self, x: int, y: int) -> None:
        self.last_move = (x, y)

    def click(self, button: str = "left") -> None:
        self.last_click = button
