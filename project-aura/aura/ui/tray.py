"""System tray UI using PyQt6."""
from __future__ import annotations

from PyQt6 import QtWidgets


def create_tray(app: QtWidgets.QApplication) -> QtWidgets.QSystemTrayIcon:
    tray = QtWidgets.QSystemTrayIcon()
    tray.setToolTip("Project Aura")
    tray.show()
    return tray
