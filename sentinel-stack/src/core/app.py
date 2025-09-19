from __future__ import annotations

import logging
import os
from pathlib import Path
from typing import List, TYPE_CHECKING

if TYPE_CHECKING:  # pragma: no cover - for static typing only
    from PyQt6.QtWidgets import QApplication, QMainWindow, QTabWidget
else:  # pragma: no cover - executed during runtime
    if os.environ.get("RUNNING_TESTS") == "1":
        try:
            from PyQt6.QtWidgets import QApplication, QMainWindow, QTabWidget  # type: ignore
        except Exception:
            class QApplication:  # type: ignore
                """Minimal QApplication stub for testing."""

                _instance: "QApplication | None" = None

                def __init__(self, *_args, **_kwargs) -> None:
                    QApplication._instance = self

                @classmethod
                def instance(cls) -> "QApplication | None":
                    return cls._instance

                def exec(self) -> None:
                    return None

            class QMainWindow:  # type: ignore
                def __init__(self, *_args, **_kwargs) -> None:
                    self._central_widget = None

                def setWindowTitle(self, *_args, **_kwargs) -> None:
                    return None

                def resize(self, *_args, **_kwargs) -> None:
                    return None

                def setCentralWidget(self, widget) -> None:  # type: ignore[override]
                    self._central_widget = widget

                def show(self) -> None:  # pragma: no cover - trivial
                    return None

                def closeEvent(self, _event) -> None:  # pragma: no cover - trivial
                    return None

            class QTabWidget:  # type: ignore
                def __init__(self) -> None:
                    self._tabs: list = []

                def addTab(self, widget, name: str) -> None:
                    self._tabs.append((widget, name))
    else:  # pragma: no cover - requires PyQt runtime
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
