"""Picovoice Porcupine wake-word provider (mock)."""
from __future__ import annotations


class PorcupineProvider:
    """Minimal wake-word detector used in tests."""

    def __init__(self, keyword: bytes = b"aura") -> None:
        self.keyword = keyword

    def detected(self, audio: bytes) -> bool:
        return self.keyword in audio
