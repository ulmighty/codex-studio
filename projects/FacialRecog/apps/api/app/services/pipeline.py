"""Pipeline orchestration utilities for the FastAPI service."""
from __future__ import annotations

import hashlib
import json
import math
import random
import threading
import uuid
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional, Sequence, Tuple

from pydantic import BaseModel, Field, validator

try:
    import yaml  # type: ignore
except Exception:  # pragma: no cover - optional dependency
    yaml = None  # type: ignore


class PipelineServiceError(RuntimeError):
    """Raised when an operation inside the pipeline fails."""


@dataclass(frozen=True)
class PipelineSettings:
    """Configuration values that drive pipeline behaviour."""

    ingest_fps: int = 1
    audio_format: str = "wav"
    video_extensions: Tuple[str, ...] = (".mp4", ".mov", ".mkv", ".avi")
    transcription_backend: str = "whisper"
    transcription_model: str = "base"
    sample_rate: int = 16_000
    embedding_dim: int = 128
    index_path: Path = Path("var/index/faces.json")
    detectors: Tuple[str, ...] = ("evp", "orb", "shadow")

    @classmethod
    def load(cls, config_path: Path) -> "PipelineSettings":
        """Load settings from ``projects/FacialRecog/configs/pipeline.yaml`` when available."""

        config_data = cls._read_config(config_path)
        if not config_data:
            return cls()

        ingest_cfg = config_data.get("ingest", {})
        frame_cfg = ingest_cfg.get("frame_extraction", {})
        audio_cfg = ingest_cfg.get("audio", {})

        vision_cfg = config_data.get("vision", {})
        face_cfg = vision_cfg.get("faces", {})

        transcription_cfg = config_data.get("audio", {}).get("transcription", {})
        anomaly_cfg = config_data.get("anomaly", {})

        fps = cls._coerce_int(frame_cfg.get("fps"), default=cls.ingest_fps)
        audio_format = str(audio_cfg.get("format", cls.audio_format)).strip() or cls.audio_format

        video_extensions = frame_cfg.get("extensions") or cls.video_extensions
        if isinstance(video_extensions, str):
            video_extensions = tuple(ext.strip() for ext in video_extensions.split(",") if ext.strip())
        elif isinstance(video_extensions, Iterable):
            video_extensions = tuple(str(ext).strip() for ext in video_extensions)
        else:
            video_extensions = cls.video_extensions

        index_path_value = face_cfg.get("index_store") or cls.index_path
        index_path = Path(str(index_path_value)) if index_path_value else cls.index_path

        transcription_backend = str(
            transcription_cfg.get("backend", cls.transcription_backend)
        ).strip() or cls.transcription_backend
        transcription_model = str(
            transcription_cfg.get("model", cls.transcription_model)
        ).strip() or cls.transcription_model
        sample_rate = cls._coerce_int(
            transcription_cfg.get("sample_rate"),
            default=cls.sample_rate,
        )
        embedding_dim = cls._coerce_int(face_cfg.get("embedding_dim"), default=cls.embedding_dim)

        detectors: Tuple[str, ...]
        configured_detectors = anomaly_cfg.get("detectors")
        if isinstance(configured_detectors, Iterable) and not isinstance(configured_detectors, (str, bytes)):
            detectors = tuple(str(item).strip() for item in configured_detectors if str(item).strip())
            detectors = detectors or cls.detectors
        else:
            detectors = cls.detectors

        return cls(
            ingest_fps=fps,
            audio_format=audio_format,
            video_extensions=video_extensions or cls.video_extensions,
            transcription_backend=transcription_backend,
            transcription_model=transcription_model,
            sample_rate=sample_rate,
            embedding_dim=embedding_dim,
            index_path=index_path,
            detectors=detectors,
        )

    @staticmethod
    def _coerce_int(value: Any, default: int) -> int:
        try:
            if value is None:
                raise ValueError("missing")
            return int(value)
        except Exception:
            return default

    @staticmethod
    def _read_config(config_path: Path) -> Dict[str, Any]:
        if not config_path.exists():
            return {}

        try:
            text = config_path.read_text(encoding="utf-8")
        except OSError as exc:  # pragma: no cover - rare filesystem issue
            raise PipelineServiceError(f"Unable to read config: {exc}") from exc

        if not text.strip():
            return {}

        if yaml is None:
            # Gracefully degrade when PyYAML is unavailable.
            return {}

        loaded = yaml.safe_load(text)  # type: ignore[union-attr]
        if not isinstance(loaded, dict):
            return {}
        return loaded


