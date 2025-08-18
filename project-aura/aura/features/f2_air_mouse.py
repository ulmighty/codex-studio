from __future__ import annotations

from dataclasses import dataclass

from ..providers.bodytracking.base import BodyTrackingProvider
from ..providers.input.base import MouseKeyboardProvider
from ..utils.mapping import map_range
from ..utils.smoothing import RollingAverage


@dataclass
class AirMouseConfig:
    """Configuration parameters for the air mouse."""

    z_push_mm: float
    z_pull_mm: float
    smoothing: float


class AirMouse:
    """Map hand movements to cursor actions."""

    def __init__(
        self,
        body: BodyTrackingProvider,
        io: MouseKeyboardProvider,
        config: AirMouseConfig,
    ) -> None:
        self.body = body
        self.io = io
        self.config = config
        self._smooth_x = RollingAverage(int(config.smoothing))
        self._smooth_y = RollingAverage(int(config.smoothing))

    def update(self) -> None:
        joints = self.body.get_joints()
        hand = joints.get("HandRight")
        if not hand:
            return
        x = self._smooth_x.add(hand.x)
        y = self._smooth_y.add(hand.y)
        # map 0..1 space to screen resolution (fake 1920x1080)
        px = int(map_range(x, 0, 1, 0, 1919))
        py = int(map_range(y, 0, 1, 0, 1079))
        self.io.move(px, py)

        # Determine click via Z push/pull thresholds
        if hand.z < self.config.z_push_mm:
            self.io.click("left")
        elif hand.z > self.config.z_pull_mm:
            self.io.click("right")
