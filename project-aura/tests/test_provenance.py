import json
import sqlite3
from pathlib import Path

from aura.core import config as config_module
from aura.core.provenance import snapshot_versions


def test_snapshot_versions_records_hashes(tmp_path: Path) -> None:
    config = config_module.load_config()
    db_path = tmp_path / 'provenance.sqlite3'
    path = snapshot_versions(config, db_path=db_path)

    assert path == db_path
    assert db_path.exists()

    with sqlite3.connect(db_path) as conn:
        rows = conn.execute(
            'SELECT component, artifact_type, version_hash, metadata FROM provenance'
        ).fetchall()

    assert {(row[0], row[1]) for row in rows} == {('aura-core', 'code'), ('llm', 'model')}

    for _, _, version_hash, metadata in rows:
        assert len(version_hash) == 64
        if metadata:
            data = json.loads(metadata)
            assert isinstance(data, dict)

    # Second call updates the same rows without duplicating entries
    snapshot_versions(config, db_path=db_path)
    with sqlite3.connect(db_path) as conn:
        count = conn.execute('SELECT COUNT(*) FROM provenance').fetchone()[0]
    assert count == 2
