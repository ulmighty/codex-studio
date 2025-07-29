from __future__ import annotations

import logging
from pathlib import Path
from typing import List

from PyQt6.QtWidgets import QApplication, QMainWindow, QTabWidget

from .interfaces import PluginInterface
from .plugin_loader import load_plugins

LOG_PATH = Path(__file__).resolve().parent.parent.parent / "logs"
LOG_PATH.mkdir(exist_ok=True)
logging.basicConfig(
    filename=LOG_PATH / "sentinel.log",
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)


class MainWindow(QMainWindow):
    def __init__(self) -> None:
        super().__init__()
        self.setWindowTitle("SentinelStack")
        self.resize(800, 600)
        self.tabs = QTabWidget()
        self.setCentralWidget(self.tabs)
        self.plugins: List[PluginInterface] = []

    def load_plugins(self) -> None:
        """Load and start plugins."""
        self.plugins = load_plugins()
        for plugin in self.plugins:
            plugin.start()
            self.tabs.addTab(plugin.widget, plugin.name)

    def closeEvent(self, event) -> None:  # type: ignore[override]
        for plugin in self.plugins:
            plugin.stop()
        super().closeEvent(event)


def run() -> None:
    """Run the SentinelStack application."""
    app = QApplication([])
    window = MainWindow()
    window.load_plugins()
    window.show()
    app.exec()
