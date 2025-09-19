"""SQLite metadata store for SentinelStack."""

from __future__ import annotations

import argparse
import sqlite3
from dataclasses import dataclass
from pathlib import Path
from typing import List, Sequence

SCHEMA_STATEMENTS: Sequence[str] = (
    "PRAGMA journal_mode=WAL;",
    "PRAGMA synchronous=NORMAL;",
    """
    CREATE TABLE IF NOT EXISTS media (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        path TEXT NOT NULL UNIQUE,
        type TEXT NOT NULL,
        checksum TEXT,
        duration REAL,
        frame_rate REAL,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        metadata TEXT
    );
    """,
    """
    CREATE TABLE IF NOT EXISTS embeddings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        media_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        model TEXT,
        dim INTEGER NOT NULL,
        vector BLOB NOT NULL,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        metadata TEXT,
        FOREIGN KEY(media_id) REFERENCES media(id) ON DELETE CASCADE
    );
    """,
    """
    CREATE TABLE IF NOT EXISTS faces (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        media_id INTEGER NOT NULL,
        embedding_id INTEGER,
        time_offset REAL,
        bbox TEXT,
        landmarks TEXT,
        attributes TEXT,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(media_id) REFERENCES media(id) ON DELETE CASCADE,
        FOREIGN KEY(embedding_id) REFERENCES embeddings(id) ON DELETE SET NULL
    );
    """,
    """
    CREATE TABLE IF NOT EXISTS scenes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        media_id INTEGER NOT NULL,
        start_time REAL NOT NULL,
        end_time REAL,
        label TEXT,
        confidence REAL,
        metadata TEXT,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(media_id) REFERENCES media(id) ON DELETE CASCADE
    );
    """,
    """
    CREATE TABLE IF NOT EXISTS transcripts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        media_id INTEGER NOT NULL,
        start_time REAL,
        end_time REAL,
        speaker TEXT,
        text TEXT NOT NULL,
        metadata TEXT,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(media_id) REFERENCES media(id) ON DELETE CASCADE
    );
    """,
    """
    CREATE TABLE IF NOT EXISTS anomalies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        media_id INTEGER NOT NULL,
        kind TEXT NOT NULL,
        score REAL,
        severity REAL,
        details TEXT,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(media_id) REFERENCES media(id) ON DELETE CASCADE
    );
    """,
    "CREATE INDEX IF NOT EXISTS idx_embeddings_media_type ON embeddings(media_id, type);",
    "CREATE INDEX IF NOT EXISTS idx_faces_media_time ON faces(media_id, time_offset);",
    "CREATE INDEX IF NOT EXISTS idx_scenes_media_start ON scenes(media_id, start_time);",
    "CREATE INDEX IF NOT EXISTS idx_transcripts_media_start ON transcripts(media_id, start_time);",
    "CREATE INDEX IF NOT EXISTS idx_anomalies_media_kind ON anomalies(media_id, kind);",
)


@dataclass
class MetadataStore:
    """Utility wrapper around an SQLite database."""

    db_path: Path | str
    timeout: float = 30.0
    read_only: bool = False

    def __post_init__(self) -> None:
        self._path = Path(self.db_path) if self.db_path != ":memory:" else None
        if not self.read_only and self._path is not None:
            self._path.parent.mkdir(parents=True, exist_ok=True)

        if self.read_only:
            if self._path is None:
                uri = f"file:{self.db_path}?mode=ro"
            else:
                uri = f"file:{self._path.as_posix()}?mode=ro"
            self._connection = sqlite3.connect(uri, uri=True, timeout=self.timeout, detect_types=sqlite3.PARSE_DECLTYPES)
        else:
            target = ":memory:" if self._path is None else str(self._path)
            self._connection = sqlite3.connect(target, timeout=self.timeout, detect_types=sqlite3.PARSE_DECLTYPES)

        self._connection.execute("PRAGMA foreign_keys = ON;")
        self._connection.row_factory = sqlite3.Row

    # ------------------------------------------------------------------
    # Context manager helpers
    # ------------------------------------------------------------------
    def __enter__(self) -> "MetadataStore":
        return self

    def __exit__(self, exc_type, exc, tb) -> None:
        self.close()

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------
    @property
    def connection(self) -> sqlite3.Connection:
        return self._connection

    def migrate(self) -> None:
        """Initialise database schema if tables do not exist."""

        with self._connection:
            for statement in SCHEMA_STATEMENTS:
                self._connection.execute(statement)

    def table_names(self) -> List[str]:
        cursor = self._connection.execute("SELECT name FROM sqlite_master WHERE type='table';")
        return [row[0] for row in cursor.fetchall()]

    def close(self) -> None:
        self._connection.close()


# ----------------------------------------------------------------------
# Command line interface
# ----------------------------------------------------------------------

def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Manage the SentinelStack metadata store")
    parser.add_argument("command", choices=["init"], help="Initialise the metadata store if needed")
    parser.add_argument("db_path", type=Path, help="Path to the SQLite database file")
    parser.add_argument("--force", action="store_true", help="Run migrations even if the database exists")
    args = parser.parse_args(list(argv) if argv is not None else None)

    is_new = not args.db_path.exists()

    if args.command == "init":
        with MetadataStore(args.db_path) as store:
            if is_new or args.force:
                store.migrate()
                message = f"Initialised metadata store at {args.db_path}"
            else:
                store.migrate()
                message = f"Metadata store already present at {args.db_path}"
        print(message)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