class SceneSegment(BaseModel):
    index: int = Field(..., ge=0)
    start: float = Field(..., ge=0)
    end: float = Field(..., ge=0)
    confidence: float = Field(..., ge=0, le=1)

    @validator("end")
    def _validate_range(cls, value: float, values: Dict[str, Any]) -> float:  # noqa: D401
        """Ensure the end timestamp is not before the start."""

        start = values.get("start", 0.0)
        if value < start:
            raise ValueError("end must be greater than or equal to start")
        return value


class VideoIngestResult(BaseModel):
    video_path: str
    fps: int = Field(..., gt=0)
    frames_extracted: int = Field(..., ge=0)
    audio_path: str
    scene_segments: List[SceneSegment] = Field(default_factory=list)


class IngestResult(BaseModel):
    folder: str
    total_videos: int = Field(..., ge=0)
    total_frames: int = Field(..., ge=0)
    videos: List[VideoIngestResult] = Field(default_factory=list)


class TranscriptionSegment(BaseModel):
    start: float = Field(..., ge=0)
    end: float = Field(..., ge=0)
    text: str
    confidence: float = Field(..., ge=0, le=1)

    @validator("end")
    def _validate_end(cls, value: float, values: Dict[str, Any]) -> float:
        start = values.get("start", 0.0)
        if value < start:
            raise ValueError("segment end must be after start")
        return value


class TranscriptionResult(BaseModel):
    audio_path: str
    backend: str
    model: str
    transcript_path: str
    segments: List[TranscriptionSegment] = Field(default_factory=list)


class BoundingBox(BaseModel):
    top: float = Field(..., ge=0, le=1)
    left: float = Field(..., ge=0, le=1)
    width: float = Field(..., gt=0, le=1)
    height: float = Field(..., gt=0, le=1)
    confidence: float = Field(..., ge=0, le=1)


class FaceEmbeddingRecord(BaseModel):
    identifier: str
    image_path: str
    embedding: List[float]
    metadata: Dict[str, Any] = Field(default_factory=dict)
    bounding_box: BoundingBox


class FaceVisionResult(BaseModel):
    record: FaceEmbeddingRecord


class FaceSearchMatch(BaseModel):
    identifier: str
    image_path: str
    distance: float = Field(..., ge=0)
    metadata: Dict[str, Any] = Field(default_factory=dict)
    embedding: List[float]


class FaceSearchResponse(BaseModel):
    query_source: str
    matches: List[FaceSearchMatch] = Field(default_factory=list)


class DetectorFlag(BaseModel):
    name: str
    triggered: bool
    score: float = Field(..., ge=0, le=1)


class AnomalyReport(BaseModel):
    media_path: str
    severity: float = Field(..., ge=0, le=1)
    detectors: List[DetectorFlag] = Field(default_factory=list)


