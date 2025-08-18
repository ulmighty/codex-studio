"""Local Whisper transcription provider with optional RNNoise preprocessing."""
from __future__ import annotations


class WhisperLocalProvider:
    """Placeholder implementation performing a naive decode of bytes."""

    def __init__(self, use_rnnoise: bool = False) -> None:
        self.use_rnnoise = use_rnnoise

    def transcribe(self, audio: bytes) -> str:  # pragma: no cover - trivial
        try:
            return audio.decode("utf-8")
        except UnicodeDecodeError:
            return ""
