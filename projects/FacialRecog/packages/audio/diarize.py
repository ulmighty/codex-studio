"""Speaker embedding helpers built on top of Resemblyzer."""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional

import numpy as np

from .transcribe import DISCLAIMER, PathLike

try:  # pragma: no cover - optional dependency resolution
    from Resemblyzer import VoiceEncoder, preprocess_wav  # type: ignore[import]
except ImportError:  # pragma: no cover - handled in _get_encoder
    VoiceEncoder = None  # type: ignore[assignment]
    preprocess_wav = None  # type: ignore[assignment]


@dataclass(slots=True)
class EmbeddingSegment:
    """Embedding for an audio slice."""

    start: float
    end: float
    embedding: List[float]


@dataclass(slots=True)
class SpeakerEmbeddingResult:
    """Container for diarisation-friendly embeddings."""

    segments: List[EmbeddingSegment]
    sample_rate: int
    disclaimer: str = field(default=DISCLAIMER, init=False)
    metadata: Dict[str, Any] = field(default_factory=dict)


def _get_encoder(encoder: Optional[Any] = None) -> Any:
    if encoder is not None:
        return encoder
    if VoiceEncoder is None:  # pragma: no cover - executed when dependency missing
        raise RuntimeError(
            "The 'Resemblyzer' package is required to compute speaker embeddings. "
            "Install it via 'pip install Resemblyzer'."
        )
    return VoiceEncoder()


def _preprocess(audio_path: PathLike) -> np.ndarray:
    if preprocess_wav is None:  # pragma: no cover - executed when dependency missing
        raise RuntimeError(
            "Resemblyzer preprocessing helpers are unavailable. Ensure the package is installed."
        )
    return preprocess_wav(str(audio_path))


def compute_speaker_embeddings(
    audio_path: PathLike,
    *,
    window_size: float = 1.5,
    hop_size: float = 0.75,
    encoder: Optional[Any] = None,
) -> SpeakerEmbeddingResult:
    """Generate sliding window speaker embeddings using Resemblyzer.

    Parameters
    ----------
    audio_path:
        Audio file analysed for speaker characteristics.
    window_size:
        Window size in seconds used for embeddings. Defaults to 1.5 seconds as
        recommended by the Resemblyzer documentation.
    hop_size:
        Hop size between consecutive windows in seconds.
    encoder:
        Optional pre-instantiated ``VoiceEncoder`` for dependency injection.
    """

    wav = _preprocess(audio_path)
    if wav.size == 0:
        raise ValueError("Audio file is empty or could not be decoded")
    sr = 16_000  # Resemblyzer always outputs 16 kHz audio
    encoder_instance = _get_encoder(encoder)

    window_samples = max(int(window_size * sr), sr // 2)
    hop_samples = max(int(hop_size * sr), sr // 4)

    segments: List[EmbeddingSegment] = []
    total_samples = wav.shape[0]
    if total_samples <= window_samples:
        embedding = encoder_instance.embed_utterance(wav)
        segments.append(
            EmbeddingSegment(
                start=0.0,
                end=float(total_samples) / float(sr),
                embedding=embedding.astype(float).tolist(),
            )
        )
    else:
        start = 0
        while start + window_samples <= total_samples:
            end = start + window_samples
            chunk = wav[start:end]
            embedding = encoder_instance.embed_utterance(chunk)
            segments.append(
                EmbeddingSegment(
                    start=start / sr,
                    end=end / sr,
                    embedding=embedding.astype(float).tolist(),
                )
            )
            start += hop_samples
        if segments:
            last_end = segments[-1].end
        else:
            last_end = 0.0
        if last_end * sr < total_samples:
            chunk = wav[-window_samples:]
            embedding = encoder_instance.embed_utterance(chunk)
            segments.append(
                EmbeddingSegment(
                    start=max(total_samples - window_samples, 0) / sr,
                    end=total_samples / sr,
                    embedding=embedding.astype(float).tolist(),
                )
            )

    metadata = {
        "window_size": window_size,
        "hop_size": hop_size,
        "num_segments": len(segments),
    }
    return SpeakerEmbeddingResult(
        segments=segments,
        sample_rate=sr,
        metadata=metadata,
    )
