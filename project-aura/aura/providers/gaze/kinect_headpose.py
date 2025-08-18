"""Gaze estimation using Kinect head pose (mock)."""
from __future__ import annotations

from .base import GazeProvider


class KinectHeadPoseProvider(GazeProvider):
    """Return a static screen quadrant for testing."""

    def quadrant(self) -> str:
        return "top_left"
