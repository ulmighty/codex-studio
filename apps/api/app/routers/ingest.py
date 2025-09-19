"""Ingestion and audio endpoints for the FaceTrace API."""
from __future__ import annotations

from pathlib import Path
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Request, status
from pydantic import BaseModel, Field

from ..services.pipeline import (
    AnomalyReport,
    IngestResult,
    PipelineService,
    PipelineServiceError,
    TranscriptionResult,
)

router = APIRouter(tags=["ingest"])


class IngestRequest(BaseModel):
    """Request payload describing an ingestion job."""

    folder: str = Field(..., description="Path to a directory containing media assets")
    scene_detect: bool = Field(False, description="Toggle deterministic scene segmentation")


class TranscriptionRequest(BaseModel):
    """Request payload for audio transcription."""

    audio_path: str = Field(..., description="Path to an audio file that should be transcribed")
    backend: Optional[str] = Field(None, description="Override backend defined in the pipeline config")
    language: Optional[str] = Field(None, description="Optional language hint for the transcription engine")


class AnomalyRequest(BaseModel):
    """Request payload for anomaly checks."""

    media_path: str = Field(..., description="Path to a media file to analyse for anomalies")


def get_pipeline(request: Request) -> PipelineService:
    """Resolve the pipeline service stored on the FastAPI application state."""

    service = getattr(request.app.state, "pipeline_service", None)
    if service is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Pipeline service not configured on application state",
        )
    return service


@router.post("/ingest", response_model=IngestResult, status_code=status.HTTP_200_OK)
async def ingest_media(
    payload: IngestRequest,
    service: PipelineService = Depends(get_pipeline),
) -> IngestResult:
    """Walk the provided folder and extract frame/audio metadata."""

    try:
        return service.ingest_folder(Path(payload.folder), scene_detect=payload.scene_detect)
    except PipelineServiceError as exc:  # pragma: no cover - exercised in integration tests
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc


@router.post(
    "/audio/transcribe",
    response_model=TranscriptionResult,
    status_code=status.HTTP_200_OK,
)
async def transcribe_audio(
    payload: TranscriptionRequest,
    service: PipelineService = Depends(get_pipeline),
) -> TranscriptionResult:
    """Transcribe an audio file using the configured backend."""

    try:
        return service.transcribe_audio(
            Path(payload.audio_path),
            backend=payload.backend,
            language=payload.language,
        )
    except PipelineServiceError as exc:  # pragma: no cover - exercised in integration tests
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc


@router.post("/anomaly", response_model=AnomalyReport, status_code=status.HTTP_200_OK)
async def anomaly_check(
    payload: AnomalyRequest,
    service: PipelineService = Depends(get_pipeline),
) -> AnomalyReport:
    """Run the lightweight anomaly heuristics on a media file."""

    try:
        return service.detect_anomalies(Path(payload.media_path))
    except PipelineServiceError as exc:  # pragma: no cover - exercised in integration tests
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc
