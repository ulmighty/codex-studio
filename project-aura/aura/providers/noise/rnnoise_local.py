"""RNNoise based noise suppressor (mock implementation)."""
from __future__ import annotations

from .base import NoiseSuppressor


class RNNoiseLocal(NoiseSuppressor):
    """Simple pass-through noise suppressor used for tests.

    The class exposes ``frame_size`` which is verified by unit tests to ensure
    audio buffers are split correctly (480 samples at 48kHz).
    """

    frame_size: int = 480 * 2  # 480 samples * 2 bytes (16-bit)

    def process(self, frame: bytes) -> bytes:
        if len(frame) != self.frame_size:
            raise ValueError("invalid frame size")
        return frame
