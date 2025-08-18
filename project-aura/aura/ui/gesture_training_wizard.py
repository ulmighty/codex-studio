"""Wizard for custom gesture training (placeholder)."""
from __future__ import annotations

from PyQt6 import QtWidgets


class GestureTrainingWizard(QtWidgets.QWizard):
    def __init__(self) -> None:  # pragma: no cover - UI
        super().__init__()
        self.setWindowTitle("Gesture Training")
        self.addPage(QtWidgets.QWizardPage())
