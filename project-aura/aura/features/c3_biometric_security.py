"""Lightweight helpers for biometric face embeddings.

The real implementation would call into a vision model that emits high
dimensional embeddings for each detected face.  For the purposes of this
template we provide a deterministic NumPy based routine that mimics the
behaviour.  The function operates purely on the pixel intensities which keeps
the dependency surface tiny while still giving downstream components a stable
vector shape to operate on.
"""
from __future__ import annotations

from typing import Iterable

import numpy as np
from numpy.typing import NDArray


def compute_face_embedding(
    image: NDArray[np.float32] | NDArray[np.uint8],
    *,
    embedding_size: int = 128,
) -> NDArray[np.float32]:
    """Return a normalised embedding vector for ``image``.

    The function converts the input image into a deterministic histogram style
    embedding.  It works with either grayscale or RGB inputs and mirrors the
    behaviour of a FAISS compatible face encoder by always returning a vector
    of ``embedding_size`` floats with unit length.
    """

    if image.ndim not in (2, 3):  # pragma: no cover - defensive guard
        raise ValueError("image must be 2D (grayscale) or 3D (RGB)")

    flat: NDArray[np.float32]
    if image.dtype == np.uint8:
        flat = image.astype(np.float32, copy=False).reshape(-1)
    else:
        flat = np.asarray(image, dtype=np.float32).reshape(-1)

    if flat.size == 0:  # pragma: no cover - sanity guard
        raise ValueError("image must contain pixels")

    # Build a histogram over the pixel intensity range.  Using ``embedding_size``
    # bins guarantees the output shape matches FAISS expectations without
    # needing heavy dependencies.
    hist, _ = np.histogram(flat, bins=embedding_size, range=(0.0, 255.0))
    embedding = hist.astype(np.float32)

    norm = np.linalg.norm(embedding)
    if norm == 0:
        # Uniform images collapse to zero variance; fall back to an even
        # distribution so that the vector shape remains useful for tests.
        embedding.fill(1.0 / embedding_size)
    else:
        embedding /= norm

    return embedding


def batch_embeddings(
    images: Iterable[NDArray[np.float32] | NDArray[np.uint8]],
    *,
    embedding_size: int = 128,
) -> NDArray[np.float32]:
    """Compute embeddings for a sequence of ``images``.

    This helper mirrors a common production pattern where batches of face crops
    are encoded before being sent to an indexer.  It is intentionally tiny but
    gives unit tests something deterministic to assert against.
    """

    vectors = [compute_face_embedding(img, embedding_size=embedding_size) for img in images]
    if not vectors:  # pragma: no cover - defensive guard
        raise ValueError("at least one image required")
    return np.vstack(vectors)
