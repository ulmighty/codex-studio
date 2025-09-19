from __future__ import annotations

import sys
from pathlib import Path

# Ensure the repository root is importable for local packages.
PROJECT_ROOT = Path(__file__).resolve().parents[2]
REPO_ROOT = PROJECT_ROOT.parent.parent
for path in (str(REPO_ROOT), str(PROJECT_ROOT)):
    if path not in sys.path:
        sys.path.insert(0, path)
