"""Status toast (placeholder)."""
from __future__ import annotations

from PyQt6 import QtWidgets


class StatusToast(QtWidgets.QLabel):
    def __init__(self, text: str) -> None:  # pragma: no cover - UI
        super().__init__(text)
        self.setWindowTitle("Status")
