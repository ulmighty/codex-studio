"""Transcription helpers for interfacing with Whisper implementations."""
from __future__ import annotations

import json
import os
import subprocess
import tempfile
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Dict, List, Optional, Sequence, Union

PathLike = Union[str, os.PathLike[str]]

DISCLAIMER = "Transcription may be inaccurate."


@dataclass(slots=True)
class Segment:
    """A lightweight representation of a transcript segment."""

    start: float
    end: float
    text: str
    speaker: Optional[str] = None


@dataclass(slots=True)
class TranscriptionResult:
    """Standard transcription payload consumed by the API lane."""

    text: str
    segments: List[Segment]
    language: Optional[str]
    engine: str
    disclaimer: str = DISCLAIMER
    metadata: Dict[str, Any] = field(default_factory=dict)


def _import_whisper(module_override: Any = None) -> Any:
    """Import the python ``whisper`` package lazily.

    Parameters
    ----------
    module_override:
        Optional module instance supplied during testing to avoid runtime imports.

    Returns
    -------
    Module
        The whisper module.

    Raises
    ------
    RuntimeError
        If the whisper package is not available.
    """

    if module_override is not None:
        return module_override
    try:
        import whisper  # type: ignore[import]
    except ImportError as exc:  # pragma: no cover - dependency missing
        raise RuntimeError(
            "The 'whisper' package is required for python-based transcription. "
            "Install it via 'pip install openai-whisper'."
        ) from exc
    return whisper


def transcribe_with_python_whisper(
    audio_path: PathLike,
    *,
    model_name: str = "base",
    model_dir: Optional[PathLike] = None,
    language: Optional[str] = None,
    temperature: float = 0.0,
    whisper_module: Any | None = None,
    decode_options: Optional[Dict[str, Any]] = None,
) -> TranscriptionResult:
    """Run transcription using the python ``whisper`` package.

    The function intentionally keeps parameters explicit so the BACKEND_API lane
    can pass deterministic decoding arguments. Callers may specify a custom
    ``download_root`` directory through ``model_dir`` to keep all assets offline.

    Parameters
    ----------
    audio_path:
        Path to the audio clip to transcribe.
    model_name:
        Whisper model identifier (e.g. ``base.en``).
    model_dir:
        Optional directory containing pre-downloaded model weights.
    language:
        Force transcription language. ``None`` enables automatic detection.
    temperature:
        Decoding temperature forwarded to Whisper.
    whisper_module:
        Optional module override primarily intended for unit tests.
    decode_options:
        Additional keyword arguments forwarded to ``model.transcribe``.

    Returns
    -------
    TranscriptionResult
        Parsed transcription output compatible with API payloads.
    """

    whisper = _import_whisper(whisper_module)
    model = whisper.load_model(
        model_name,
        download_root=str(model_dir) if model_dir is not None else None,
    )
    options: Dict[str, Any] = {
        "temperature": temperature,
        "condition_on_previous_text": False,
    }
    if decode_options:
        options.update(decode_options)
    if language:
        options["language"] = language

    raw_result: Dict[str, Any] = model.transcribe(str(audio_path), **options)
    segments = [
        Segment(
            start=float(segment.get("start", 0.0)),
            end=float(segment.get("end", 0.0)),
            text=str(segment.get("text", "")).strip(),
            speaker=None,
        )
        for segment in raw_result.get("segments", [])
    ]
    text = raw_result.get("text", "").strip()
    metadata = {
        "temperature": options.get("temperature"),
        "model": model_name,
        "duration": raw_result.get("duration"),
        "language_probability": raw_result.get("language_probability"),
    }
    detected_language = raw_result.get("language") or language
    return TranscriptionResult(
        text=text,
        segments=segments,
        language=detected_language,
        engine="python-whisper",
        metadata=metadata,
    )


