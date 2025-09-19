from __future__ import annotations

import json
from pathlib import Path

import numpy as np
import pytest

from indexer.faiss_index import FaissIndex, FaissIndexError


@pytest.mark.parametrize("metric", ["l2", "cosine"])
def test_add_search_and_persistence(metric: str, tmp_path: Path) -> None:
    index = FaissIndex(dimension=4, metric=metric, use_faiss=False)

    vectors = np.array(
        [
            [0.0, 0.0, 0.0, 0.0],
            [1.0, 1.0, 1.0, 1.0],
            [2.0, 2.0, 2.0, 2.0],
        ],
        dtype=np.float32,
    )

    assigned = index.add(vectors)
    assert assigned == [0, 1, 2]
    assert len(index) == 3

    distances, ids = index.search(np.array([vectors[0]]), k=2)
    assert distances.shape == (1, 2)
    assert ids.shape == (1, 2)
    assert ids[0, 0] == 0

    output_path = tmp_path / "embeddings.index"
    index.save(output_path)

    metadata_path = output_path.with_suffix(output_path.suffix + ".meta.json")
    ids_path = output_path.with_suffix(output_path.suffix + ".ids.json")
    assert metadata_path.exists()
    assert ids_path.exists()

    with metadata_path.open("r", encoding="utf-8") as handle:
        metadata = json.load(handle)
    data_file = metadata_path.parent / metadata["index_file"]
    assert data_file.exists()

    reloaded = FaissIndex.load(output_path, prefer_faiss=False)
    assert len(reloaded) == 3

    distances_reload, ids_reload = reloaded.search(np.array([[1.0, 1.0, 1.0, 1.0]], dtype=np.float32), k=3)
    assert ids_reload[0, 0] in assigned
    assert np.all(np.isfinite(distances_reload))


def test_duplicate_ids_raise(tmp_path: Path) -> None:
    index = FaissIndex(dimension=2, use_faiss=False)
    index.add([[0.0, 0.0]], ids=[5])

    with pytest.raises(ValueError):
        index.add([[1.0, 1.0]], ids=[5])


def test_loading_missing_files(tmp_path: Path) -> None:
    path = tmp_path / "missing.index"
    with pytest.raises(FaissIndexError):
        FaissIndex.load(path, prefer_faiss=False)
