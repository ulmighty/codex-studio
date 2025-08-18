"""Voice engine provider interface."""
from __future__ import annotations

from typing import Protocol


class VoiceEngineProvider(Protocol):
    """Protocol for voice transcription engines."""

    def transcribe(self, audio: bytes) -> str:
        """Return text transcription for the given audio bytes."""
