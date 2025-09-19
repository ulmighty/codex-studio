"""Audio feature extraction utilities for the voice enhancement pipeline."""
from __future__ import annotations

import numpy as np
from numpy.typing import NDArray


def extract_spectral_features(
    audio: NDArray[np.float32],
    *,
    sample_rate: int,
    frame_size: int = 400,
    hop_size: int = 160,
) -> NDArray[np.float32]:
    """Return a stack of spectral magnitudes for ``audio``.

    The routine implements a lightweight short-time Fourier transform.  The
    parameters default to 25 ms frames with a 10 ms hop which mirrors common
    speech-processing front-ends.  Values are normalised to the range ``[0, 1]``
    so that callers can feed them into downstream ML components without any
    additional scaling.
    """

    if audio.ndim != 1:  # pragma: no cover - defensive guard
        raise ValueError("audio must be a 1-D array")
    if sample_rate <= 0:  # pragma: no cover - defensive guard
        raise ValueError("sample_rate must be positive")

    signal = np.asarray(audio, dtype=np.float32)
    if signal.size < frame_size:
        pad = frame_size - signal.size
        signal = np.pad(signal, (0, pad), mode="constant")

    window = np.hanning(frame_size).astype(np.float32)
    frames: list[NDArray[np.float32]] = []
    for start in range(0, signal.size - frame_size + 1, hop_size):
        frame = signal[start : start + frame_size] * window
        spectrum = np.abs(np.fft.rfft(frame))
        frames.append(spectrum.astype(np.float32))

    if not frames:  # pragma: no cover - should not happen thanks to padding
        frames.append(np.abs(np.fft.rfft(signal[:frame_size])).astype(np.float32))

    features = np.vstack(frames)
    max_val = features.max(initial=0.0)
    if max_val > 0:
        features /= max_val
    return features
