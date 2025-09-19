"""FAISS index management with optional numpy fallback."""

from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import List, Sequence, Tuple, Union

import numpy as np
from numpy.typing import ArrayLike, NDArray

try:  # pragma: no cover - import guarded for environments without faiss
    import faiss  # type: ignore
except ImportError:  # pragma: no cover - handled gracefully at runtime
    faiss = None  # type: ignore

DistanceMetric = Union[str, "Metric"]


class FaissIndexError(RuntimeError):
    """Raised when FAISS specific operations cannot be completed."""


@dataclass(frozen=True)
class Metric:
    """Enumeration of supported distance metrics."""

    name: str

    @classmethod
    def l2(cls) -> "Metric":
        return cls("l2")

    @classmethod
    def inner_product(cls) -> "Metric":
        return cls("ip")

    @classmethod
    def cosine(cls) -> "Metric":
        return cls("cosine")

    def __str__(self) -> str:  # pragma: no cover - trivial
        return self.name


_SUPPORTED_METRICS = {"l2", "ip", "cosine"}


def _normalise_metric(metric: DistanceMetric) -> str:
    name = str(metric).lower()
    if name not in _SUPPORTED_METRICS:
        raise ValueError(f"Unsupported metric '{metric}'. Supported metrics: {sorted(_SUPPORTED_METRICS)}")
    return name


