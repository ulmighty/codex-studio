"""Small FAISS style nearest neighbour helpers used in tests."""
from __future__ import annotations

import numpy as np
from numpy.typing import NDArray


def search_index(
    index: NDArray[np.float32],
    queries: NDArray[np.float32],
    *,
    k: int = 5,
) -> tuple[NDArray[np.float32], NDArray[np.int64]]:
    """Return ``(distances, indices)`` for the ``k`` nearest vectors.

    The function mirrors ``faiss.IndexFlatL2.search`` which is sufficient for
    exercising downstream logic without depending on the actual FAISS bindings.
    Both ``index`` and ``queries`` are expected to be two dimensional with the
    same embedding width.
    """

    if index.ndim != 2 or queries.ndim != 2:  # pragma: no cover - sanity guard
        raise ValueError("index and queries must be 2-D arrays")
    if index.shape[1] != queries.shape[1]:  # pragma: no cover - sanity guard
        raise ValueError("index and queries must share dimensionality")
    if k <= 0:  # pragma: no cover - sanity guard
        raise ValueError("k must be positive")

    if index.shape[0] == 0:  # pragma: no cover - sanity guard
        raise ValueError("index cannot be empty")

    k = min(k, index.shape[0])
    # Compute pairwise L2 distances.  ``queries`` is shaped ``(Q, D)`` and the
    # resulting matrix has shape ``(Q, N)`` where ``N`` is the number of vectors
    # in the index.
    diff = queries[:, None, :] - index[None, :, :]
    distances = np.linalg.norm(diff, axis=2)
    nearest = np.argsort(distances, axis=1)[:, :k]
    nearest_distances = np.take_along_axis(distances, nearest, axis=1)
    return nearest_distances.astype(np.float32), nearest.astype(np.int64)