class FaceIndexStore:
    """Simple embedding index persisted to disk."""

    def __init__(self, store_path: Path) -> None:
        self._path = store_path
        self._path.parent.mkdir(parents=True, exist_ok=True)
        self._lock = threading.Lock()
        self._records: List[FaceEmbeddingRecord] = []
        self._load()

    def _load(self) -> None:
        if not self._path.exists():
            self._records = []
            return
        try:
            raw = json.loads(self._path.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            self._records = []
            return
        except OSError as exc:  # pragma: no cover - filesystem edge case
            raise PipelineServiceError(f"Unable to read index store: {exc}") from exc

        if not isinstance(raw, list):
            self._records = []
            return
        self._records = [FaceEmbeddingRecord(**item) for item in raw]

    def _flush(self) -> None:
        serialisable = [record.dict() for record in self._records]
        try:
            self._path.write_text(json.dumps(serialisable, indent=2), encoding="utf-8")
        except OSError as exc:  # pragma: no cover
            raise PipelineServiceError(f"Unable to persist index store: {exc}") from exc

    def add(self, record: FaceEmbeddingRecord) -> None:
        with self._lock:
            self._load()
            self._records.append(record)
            self._flush()

    def all(self) -> List[FaceEmbeddingRecord]:
        with self._lock:
            self._load()
            return list(self._records)


class PipelineService:
    """Facade responsible for orchestrating pipeline operations."""

    def __init__(self, config_path: Optional[Path] = None) -> None:
        cfg_path = config_path or Path("projects/FacialRecog/configs/pipeline.yaml")
        self.settings = PipelineSettings.load(cfg_path)
        self._index = FaceIndexStore(self.settings.index_path)

    # ------------------------------------------------------------------
    # Ingestion
    # ------------------------------------------------------------------
    def ingest_folder(self, folder: Path, scene_detect: bool = False) -> IngestResult:
        folder = folder.expanduser().resolve()
        if not folder.exists() or not folder.is_dir():
            raise PipelineServiceError(f"Media folder not found: {folder}")

        videos: List[VideoIngestResult] = []
        total_frames = 0
        extensions = {ext.lower() for ext in self.settings.video_extensions}

        for video_path in sorted(folder.rglob("*")):
            if not video_path.is_file() or video_path.suffix.lower() not in extensions:
                continue
            frames = self._simulate_frame_extraction(video_path, self.settings.ingest_fps)
            audio_output = self._simulate_audio_extraction(video_path)
            scenes = self._simulate_scene_detection(video_path, frames) if scene_detect else []
            videos.append(
                VideoIngestResult(
                    video_path=str(video_path),
                    fps=self.settings.ingest_fps,
                    frames_extracted=frames,
                    audio_path=str(audio_output),
                    scene_segments=scenes,
                )
            )
            total_frames += frames

        return IngestResult(
            folder=str(folder),
            total_videos=len(videos),
            total_frames=total_frames,
            videos=videos,
        )

    def _simulate_frame_extraction(self, video_path: Path, fps: int) -> int:
        size = max(video_path.stat().st_size, 1)
        frames = max(fps, int(size / 1_000_000 * fps))
        return frames

    def _simulate_audio_extraction(self, video_path: Path) -> Path:
        audio_path = video_path.with_suffix(f".{self.settings.audio_format}")
        if not audio_path.exists():
            try:
                audio_path.write_bytes(b"")
            except OSError as exc:  # pragma: no cover - filesystem limitation
                raise PipelineServiceError(f"Unable to materialise audio file: {exc}") from exc
        return audio_path

    def _simulate_scene_detection(self, video_path: Path, frames: int) -> List[SceneSegment]:
        if frames <= 0:
            return []
        size = max(video_path.stat().st_size, 1)
        segments = max(1, min(5, int(size / 2_000_000) + 1))
        duration = frames / max(self.settings.ingest_fps, 1)
        step = duration / segments
        scene_segments: List[SceneSegment] = []
        for index in range(segments):
            start = round(step * index, 3)
            end = round(start + step, 3)
            confidence = max(0.3, min(0.95, 0.5 + (index / segments)))
            scene_segments.append(
                SceneSegment(index=index, start=start, end=end, confidence=round(confidence, 3))
            )
        return scene_segments

    # ------------------------------------------------------------------
    # Vision / Search
    # ------------------------------------------------------------------
    def process_face_image(self, image_path: Path, metadata: Optional[Dict[str, Any]] = None) -> FaceVisionResult:
        image_path = image_path.expanduser().resolve()
        if not image_path.exists() or not image_path.is_file():
            raise PipelineServiceError(f"Image not found: {image_path}")

        embedding = self._generate_embedding(image_path)
        bounding_box = self._simulate_detection(image_path)
        record = FaceEmbeddingRecord(
            identifier=str(uuid.uuid4()),
            image_path=str(image_path),
            embedding=embedding,
            metadata=metadata or {},
            bounding_box=bounding_box,
        )
        self._index.add(record)
        return FaceVisionResult(record=record)

    def _generate_embedding(self, media_path: Path) -> List[float]:
        data = media_path.read_bytes()
        if not data:
            data = media_path.name.encode("utf-8")
        seed = int(hashlib.sha256(data).hexdigest(), 16)
        rng = random.Random(seed)
        return [round(rng.uniform(-1.0, 1.0), 6) for _ in range(self.settings.embedding_dim)]

    def _simulate_detection(self, media_path: Path) -> BoundingBox:
        data = media_path.read_bytes() or media_path.name.encode("utf-8")
        seed = int(hashlib.md5(data).hexdigest(), 16)
        rng = random.Random(seed)
        width = rng.uniform(0.3, 0.8)
        height = rng.uniform(0.3, 0.8)
        left = rng.uniform(0.0, 1.0 - width)
        top = rng.uniform(0.0, 1.0 - height)
        confidence = rng.uniform(0.5, 0.99)
        return BoundingBox(
            top=round(top, 3),
            left=round(left, 3),
            width=round(width, 3),
            height=round(height, 3),
            confidence=round(confidence, 3),
        )

    def generate_embedding(self, image_path: Path) -> List[float]:
        """Expose deterministic embedding generation without indexing."""

        image_path = image_path.expanduser().resolve()
        if not image_path.exists() or not image_path.is_file():
            raise PipelineServiceError(f"Image not found: {image_path}")
        return self._generate_embedding(image_path)

    def search_faces(
        self,
        embedding: Sequence[float],
        k: int,
        threshold: Optional[float] = None,
    ) -> FaceSearchResponse:
        if k <= 0:
            raise PipelineServiceError("k must be greater than zero")

        records = self._index.all()
        if not records:
            return FaceSearchResponse(query_source="embedding", matches=[])

        query = list(float(value) for value in embedding)
        results: List[Tuple[FaceEmbeddingRecord, float]] = []
        for record in records:
            dist = self._euclidean_distance(query, record.embedding)
            if threshold is not None and dist > threshold:
                continue
            results.append((record, dist))

        results.sort(key=lambda item: item[1])
        matches = [
            FaceSearchMatch(
                identifier=record.identifier,
                image_path=record.image_path,
                distance=round(distance, 6),
                metadata=record.metadata,
                embedding=record.embedding,
            )
            for record, distance in results[:k]
        ]
        return FaceSearchResponse(query_source="embedding", matches=matches)

    def _euclidean_distance(self, query: Sequence[float], target: Sequence[float]) -> float:
        length = min(len(query), len(target))
        if length == 0:
            return float("inf")
        total = 0.0
        for index in range(length):
            diff = query[index] - target[index]
            total += diff * diff
        return math.sqrt(total)

    # ------------------------------------------------------------------
    # Audio
    # ------------------------------------------------------------------
    def transcribe_audio(
        self,
        audio_path: Path,
        backend: Optional[str] = None,
        language: Optional[str] = None,
    ) -> TranscriptionResult:
        audio_path = audio_path.expanduser().resolve()
        if not audio_path.exists() or not audio_path.is_file():
            raise PipelineServiceError(f"Audio file not found: {audio_path}")

        data = audio_path.read_bytes()
        if not data:
            data = audio_path.name.encode("utf-8")
        seed = int(hashlib.sha1(data).hexdigest(), 16)
        rng = random.Random(seed)

        total_duration = max(1.0, len(data) / max(self.settings.sample_rate, 1))
        segment_count = max(1, min(5, int(total_duration // 5) + 1))
        step = total_duration / segment_count

        vocabulary = [
            "analysis",
            "frame",
            "embedding",
            "anomaly",
            "signal",
            "scene",
            "sequence",
            "vector",
        ]

        segments: List[TranscriptionSegment] = []
        for index in range(segment_count):
            start = round(step * index, 3)
            end = round(start + step, 3)
            words = " ".join(rng.choice(vocabulary) for _ in range(3))
            confidence = round(rng.uniform(0.6, 0.95), 3)
            segments.append(
                TranscriptionSegment(start=start, end=end, text=words, confidence=confidence)
            )

        transcript_path = audio_path.with_suffix(".transcript.json")
        payload = {
            "audio_path": str(audio_path),
            "backend": backend or self.settings.transcription_backend,
            "language": language,
            "model": self.settings.transcription_model,
            "segments": [segment.dict() for segment in segments],
        }
        try:
            transcript_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")
        except OSError as exc:  # pragma: no cover
            raise PipelineServiceError(f"Unable to persist transcript: {exc}") from exc

        return TranscriptionResult(
            audio_path=str(audio_path),
            backend=backend or self.settings.transcription_backend,
            model=self.settings.transcription_model,
            transcript_path=str(transcript_path),
            segments=segments,
        )

    # ------------------------------------------------------------------
    # Anomaly detection
    # ------------------------------------------------------------------
    def detect_anomalies(self, media_path: Path) -> AnomalyReport:
        media_path = media_path.expanduser().resolve()
        if not media_path.exists() or not media_path.is_file():
            raise PipelineServiceError(f"Media file not found: {media_path}")

        size = max(media_path.stat().st_size, 1)
        flags: List[DetectorFlag] = []
        for detector in self.settings.detectors:
            score = self._compute_detector_score(detector, size)
            flags.append(DetectorFlag(name=detector, triggered=score >= 0.6, score=score))

        severity = sum(flag.score for flag in flags) / len(flags) if flags else 0.0
        severity = round(min(1.0, severity), 3)
        return AnomalyReport(media_path=str(media_path), severity=severity, detectors=flags)

    def _compute_detector_score(self, detector: str, size: int) -> float:
        normalised = (size % 10_000_000) / 10_000_000
        base = {
            "evp": 0.4,
            "orb": 0.5,
            "shadow": 0.3,
        }.get(detector.lower(), 0.45)
        variation = (hash(detector) % 100) / 200.0
        score = min(1.0, max(0.0, base + normalised + variation))
        return round(score, 3)
