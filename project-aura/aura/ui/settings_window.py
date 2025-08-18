"""Settings window stub."""
from __future__ import annotations

from PyQt6 import QtWidgets


class SettingsWindow(QtWidgets.QWidget):
    def __init__(self) -> None:  # pragma: no cover - UI
        super().__init__()
        self.setWindowTitle("Aura Settings")
        layout = QtWidgets.QVBoxLayout(self)
        layout.addWidget(QtWidgets.QLabel("Settings go here"))
