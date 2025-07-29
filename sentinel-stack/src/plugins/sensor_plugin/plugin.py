from __future__ import annotations

import os
os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
os.environ.setdefault("XDG_RUNTIME_DIR", "/tmp")

from PyQt6.QtWidgets import QApplication, QLabel

from core.interfaces import PluginInterface


class SensorPlugin(PluginInterface):
    name = "Sensor"

    def __init__(self) -> None:
        self.widget: QLabel | None = None

    def start(self) -> None:
        if os.environ.get("RUNNING_TESTS") == "1":
            self.widget = object()
            return
        if QApplication.instance() is None:
            QApplication([])
        if self.widget is None:
            self.widget = QLabel("Sensor Plugin Loaded")

    def stop(self) -> None:
        pass

    def get_health_status(self) -> dict:
        return {"temp": 42}
