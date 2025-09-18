from __future__ import annotations

import os
from abc import ABC, abstractmethod
from typing import Dict, TYPE_CHECKING

if TYPE_CHECKING:
    from PyQt6.QtWidgets import QWidget
else:  # pragma: no cover - exercised indirectly via tests
    if os.environ.get("RUNNING_TESTS") == "1":
        try:
            from PyQt6.QtWidgets import QWidget  # type: ignore
        except Exception:  # pragma: no cover - executed when Qt libraries are unavailable
            class QWidget:  # type: ignore
                """Fallback QWidget stub used for headless testing."""

                pass
    else:  # pragma: no cover - requires PyQt runtime
        from PyQt6.QtWidgets import QWidget


class PluginInterface(ABC):
    """Base class for SentinelStack plugins."""

    name: str
    widget: QWidget

    @abstractmethod
    def start(self) -> None:
        """Start the plugin."""

    @abstractmethod
    def stop(self) -> None:
        """Stop the plugin."""

    @abstractmethod
    def get_health_status(self) -> Dict[str, object]:
        """Return a health status dictionary."""
