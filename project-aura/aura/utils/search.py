"""Simple text search utilities for the contextual recall feature."""
from __future__ import annotations

from pathlib import Path
from typing import List


def search_logs(directory: Path, term: str) -> List[Path]:
    """Return all files containing ``term``."""

    results: List[Path] = []
    for path in directory.glob("*.log"):
        if term.lower() in path.read_text(encoding="utf-8").lower():
            results.append(path)
    return results
