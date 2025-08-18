"""Feature F1: Kinect body tracking demonstration."""
from __future__ import annotations

from typing import Dict

from ..providers.bodytracking.base import BodyTrackingProvider, Joint


def track_joints(provider: BodyTrackingProvider) -> Dict[str, Joint]:
    """Return current joint mapping for diagnostics."""

    return provider.get_joints()
