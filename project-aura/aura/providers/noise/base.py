"""Noise suppression provider interface."""
from __future__ import annotations

from typing import Protocol


class NoiseSuppressor(Protocol):
    """Process audio frames and return denoised bytes."""

    frame_size: int

    def process(self, frame: bytes) -> bytes:
        """Process a single frame of audio."""
