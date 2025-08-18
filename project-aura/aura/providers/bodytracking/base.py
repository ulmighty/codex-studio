"""Body tracking provider interfaces."""
from __future__ import annotations

from dataclasses import dataclass
from typing import Dict, Protocol


@dataclass
class Joint:
    x: float
    y: float
    z: float


class BodyTrackingProvider(Protocol):
    """Protocol for body tracking implementations."""

    def get_joints(self) -> Dict[str, Joint]:
        """Return a mapping of joint names to their positions."""

    def get_hand_state(self) -> Dict[str, str]:
        """Return current hand states."""
