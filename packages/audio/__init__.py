"""Audio processing utilities for the AUDIO_PKG lane."""
from .transcribe import (
    Segment,
    TranscriptionResult,
    transcribe_with_python_whisper,
    transcribe_with_whisper_cpp,
)
from .evp import (
    EvpAnomalyFlags,
    EvpFeatureSet,
    extract_evp_features,
)
from .diarize import (
    EmbeddingSegment,
    SpeakerEmbeddingResult,
    compute_speaker_embeddings,
)

__all__ = [
    "Segment",
    "TranscriptionResult",
    "transcribe_with_python_whisper",
    "transcribe_with_whisper_cpp",
    "EvpAnomalyFlags",
    "EvpFeatureSet",
    "extract_evp_features",
    "EmbeddingSegment",
    "SpeakerEmbeddingResult",
    "compute_speaker_embeddings",
]
