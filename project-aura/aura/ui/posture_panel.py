"""Panel used to display posture guidance."""
from __future__ import annotations

from PyQt6 import QtWidgets


class PosturePanel(QtWidgets.QWidget):
    def __init__(self) -> None:  # pragma: no cover - UI
        super().__init__()
        self.setWindowTitle("Posture Coach")
        self.label = QtWidgets.QLabel("Good posture", self)
        layout = QtWidgets.QVBoxLayout(self)
        layout.addWidget(self.label)