def _build_whisper_cpp_command(
    binary_path: Path,
    audio_path: Path,
    model_path: Path,
    *,
    language: Optional[str],
    temperature: float,
    threads: Optional[int],
    beam_size: Optional[int],
    extra_args: Optional[Sequence[str]] = None,
    output_dir: Optional[Path] = None,
) -> List[str]:
    cmd: List[str] = [str(binary_path), "--model", str(model_path), "--output-json"]
    if output_dir is not None:
        cmd.extend(["--output-dir", str(output_dir)])
    if language:
        cmd.extend(["--language", language])
    cmd.extend(["--temperature", f"{temperature:.2f}"])
    if threads:
        cmd.extend(["--threads", str(threads)])
    if beam_size:
        cmd.extend(["--beam-size", str(beam_size)])
    cmd.append(str(audio_path))
    if extra_args:
        cmd.extend(list(extra_args))
    return cmd


def transcribe_with_whisper_cpp(
    audio_path: PathLike,
    *,
    binary_path: PathLike,
    model_path: PathLike,
    language: Optional[str] = None,
    temperature: float = 0.0,
    threads: Optional[int] = None,
    beam_size: Optional[int] = None,
    extra_args: Optional[Sequence[str]] = None,
    working_dir: Optional[PathLike] = None,
    env: Optional[Dict[str, str]] = None,
) -> TranscriptionResult:
    """Execute a whisper.cpp binary and normalise its JSON output.

    The function expects a whisper.cpp build compiled with ``--output-json``
    support. It writes temporary results to ``working_dir`` when provided or a
    newly created temporary directory otherwise.
    """

    audio_path = Path(audio_path)
    binary_path = Path(binary_path)
    model_path = Path(model_path)
    if not audio_path.exists():
        raise FileNotFoundError(f"Audio file not found: {audio_path}")
    if not binary_path.exists():
        raise FileNotFoundError(f"whisper.cpp binary not found: {binary_path}")
    if not model_path.exists():
        raise FileNotFoundError(f"whisper.cpp model not found: {model_path}")

    temp_dir: tempfile.TemporaryDirectory[str] | None = None
    try:
        output_dir: Path
        if working_dir is None:
            temp_dir = tempfile.TemporaryDirectory(prefix="whispercpp_")
            output_dir = Path(temp_dir.name)
        else:
            output_dir = Path(working_dir)
            output_dir.mkdir(parents=True, exist_ok=True)

        cmd = _build_whisper_cpp_command(
            binary_path=binary_path,
            audio_path=audio_path,
            model_path=model_path,
            language=language,
            temperature=temperature,
            threads=threads,
            beam_size=beam_size,
            extra_args=extra_args,
            output_dir=output_dir,
        )

        completed = subprocess.run(
            cmd,
            check=False,
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        if completed.returncode != 0:
            raise RuntimeError(
                "whisper.cpp execution failed",
                {
                    "command": cmd,
                    "stdout": completed.stdout,
                    "stderr": completed.stderr,
                },
            )

        json_files = sorted(output_dir.glob("*.json"))
        if not json_files:
            raise RuntimeError(
                "whisper.cpp did not emit JSON output; enable '--output-json' in the binary."
            )
        with json_files[0].open("r", encoding="utf-8") as fh:
            payload = json.load(fh)

        segments = [
            Segment(
                start=float(segment.get("start", 0.0)),
                end=float(segment.get("end", 0.0)),
                text=str(segment.get("text", "")).strip(),
                speaker=None,
            )
            for segment in payload.get("segments", [])
        ]
        metadata = {
            "command": cmd,
            "stdout": completed.stdout,
            "stderr": completed.stderr,
        }
        text = payload.get("text", "").strip()
        detected_language = payload.get("language") or language

        return TranscriptionResult(
            text=text,
            segments=segments,
            language=detected_language,
            engine="whisper.cpp",
            metadata=metadata,
        )
    finally:
        if temp_dir is not None:
            temp_dir.cleanup()
