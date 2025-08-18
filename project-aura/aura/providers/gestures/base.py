"""Gesture recogniser provider interface."""
from __future__ import annotations

from typing import Protocol


class GestureRecognizerProvider(Protocol):
    """Protocol for gesture recognition engines."""

    def recognise(self, frame: bytes) -> str:
        """Return the recognised gesture label."""
