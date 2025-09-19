"""Provenance tracking utilities for Project Aura."""
from __future__ import annotations

import hashlib
import json
import os
import sqlite3
from pathlib import Path
from typing import Dict, Optional, Tuple

from .config import AppConfig

CACHE_DIR = Path.home() / '.cache' / 'project_aura'
DEFAULT_DB_PATH = CACHE_DIR / 'provenance.sqlite3'


def resolve_db_path(override: Optional[Path] = None) -> Path:
    """Resolve the provenance database path."""

    if override is not None:
        return override
    env_path = os.environ.get('AURA_PROVENANCE_DB')
    if env_path:
        return Path(env_path).expanduser()
    return DEFAULT_DB_PATH


def _ensure_schema(conn: sqlite3.Connection) -> None:
    conn.execute(
        '''
        CREATE TABLE IF NOT EXISTS provenance (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            component TEXT NOT NULL,
            artifact_type TEXT NOT NULL,
            version_hash TEXT NOT NULL,
            metadata TEXT,
            recorded_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
        )
        '''
    )
    conn.execute(
        '''
        CREATE UNIQUE INDEX IF NOT EXISTS idx_provenance_component_type
        ON provenance(component, artifact_type)
        '''
    )


def _compute_directory_hash(root: Path) -> Tuple[str, int]:
    digest = hashlib.sha256()
    files = [path for path in sorted(root.rglob('*.py')) if path.is_file()]
    for path in files:
        digest.update(path.relative_to(root).as_posix().encode('utf-8'))
        digest.update(path.read_bytes())
    return digest.hexdigest(), len(files)


def _compute_text_hash(value: str) -> str:
    return hashlib.sha256(value.encode('utf-8')).hexdigest()


def record_provenance(
    component: str,
    artifact_type: str,
    version_hash: str,
    metadata: Optional[Dict[str, object]] = None,
    db_path: Optional[Path] = None,
) -> Path:
    """Persist a provenance entry, overwriting existing rows for the component."""

    resolved = resolve_db_path(db_path)
    resolved.parent.mkdir(parents=True, exist_ok=True)
    payload = json.dumps(metadata, sort_keys=True) if metadata else None

    with sqlite3.connect(resolved) as conn:
        _ensure_schema(conn)
        conn.execute(
            '''
            INSERT INTO provenance (component, artifact_type, version_hash, metadata)
            VALUES (?, ?, ?, ?)
            ON CONFLICT(component, artifact_type)
            DO UPDATE SET
                version_hash=excluded.version_hash,
                metadata=excluded.metadata,
                recorded_at=CURRENT_TIMESTAMP
            ''',
            (component, artifact_type, version_hash, payload),
        )
    return resolved


def snapshot_versions(config: AppConfig, db_path: Optional[Path] = None) -> Path:
    """Record hashes for the core code and active language model."""

    package_root = Path(__file__).resolve().parents[1]
    code_hash, file_count = _compute_directory_hash(package_root)
    path = record_provenance(
        component='aura-core',
        artifact_type='code',
        version_hash=code_hash,
        metadata={'files': file_count, 'root': str(package_root)},
        db_path=db_path,
    )

    model_hash = _compute_text_hash(config.llm.model)
    record_provenance(
        component='llm',
        artifact_type='model',
        version_hash=model_hash,
        metadata={'model': config.llm.model},
        db_path=path,
    )
    return path


__all__ = ['record_provenance', 'resolve_db_path', 'snapshot_versions']
