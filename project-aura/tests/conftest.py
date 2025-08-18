import sys
from pathlib import Path

# Ensure the ``aura`` package is importable when tests run from repository root.
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
