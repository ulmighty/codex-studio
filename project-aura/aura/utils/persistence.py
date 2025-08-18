"""Simple persistence helpers for local encrypted storage (mock)."""
from __future__ import annotations

import json
from pathlib import Path
from typing import Any


def save_json(path: Path, data: Any) -> None:
    path.write_text(json.dumps(data), encoding="utf-8")


def load_json(path: Path) -> Any:
    if not path.exists():
        return None
    return json.loads(path.read_text(encoding="utf-8"))
