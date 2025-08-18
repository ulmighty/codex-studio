"""Coordinate mapping utilities."""
from __future__ import annotations


def clamp(value: float, minimum: float, maximum: float) -> float:
    return max(min(value, maximum), minimum)


def map_range(value: float, in_min: float, in_max: float, out_min: float, out_max: float) -> float:
    """Map a value from one range to another."""

    if in_max - in_min == 0:
        return out_min
    proportion = (value - in_min) / (in_max - in_min)
    return out_min + proportion * (out_max - out_min)
