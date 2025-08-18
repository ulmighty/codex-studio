"""Thin wrappers around Windows APIs.

Only the pieces required by the sample implementation are provided.  The real
project would use ``ctypes`` or ``pywin32``; here we simply define placeholders
so that unit tests can run on any platform.
"""
from __future__ import annotations

from dataclasses import dataclass


@dataclass
class RECT:
    left: int
    top: int
    right: int
    bottom: int


def get_primary_monitor() -> RECT:
    """Return a fake 1920x1080 monitor rectangle."""

    return RECT(0, 0, 1920, 1080)
