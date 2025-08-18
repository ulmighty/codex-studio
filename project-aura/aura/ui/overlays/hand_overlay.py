"""Hand position overlay (placeholder)."""
from __future__ import annotations

from PyQt6 import QtWidgets


class HandOverlay(QtWidgets.QWidget):
    def __init__(self) -> None:  # pragma: no cover - UI
        super().__init__()
        self.setWindowTitle("Hand Overlay")
