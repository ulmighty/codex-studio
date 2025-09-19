"""Command-line orchestrator for the FaceTrace stack."""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import logging
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any, Dict, Iterable, List, Mapping, Optional, Sequence

from rich import pretty
from rich.console import Console
from rich.logging import RichHandler
from rich.progress import BarColumn, Progress, SpinnerColumn, TextColumn, TimeElapsedColumn
from rich.table import Table
from rich.text import Text

from . import FACETRACE_HOME

pretty.install()

_LOGGER = logging.getLogger("facetrace")


def _configure_logging(console: Console) -> None:
    """Configure logging to route through :mod:`rich`."""

    if any(isinstance(handler, RichHandler) for handler in _LOGGER.handlers):
        return

    handler = RichHandler(console=console, show_time=False, rich_tracebacks=True)
    handler.setFormatter(logging.Formatter("%(message)s"))
    _LOGGER.addHandler(handler)
    _LOGGER.setLevel(logging.INFO)


console = Console()
_configure_logging(console)

MEDIA_TYPE_BY_EXTENSION: Mapping[str, str] = {
    ".jpg": "image",
    ".jpeg": "image",
    ".png": "image",
    ".bmp": "image",
    ".gif": "image",
    ".tif": "image",
    ".tiff": "image",
    ".webp": "image",
    ".mp4": "video",
    ".mov": "video",
    ".mkv": "video",
    ".avi": "video",
    ".mp3": "audio",
    ".wav": "audio",
    ".flac": "audio",
    ".ogg": "audio",
    ".m4a": "audio",
    ".aac": "audio",
}

SUPPORTED_EXTENSIONS = frozenset(MEDIA_TYPE_BY_EXTENSION)

STATE_FILE = FACETRACE_HOME / "state.json"


@dataclass
class MediaEntry:
    """Metadata about a single ingested media asset."""

    media_id: str
    path: str
    root: str
    type: str
    size_bytes: int
    checksum: str
    ingested_at: str
    faces: Optional[Dict[str, Any]] = None
    transcript: Optional[Dict[str, Any]] = None

    def short_id(self) -> str:
        return self.media_id[:12]


@dataclass
class State:
    """Persisted FaceTrace CLI state."""

    media: Dict[str, MediaEntry] = field(default_factory=dict)
    ingests: List[Dict[str, Any]] = field(default_factory=list)

    @classmethod
    def load(cls) -> "State":
        if not STATE_FILE.exists():
            FACETRACE_HOME.mkdir(parents=True, exist_ok=True)
            return cls()
        try:
            payload = json.loads(STATE_FILE.read_text())
        except json.JSONDecodeError as exc:  # pragma: no cover - defensive
            _LOGGER.error("Failed to parse %s: %s", STATE_FILE, exc)
            return cls()
        media = {
            media_id: MediaEntry(**entry)
            for media_id, entry in payload.get("media", {}).items()
        }
        ingests = payload.get("ingests", [])
        return cls(media=media, ingests=ingests)

    def save(self) -> None:
        FACETRACE_HOME.mkdir(parents=True, exist_ok=True)
        payload = {
            "media": {media_id: asdict(entry) for media_id, entry in self.media.items()},
            "ingests": list(self.ingests),
        }
        tmp_path = STATE_FILE.with_suffix(".tmp")
        tmp_path.write_text(json.dumps(payload, indent=2, sort_keys=True))
        tmp_path.replace(STATE_FILE)

    def lookup(self, media_id: str) -> Optional[MediaEntry]:
        entry = self.media.get(media_id)
        if entry:
            return entry
        matches = [item for item in self.media.values() if item.media_id.startswith(media_id)]
        if len(matches) == 1:
            return matches[0]
        if len(matches) > 1:
            raise ValueError(
                f"Identifier '{media_id}' is ambiguous; please use a longer prefix."
            )
        return None


def _iter_media_files(folder: Path) -> Iterable[Path]:
    for path in sorted(folder.rglob("*")):
        if path.is_file() and path.suffix.lower() in SUPPORTED_EXTENSIONS:
            yield path


def _classify_media(path: Path) -> str:
    return MEDIA_TYPE_BY_EXTENSION.get(path.suffix.lower(), "binary")


