"""Utility functions for smoothing numeric streams."""
from __future__ import annotations

from collections import deque
from typing import Deque, Iterable


class RollingAverage:
    """Compute a rolling average over the last *n* samples."""

    def __init__(self, window: int) -> None:
        self.window = window
        self.values: Deque[float] = deque(maxlen=window)

    def add(self, value: float) -> float:
        self.values.append(value)
        return sum(self.values) / len(self.values)

    def extend(self, values: Iterable[float]) -> float:
        for v in values:
            self.values.append(v)
        return sum(self.values) / len(self.values)
