"""Feature F5: Application awareness and profile loading."""
from __future__ import annotations

from pathlib import Path
from typing import Any, Dict

import yaml  # type: ignore[import-untyped]

from ..providers.appaware.base import AppAwarenessProvider


class ProfileManager:
    """Load YAML profiles based on active application."""

    def __init__(self, directory: Path) -> None:
        self.directory = directory
        self.cache: Dict[str, Dict[str, Any]] = {}

    def load(self, name: str) -> Dict[str, Any]:
        if name in self.cache:
            return self.cache[name]
        path = self.directory / f"{name}_profile.yaml"
        data: Dict[str, Any] = yaml.safe_load(path.read_text(encoding="utf-8"))
        self.cache[name] = data
        return data


def active_profile(provider: AppAwarenessProvider, manager: ProfileManager) -> Dict[str, Any]:
    app = provider.active_app()
    return manager.load(app)