def _checksum_for(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _ensure_media_entry(state: State, path: Path, root: Path) -> tuple[MediaEntry, bool]:
    checksum = _checksum_for(path)
    media_id = checksum[:24]
    existing = state.media.get(media_id)
    metadata = {
        "media_id": media_id,
        "path": str(path.resolve()),
        "root": str(root.resolve()),
        "type": _classify_media(path),
        "size_bytes": path.stat().st_size,
        "checksum": checksum,
        "ingested_at": dt.datetime.now(dt.timezone.utc).isoformat(),
    }
    if existing:
        # Refresh mutable fields to reflect potential moves.
        existing.path = metadata["path"]
        existing.root = metadata["root"]
        existing.size_bytes = metadata["size_bytes"]
        existing.checksum = metadata["checksum"]
        existing.ingested_at = metadata["ingested_at"]
        return existing, False
    entry = MediaEntry(**metadata)
    state.media[media_id] = entry
    return entry, True


def _format_size(num_bytes: int) -> str:
    step = 1024.0
    units = ["B", "KB", "MB", "GB", "TB"]
    size = float(num_bytes)
    for unit in units:
        if size < step:
            return f"{size:.1f} {unit}"
        size /= step
    return f"{size:.1f} PB"


def _pseudo_face_summary(entry: MediaEntry) -> Dict[str, Any]:
    faces = int(entry.checksum[:2], 16) % 5
    return {
        "count": faces,
        "analyzed_at": dt.datetime.now(dt.timezone.utc).isoformat(),
        "digest": hashlib.sha1(entry.checksum.encode("utf-8")).hexdigest(),
    }


def _pseudo_transcript(entry: MediaEntry) -> Dict[str, Any]:
    random_seed = int(entry.checksum[:16], 16)
    words = [
        "observation",
        "ambient",
        "vector",
        "analysis",
        "deterministic",
        "offline",
        "forensics",
        "stack",
        "timeline",
        "facet",
        "trace",
        "synthesis",
        "signal",
    ]
    result_words = []
    for idx in range(12):
        index = (random_seed >> (idx * 4)) & 0xF
        word = words[index % len(words)]
        result_words.append(word)
    sentence = " ".join(result_words).capitalize() + "."
    return {
        "transcript": sentence,
        "generated_at": dt.datetime.now(dt.timezone.utc).isoformat(),
        "digest": hashlib.sha1(entry.checksum.encode("utf-8")).hexdigest(),
    }


def _load_entries_for_target(state: State, target: str) -> List[MediaEntry]:
    path = Path(target)
    if path.exists():
        resolved = path.resolve()
        if path.is_dir():
            return [
                entry
                for entry in state.media.values()
                if Path(entry.root) == resolved
            ]
        for entry in state.media.values():
            if Path(entry.path) == resolved:
                return [entry]
        raise FileNotFoundError(f"{target} has not been ingested yet")
    entry = state.lookup(target)
    if entry:
        return [entry]
    raise KeyError(f"No media found for '{target}'")


def handle_ingest(args: argparse.Namespace) -> int:
    folder = Path(args.folder)
    if not folder.exists() or not folder.is_dir():
        console.print(f"[red]Folder not found:[/] {folder}")
        return 1

    state = State.load()
    files = list(_iter_media_files(folder))
    if not files:
        console.print(f"[yellow]No supported media files found in {folder}.[/]")
        return 0

    console.print(f"[bold]Ingesting {len(files)} file(s) from {folder}[/]")
    new_entries: List[MediaEntry] = []
    updated_entries: List[MediaEntry] = []
    with Progress(
        SpinnerColumn(),
        TextColumn("{task.description}"),
        BarColumn(),
        TextColumn("{task.completed}/{task.total}"),
        TimeElapsedColumn(),
        console=console,
    ) as progress:
        task_id = progress.add_task("Hashing", total=len(files))
        for file_path in files:
            entry, created = _ensure_media_entry(state, file_path, folder)
            if created:
                new_entries.append(entry)
            else:
                updated_entries.append(entry)
            progress.advance(task_id)

    ingest_record = {
        "root": str(folder.resolve()),
        "media_ids": [entry.media_id for entry in new_entries],
        "completed_at": dt.datetime.now(dt.timezone.utc).isoformat(),
    }
    state.ingests.append(ingest_record)
    state.save()

    table = Table(title="Ingest Summary")
    table.add_column("Media ID")
    table.add_column("Type")
    table.add_column("Size", justify="right")
    table.add_column("Path")
    table.add_column("Status")

    for entry in new_entries:
        table.add_row(
            entry.short_id(),
            entry.type,
            _format_size(entry.size_bytes),
            entry.path,
            "new",
        )
    if updated_entries:
        if new_entries:
            table.add_section()
        for entry in updated_entries:
            table.add_row(
                entry.short_id(),
                entry.type,
                _format_size(entry.size_bytes),
                entry.path,
                "updated",
            )

    console.print(table)
    if updated_entries:
        console.print(
            f"[green]Ingested {len(new_entries)} new file(s); updated {len(updated_entries)} existing file(s).[/]"
        )
    else:
        console.print(f"[green]Ingested {len(new_entries)} file(s).[/]")
    return 0


def handle_faces(args: argparse.Namespace) -> int:
    state = State.load()
    try:
        entries = _load_entries_for_target(state, args.target)
    except (KeyError, FileNotFoundError) as exc:
        console.print(f"[red]{exc}[/]")
        return 1
    if not entries:
        console.print(f"[yellow]No ingested media for {args.target}.[/]")
        return 0

    table = Table(title="Face Analysis")
    table.add_column("Media ID")
    table.add_column("Faces", justify="right")
    table.add_column("Analyzed")
    table.add_column("Path")

    for entry in entries:
        summary = _pseudo_face_summary(entry)
        entry.faces = summary
        table.add_row(
            entry.short_id(),
            str(summary["count"]),
            summary["analyzed_at"],
            entry.path,
        )

    state.save()
    console.print(table)
    return 0


def handle_transcribe(args: argparse.Namespace) -> int:
    state = State.load()
    try:
        entry = state.lookup(args.media_id)
    except ValueError as exc:
        console.print(f"[red]{exc}[/]")
        return 1
    if not entry:
        console.print(f"[red]Unknown media ID: {args.media_id}[/]")
        return 1
    if entry.type != "audio":
        console.print(
            f"[red]Transcription is only supported for audio assets (got {entry.type}).[/]"
        )
        return 1
    transcript = _pseudo_transcript(entry)
    entry.transcript = transcript
    state.save()

    console.print(Text(transcript["transcript"], style="green"))
    console.print(f"[blue]Generated at:[/] {transcript['generated_at']}")
    return 0


def handle_index_stats(_args: argparse.Namespace) -> int:
    state = State.load()
    if not state.media:
        console.print("[yellow]No media ingested yet.[/]")
        return 0

    counts: Dict[str, int] = {}
    sizes: Dict[str, int] = {}
    for entry in state.media.values():
        counts[entry.type] = counts.get(entry.type, 0) + 1
        sizes[entry.type] = sizes.get(entry.type, 0) + entry.size_bytes

    table = Table(title="Index Statistics")
    table.add_column("Type")
    table.add_column("Count", justify="right")
    table.add_column("Size", justify="right")

    total_count = 0
    total_size = 0
    for media_type in sorted(counts):
        count = counts[media_type]
        size = sizes[media_type]
        total_count += count
        total_size += size
        table.add_row(media_type, str(count), _format_size(size))
    table.add_section()
    table.add_row("Total", str(total_count), _format_size(total_size))

    console.print(table)
    return 0


def handle_serve(args: argparse.Namespace) -> int:
    try:
        import uvicorn
    except ImportError as exc:  # pragma: no cover - runtime guard
        console.print(f"[red]Uvicorn is not installed: {exc}[/]")
        return 1

    app_path = args.app or "facetrace_cli.server:app"
    console.print(
        f"[green]Starting uvicorn[/] [bold]{app_path}[/] on {args.host}:{args.port}"
    )
    uvicorn.run(app_path, host=args.host, port=args.port, reload=args.reload, log_level="info")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="facetrace", description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    ingest_parser = subparsers.add_parser("ingest", help="Ingest media from a folder")
    ingest_parser.add_argument("folder", help="Folder containing media assets")
    ingest_parser.set_defaults(func=handle_ingest)

    faces_parser = subparsers.add_parser("faces", help="Run face analysis")
    faces_parser.add_argument("target", help="Folder path or media identifier")
    faces_parser.set_defaults(func=handle_faces)

    transcribe_parser = subparsers.add_parser(
        "transcribe", help="Generate a deterministic pseudo-transcript for audio"
    )
    transcribe_parser.add_argument("media_id", help="Identifier of the audio asset")
    transcribe_parser.set_defaults(func=handle_transcribe)

    index_parser = subparsers.add_parser("index", help="Inspect index data")
    index_sub = index_parser.add_subparsers(dest="index_command", required=True)
    stats_parser = index_sub.add_parser("stats", help="Show aggregate index statistics")
    stats_parser.set_defaults(func=handle_index_stats)

    serve_parser = subparsers.add_parser("serve", help="Launch the FaceTrace API server")
    serve_parser.add_argument("--host", default="127.0.0.1")
    serve_parser.add_argument("--port", default=8000, type=int)
    serve_parser.add_argument("--reload", action="store_true")
    serve_parser.add_argument(
        "--app",
        default="facetrace_cli.server:app",
        help="ASGI application path passed to uvicorn",
    )
    serve_parser.set_defaults(func=handle_serve)

    return parser


def main(argv: Optional[Sequence[str]] = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":  # pragma: no cover - CLI entrypoint
    raise SystemExit(main())
