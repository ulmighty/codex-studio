"""Configuration loader for Project Aura.

This module loads the global ``config.yaml`` file and exposes a dataclass
representation used throughout the application.  The configuration follows the
schema defined in the project requirements and allows switching provider
implementations at runtime using a provider/strategy pattern.
"""
from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict

import yaml  # type: ignore[import-untyped]

CONFIG_PATH = Path(__file__).resolve().parent.parent.parent / "config.yaml"


@dataclass
class ProviderConfig:
    """Mapping of provider interfaces to implementation names."""

    bodytracking: str
    voice: str
    wakeword: str
    noise: str
    virtualcam: str
    gestures: str
    gaze: str
    appaware: str
    input: str


@dataclass
class LLMConfig:
    """Configuration for the language model provider."""

    model: str


@dataclass
class ThresholdConfig:
    smoothing: float
    z_push_mm: float
    z_pull_mm: float
    dwell_ms: int
    zen_mode_seconds: int


@dataclass
class PrivacyConfig:
    voice_log_retention_days: int
    pii_redaction: bool


@dataclass
class AppConfig:
    providers: ProviderConfig
    llm: LLMConfig
    profiles: Dict[str, str]
    thresholds: ThresholdConfig
    privacy: PrivacyConfig


class ConfigError(RuntimeError):
    """Raised when configuration loading fails."""


def load_config(path: Path = CONFIG_PATH) -> AppConfig:
    """Load the YAML configuration file and return :class:`AppConfig`.

    Parameters
    ----------
    path:
        Optional override path for unit testing.
    """

    try:
        raw: Dict[str, Any] = yaml.safe_load(path.read_text(encoding="utf-8"))
    except Exception as exc:  # pragma: no cover - exercised in smoke tests
        raise ConfigError(str(exc)) from exc

    providers = ProviderConfig(**raw["providers"])
    llm = LLMConfig(**raw["llm"])
    thresholds = ThresholdConfig(**raw["thresholds"])
    privacy = PrivacyConfig(**raw["privacy"])
    profiles = raw["profiles"]

    return AppConfig(
        providers=providers,
        llm=llm,
        profiles=profiles,
        thresholds=thresholds,
        privacy=privacy,
    )
