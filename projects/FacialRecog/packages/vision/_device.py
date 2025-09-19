"""Helpers for querying hardware tuning metadata from a device manager."""

from __future__ import annotations

import logging
from typing import Any, Dict, List, Mapping, Tuple

LOGGER = logging.getLogger(__name__)


def extract_mapping(value: Any) -> Mapping[str, Any]:
    """Best-effort conversion of ``value`` into a mapping."""

    if isinstance(value, Mapping):
        return value
    if hasattr(value, "_asdict"):
        return value._asdict()
    if hasattr(value, "__dict__"):
        return value.__dict__
    return {}


def resolve_device_config(device_manager: Any, key: str) -> Mapping[str, Any]:
    """Resolve tuning metadata for ``key`` from ``device_manager``."""

    if device_manager is None:
        return {}

    if isinstance(device_manager, Mapping):
        return device_manager

    candidates: List[Tuple[str, Tuple[Any, ...], Dict[str, Any]]] = [
        ("get_inference_config", (key,), {}),
        ("get_detector_config", (key,), {}),
        ("resolve", (key,), {}),
        ("get", (key,), {}),
        ("__call__", (key,), {}),
        ("get", tuple(), {"name": key}),
        ("resolve", tuple(), {"component": key}),
    ]

    for attr, args, kwargs in candidates:
        method = getattr(device_manager, attr, None)
        if not callable(method):
            continue
        try:
            result = method(*args, **kwargs)
        except TypeError:
            try:
                result = method(*args)
            except Exception:  # pragma: no cover - defensive branch
                continue
        except Exception:  # pragma: no cover - defensive branch
            LOGGER.debug("device_manager.%s raised an exception", attr, exc_info=True)
            continue
        mapping = extract_mapping(result)
        if mapping:
            return mapping

    direct_mapping = extract_mapping(device_manager)
    if direct_mapping:
        return direct_mapping

    return {}


__all__ = ["extract_mapping", "resolve_device_config"]
