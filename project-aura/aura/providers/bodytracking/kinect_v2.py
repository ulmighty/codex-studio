"""Kinect v2 body tracking provider.

The implementation is intentionally lightweight for the template project.
"""
from __future__ import annotations

from typing import Dict

from .base import Joint


class KinectV2Provider:
    """Minimal stand-in implementation for development and testing."""

    def get_joints(self) -> Dict[str, Joint]:
        return {"HandRight": Joint(0.5, 0.5, 0.5)}

    def get_hand_state(self) -> Dict[str, str]:
        return {"Right": "Open", "Left": "Open"}
