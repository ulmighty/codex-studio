"""Profiling helpers."""
from __future__ import annotations

import contextlib
import time
from typing import Iterator


@contextlib.contextmanager
def time_block(name: str) -> Iterator[float]:
    start = time.perf_counter()
    yield start
    end = time.perf_counter()
    print(f"{name}: {end - start:.4f}s")
