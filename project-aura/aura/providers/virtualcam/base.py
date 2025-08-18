"""Virtual camera provider interface."""
from __future__ import annotations

from typing import Protocol


class VirtualCameraProvider(Protocol):
    """Protocol for virtual camera output."""

    def start(self) -> None:
        """Begin streaming to the virtual camera."""

    def stop(self) -> None:
        """Stop streaming."""
