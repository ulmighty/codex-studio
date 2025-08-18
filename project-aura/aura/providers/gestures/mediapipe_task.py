"""MediaPipe Tasks gesture recognition provider (mock)."""
from __future__ import annotations

from .base import GestureRecognizerProvider


class MediaPipeTaskProvider(GestureRecognizerProvider):
    """Return a static gesture label for testing."""

    def recognise(self, frame: bytes) -> str:
        return "open_hand"
