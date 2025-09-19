"""FaceTrace CLI package."""

from __future__ import annotations

import os
from pathlib import Path

_DEFAULT_HOME = Path.home() / ".facetrace"
FACETRACE_HOME = (
    Path(os.environ.get("FACETRACE_HOME", _DEFAULT_HOME))
    .expanduser()
    .resolve(strict=False)
)

__all__ = ["FACETRACE_HOME"]
