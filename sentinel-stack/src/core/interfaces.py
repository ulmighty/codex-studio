from __future__ import annotations

from abc import ABC, abstractmethod
from PyQt6.QtWidgets import QWidget
from typing import Dict


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
