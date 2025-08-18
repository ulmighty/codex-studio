"""Language model provider abstraction."""
from __future__ import annotations

from typing import Protocol


class LLMProvider(Protocol):
    """Protocol for LLM interaction."""

    def complete(self, prompt: str) -> str:
        """Return a completion for the given prompt."""
