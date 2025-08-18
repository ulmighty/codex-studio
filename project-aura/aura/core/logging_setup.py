"""Centralised logging configuration for Project Aura."""
from __future__ import annotations

import logging
from pathlib import Path
from typing import List

LOG_PATH = Path.home() / "project_aura.log"


def setup_logging(level: int = logging.INFO) -> None:
    """Configure root logger with a file handler and console output."""

    fmt = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    handlers: List[logging.Handler] = [
        logging.FileHandler(LOG_PATH),
        logging.StreamHandler(),
    ]
    logging.basicConfig(level=level, format=fmt, handlers=handlers)
