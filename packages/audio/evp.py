"""EVP (Electronic Voice Phenomena) feature extraction utilities."""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Dict, Optional

import numpy as np

from .transcribe import DISCLAIMER, PathLike

try:  # pragma: no cover - optional dependency resolution
    import librosa  # type: ignore[import]
except ImportError:  # pragma: no cover - handled in _ensure_librosa
    librosa = None  # type: ignore[assignment]


@dataclass(slots=True)
class EvpAnomalyFlags:
    """Boolean anomaly flags derived from spectral heuristics."""

    is_silent: bool
    possible_clipping: bool
    high_noise: bool


@dataclass(slots=True)
class EvpFeatureSet:
    """Container for EVP-oriented acoustic features."""

    sample_rate: int
    duration: float
    features: Dict[str, float]
    anomaly_flags: EvpAnomalyFlags
    disclaimer: str = field(default=DISCLAIMER, init=False)


def _ensure_librosa() -> None:
    if librosa is None:  # pragma: no cover - executed when dependency missing
        raise RuntimeError(
            "The 'librosa' package is required to extract EVP features. "
            "Install it via 'pip install librosa'."
        )


def _summarise_feature(values: np.ndarray, prefix: str, output: Dict[str, float]) -> None:
    output[f"{prefix}_mean"] = float(np.mean(values))
    output[f"{prefix}_std"] = float(np.std(values))
    output[f"{prefix}_min"] = float(np.min(values))
    output[f"{prefix}_max"] = float(np.max(values))


def extract_evp_features(
    audio_path: PathLike,
    *,
    target_sr: int = 16_000,
    top_db: Optional[float] = 60.0,
) -> EvpFeatureSet:
    """Extract EVP-friendly spectral descriptors using ``librosa``.

    Parameters
    ----------
    audio_path:
        Path to the audio clip to analyse.
    target_sr:
        Sample rate used when loading audio. Defaults to 16 kHz for speech tasks.
    top_db:
        When provided, leading/trailing silence is trimmed before analysis using
        ``librosa.effects.trim``.
    """

    _ensure_librosa()
    y, sr = librosa.load(str(audio_path), sr=target_sr, mono=True)
    if y.size == 0:
        raise ValueError("Audio file is empty or could not be decoded")

    if top_db is not None:
        y, _ = librosa.effects.trim(y, top_db=top_db)
    duration = float(y.size) / float(sr)

    # Normalise amplitude for consistent heuristics.
    peak = float(np.max(np.abs(y)))
    if peak > 0:
        y = y / peak

    features: Dict[str, float] = {}
    rms = librosa.feature.rms(y=y)
    zcr = librosa.feature.zero_crossing_rate(y)
    centroid = librosa.feature.spectral_centroid(y=y, sr=sr)
    bandwidth = librosa.feature.spectral_bandwidth(y=y, sr=sr)
    rolloff = librosa.feature.spectral_rolloff(y=y, sr=sr, roll_percent=0.85)
    flatness = librosa.feature.spectral_flatness(y=y)
    mfcc = librosa.feature.mfcc(y=y, sr=sr, n_mfcc=13)

    _summarise_feature(rms, "rms", features)
    _summarise_feature(zcr, "zcr", features)
    _summarise_feature(centroid, "spectral_centroid", features)
    _summarise_feature(bandwidth, "spectral_bandwidth", features)
    _summarise_feature(rolloff, "spectral_rolloff", features)
    _summarise_feature(flatness, "spectral_flatness", features)

    for idx in range(mfcc.shape[0]):
        coeff = mfcc[idx]
        prefix = f"mfcc_{idx:02d}"
        features[f"{prefix}_mean"] = float(np.mean(coeff))
        features[f"{prefix}_std"] = float(np.std(coeff))

    anomaly_flags = EvpAnomalyFlags(
        is_silent=features["rms_mean"] < 1e-3,
        possible_clipping=peak >= 0.98,
        high_noise=features["spectral_flatness_mean"] > 0.4,
    )

    return EvpFeatureSet(
        sample_rate=sr,
        duration=duration,
        features=features,
        anomaly_flags=anomaly_flags,
    )
