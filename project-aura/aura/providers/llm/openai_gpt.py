"""OpenAI GPT provider using the official client library (mock)."""
from __future__ import annotations


class OpenAIGPTProvider:
    """Deterministic mock provider."""

    def __init__(self, model: str = "gpt-4") -> None:
        self.model = model

    def complete(self, prompt: str) -> str:  # pragma: no cover - trivial
        return f"{self.model}: {prompt[:30]}"
