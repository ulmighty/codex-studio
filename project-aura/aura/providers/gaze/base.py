"""Gaze estimation provider interface."""
from __future__ import annotations

from typing import Protocol


class GazeProvider(Protocol):
    """Protocol for gaze estimation engines."""

    def quadrant(self) -> str:
        """Return the currently focused screen quadrant."""
