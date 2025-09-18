from __future__ import annotations

from pathlib import Path

from indexer.store import MetadataStore, main


def test_migrate_creates_tables(tmp_path: Path) -> None:
    db_path = tmp_path / "metadata.db"
    assert not db_path.exists()

    result = main(["init", str(db_path)])
    assert result == 0
    assert db_path.exists()

    with MetadataStore(db_path) as store:
        tables = set(store.table_names())

    expected_tables = {"media", "embeddings", "faces", "scenes", "transcripts", "anomalies"}
    assert expected_tables.issubset(tables)

    # Second migration should be idempotent
    result_again = main(["init", str(db_path)])
    assert result_again == 0
