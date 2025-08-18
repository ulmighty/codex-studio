"""Wake-word detection provider interface."""
from __future__ import annotations

from typing import Protocol


class WakeWordProvider(Protocol):
    """Protocol for wake-word engines."""

    def detected(self, audio: bytes) -> bool:
        """Return ``True`` if the wake word is detected in the audio chunk."""
