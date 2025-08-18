"""pyvirtualcam provider that expects OBS VirtualCam to be installed."""
from __future__ import annotations

from .base import VirtualCameraProvider


class PyVirtualCamOBS(VirtualCameraProvider):
    """Mock implementation for unit testing."""

    def start(self) -> None:  # pragma: no cover - trivial
        pass

    def stop(self) -> None:  # pragma: no cover - trivial
        pass