class FaissIndex:
    """Wrapper around a FAISS index with persistence helpers.

    The class provides a numpy fallback to keep tests deterministic when the
    optional ``faiss`` dependency is not installed. Only a subset of FAISS
    functionality is exposed: adding embeddings, k-NN search, and saving/loading
    indices from disk.
    """

    def __init__(
        self,
        dimension: int,
        metric: DistanceMetric = "l2",
        use_faiss: bool | None = None,
    ) -> None:
        if dimension <= 0:
            raise ValueError("dimension must be a positive integer")

        metric_name = _normalise_metric(metric)

        if use_faiss is None:
            use_faiss = faiss is not None

        if use_faiss and faiss is None:
            raise FaissIndexError("The 'faiss' package is not installed. Install faiss or set use_faiss=False.")

        self.dimension = dimension
        self.metric = metric_name
        self._use_faiss = bool(use_faiss)
        self._index = self._create_faiss_index() if self._use_faiss else None
        self._vectors: NDArray[np.float32] = np.empty((0, dimension), dtype=np.float32)
        self._ids: List[int] = []
        self._next_id: int = 0

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------
    @property
    def use_faiss(self) -> bool:
        """Return whether the instance uses a real FAISS backend."""

        return self._use_faiss

    def __len__(self) -> int:
        return len(self._ids)

    def add(self, embeddings: ArrayLike, ids: Sequence[int] | None = None) -> List[int]:
        """Add embeddings to the index and return the assigned identifiers."""

        vectors = self._ensure_matrix(embeddings)
        if vectors.size == 0:
            return []

        if self.metric == "cosine":
            vectors = self._normalise(vectors)

        assigned_ids = self._prepare_ids(vectors.shape[0], ids)

        if self._use_faiss:
            assert self._index is not None  # for type checkers
            self._index.add_with_ids(vectors, np.asarray(assigned_ids, dtype=np.int64))
        else:
            self._vectors = self._stack_vectors(self._vectors, vectors)

        self._ids.extend(assigned_ids)
        self._next_id = max(self._next_id, max(assigned_ids) + 1)
        return assigned_ids

    def search(self, queries: ArrayLike, k: int) -> Tuple[NDArray[np.float32], NDArray[np.int64]]:
        """Run a k-NN search against the index."""

        if k <= 0:
            raise ValueError("k must be a positive integer")

        query_matrix = self._ensure_matrix(queries)
        fill_value = np.inf if self.metric == "l2" else -np.inf

        if query_matrix.size == 0:
            distances = np.empty((0, k), dtype=np.float32)
            ids = np.empty((0, k), dtype=np.int64)
            return distances, ids

        if self.metric == "cosine":
            query_matrix = self._normalise(query_matrix)

        if self._use_faiss:
            assert self._index is not None
            distances, ids = self._index.search(query_matrix, k)
            return distances.astype(np.float32), ids.astype(np.int64)

        if len(self._ids) == 0:
            distances = np.full((query_matrix.shape[0], k), fill_value, dtype=np.float32)
            ids = np.full((query_matrix.shape[0], k), -1, dtype=np.int64)
            return distances, ids

        return self._search_numpy(query_matrix, k)

    def reset(self) -> None:
        """Remove all embeddings from the index."""

        if self._use_faiss:
            assert self._index is not None
            self._index.reset()
        self._vectors = np.empty((0, self.dimension), dtype=np.float32)
        self._ids.clear()
        self._next_id = 0

    def save(self, path: Union[str, Path]) -> None:
        """Persist the index to disk.

        Parameters
        ----------
        path:
            File path used as the base name for the persisted artifacts. Two
            sidecar files are created alongside the index file: ``*.meta.json``
            storing metadata and ``*.ids.json`` storing the identifier mapping.
        """

        base_path = Path(path)
        base_path.parent.mkdir(parents=True, exist_ok=True)

        metadata = {
            "backend": "faiss" if self._use_faiss else "numpy",
            "dimension": self.dimension,
            "metric": self.metric,
            "count": len(self._ids),
            "next_id": self._next_id,
        }

        ids_path = self._ids_path(base_path)

        if self._use_faiss:
            if faiss is None:
                raise FaissIndexError("Cannot save FAISS index: faiss module unavailable at runtime.")
            assert self._index is not None
            faiss.write_index(self._index, str(base_path))
            metadata["index_file"] = base_path.name
        else:
            data_path = self._data_path(base_path)
            np.savez_compressed(data_path, vectors=self._vectors.astype(np.float32))
            metadata["index_file"] = data_path.name

        metadata["ids_file"] = ids_path.name
        self._write_json(ids_path, self._ids)
        self._write_json(self._metadata_path(base_path), metadata)

    @classmethod
    def load(cls, path: Union[str, Path], prefer_faiss: bool | None = None) -> "FaissIndex":
        """Load an index from disk."""

        base_path = Path(path)
        metadata_path = cls._metadata_path(base_path)
        if not metadata_path.exists():
            raise FaissIndexError(f"Metadata file '{metadata_path}' does not exist.")

        metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
        metric = metadata.get("metric", "l2")
        dimension = int(metadata["dimension"])
        backend = metadata.get("backend", "faiss")
        ids_file = metadata_path.parent / metadata.get("ids_file", cls._ids_path(base_path).name)
        ids = cls._read_ids(ids_file)

        use_faiss = backend == "faiss"
        if prefer_faiss is not None:
            use_faiss = prefer_faiss and backend == "faiss"

        if use_faiss and faiss is None:
            raise FaissIndexError("The saved index requires the 'faiss' package, but it is not installed.")

        index = cls(dimension=dimension, metric=metric, use_faiss=use_faiss)
        index._ids = ids
        index._next_id = int(metadata.get("next_id", len(ids)))

        data_file = metadata_path.parent / metadata.get("index_file", base_path.name)

        if use_faiss:
            if not data_file.exists():
                raise FaissIndexError(f"FAISS index file '{data_file}' is missing.")
            assert faiss is not None
            index._index = faiss.read_index(str(data_file))
        else:
            if not data_file.exists():
                raise FaissIndexError(f"Vector store file '{data_file}' is missing.")
            with np.load(data_file) as data:
                vectors = data["vectors"].astype(np.float32)
            if vectors.ndim == 1:
                vectors = np.expand_dims(vectors, axis=0)
            index._vectors = vectors

        return index

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------
    def _create_faiss_index(self):
        if faiss is None:
            raise FaissIndexError("FAISS backend requested but the 'faiss' package is not available.")

        if self.metric == "l2":
            base = faiss.IndexFlatL2(self.dimension)
        else:
            base = faiss.IndexFlatIP(self.dimension)
        return faiss.IndexIDMap(base)

    def _ensure_matrix(self, data: ArrayLike) -> NDArray[np.float32]:
        array = np.asarray(data, dtype=np.float32)
        if array.ndim == 1:
            array = np.expand_dims(array, axis=0)
        if array.ndim != 2:
            raise ValueError("Embeddings must be a 1D or 2D array")
        if array.shape[1] != self.dimension:
            raise ValueError(f"Expected embeddings with dimension {self.dimension}, received {array.shape[1]}")
        return array

    def _prepare_ids(self, count: int, ids: Sequence[int] | None) -> List[int]:
        if ids is None:
            assigned = list(range(self._next_id, self._next_id + count))
        else:
            if len(ids) != count:
                raise ValueError("The number of ids must match the number of embeddings")
            assigned = [int(i) for i in ids]

        existing_ids = set(self._ids)
        if existing_ids.intersection(assigned):
            raise ValueError("Duplicate identifiers detected")
        return assigned

    def _normalise(self, matrix: NDArray[np.float32]) -> NDArray[np.float32]:
        norms = np.linalg.norm(matrix, axis=1, keepdims=True)
        norms[norms == 0] = 1.0
        return matrix / norms

    def _stack_vectors(
        self,
        existing: NDArray[np.float32],
        new_vectors: NDArray[np.float32],
    ) -> NDArray[np.float32]:
        if existing.size == 0:
            return new_vectors.copy()
        return np.vstack([existing, new_vectors])

    def _search_numpy(self, query_matrix: NDArray[np.float32], k: int) -> Tuple[NDArray[np.float32], NDArray[np.int64]]:
        vectors = self._vectors
        ids_array = np.asarray(self._ids, dtype=np.int64)
        top_k = min(k, len(self._ids))

        fill_value = np.inf if self.metric == "l2" else -np.inf
        distances = np.full((query_matrix.shape[0], k), fill_value, dtype=np.float32)
        id_results = np.full((query_matrix.shape[0], k), -1, dtype=np.int64)

        if top_k == 0:
            return distances, id_results

        if self.metric == "l2":
            diff = query_matrix[:, None, :] - vectors[None, :, :]
            matrix = np.sum(diff ** 2, axis=2)
            order = np.argsort(matrix, axis=1)
            sorted_distances = np.take_along_axis(matrix, order, axis=1)
        else:
            matrix = query_matrix @ vectors.T
            order = np.argsort(-matrix, axis=1)
            sorted_distances = np.take_along_axis(matrix, order, axis=1)

        order = order[:, :top_k]
        sorted_distances = sorted_distances[:, :top_k]

        selected_ids = np.take(ids_array, order)
        distances[:, :top_k] = sorted_distances
        id_results[:, :top_k] = selected_ids
        return distances, id_results

    @staticmethod
    def _metadata_path(base_path: Path) -> Path:
        if base_path.suffix:
            return base_path.with_suffix(base_path.suffix + ".meta.json")
        return base_path.with_name(base_path.name + ".meta.json")

    @staticmethod
    def _ids_path(base_path: Path) -> Path:
        if base_path.suffix:
            return base_path.with_suffix(base_path.suffix + ".ids.json")
        return base_path.with_name(base_path.name + ".ids.json")

    @staticmethod
    def _data_path(base_path: Path) -> Path:
        if base_path.suffix:
            return base_path.with_suffix(base_path.suffix + ".npz")
        return base_path.with_suffix(".npz")

    @staticmethod
    def _write_json(path: Path, data: object) -> None:
        content = json.dumps(data, indent=2, sort_keys=True)
        path.write_text(content, encoding="utf-8")

    @staticmethod
    def _read_ids(path: Path) -> List[int]:
        if not path.exists():
            return []
        ids = json.loads(path.read_text(encoding="utf-8"))
        return [int(i) for i in ids]
