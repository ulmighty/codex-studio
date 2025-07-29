from __future__ import annotations

from pathlib import Path
import sys

# Ensure project root is on path
ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from .app import run  # noqa: E402


if __name__ == "__main__":
    run()
