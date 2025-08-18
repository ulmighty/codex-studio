"""Feature F4: Warp cursor based on gaze quadrant."""
from __future__ import annotations

from ..providers.gaze.base import GazeProvider
from ..providers.input.base import MouseKeyboardProvider
from ..utils.windows_api import get_primary_monitor


def warp_cursor(gaze: GazeProvider, io: MouseKeyboardProvider) -> None:
    rect = get_primary_monitor()
    quadrant = gaze.quadrant()
    x = rect.right // 2
    y = rect.bottom // 2
    if quadrant == "top_left":
        x, y = rect.left + rect.right // 4, rect.top + rect.bottom // 4
    elif quadrant == "top_right":
        x, y = rect.right - rect.right // 4, rect.top + rect.bottom // 4
    elif quadrant == "bottom_left":
        x, y = rect.left + rect.right // 4, rect.bottom - rect.bottom // 4
    elif quadrant == "bottom_right":
        x, y = rect.right - rect.right // 4, rect.bottom - rect.bottom // 4
    io.move(x, y)
