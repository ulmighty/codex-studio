"""Vision and face search endpoints."""
from __future__ import annotations

from pathlib import Path
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, Depends, HTTPException, Request, status
from pydantic import BaseModel, Field, root_validator

from ..services.pipeline import (
    FaceSearchResponse,
    FaceVisionResult,
    PipelineService,
    PipelineServiceError,
)

router = APIRouter(tags=["vision"])


class FaceVisionRequest(BaseModel):
    """Request body for face detection and embedding generation."""

    image_path: str = Field(..., description="Path to the image to analyse")
    metadata: Optional[Dict[str, Any]] = Field(
        default=None,
        description="Optional metadata to persist alongside the embedding",
    )


class FaceSearchRequest(BaseModel):
    """Request body for face search queries."""

    embedding: Optional[List[float]] = Field(
        default=None,
        description="Embedding vector to query against the index",
    )
    image_path: Optional[str] = Field(
        default=None,
        description="Optional path to an image to embed and search",
    )
    k: int = Field(5, gt=0, le=50, description="Number of nearest neighbours to return")
    threshold: Optional[float] = Field(
        default=None,
        gt=0,
        description="Maximum Euclidean distance allowed for returned matches",
    )

    @root_validator
    def _validate_query(cls, values: Dict[str, Any]) -> Dict[str, Any]:
        if not values.get("embedding") and not values.get("image_path"):
            raise ValueError("Provide either an embedding or an image_path")
        return values


def get_pipeline(request: Request) -> PipelineService:
    """Resolve the pipeline service stored on the FastAPI application state."""

    service = getattr(request.app.state, "pipeline_service", None)
    if service is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Pipeline service not configured on application state",
        )
    return service


@router.post("/vision/faces", response_model=FaceVisionResult, status_code=status.HTTP_200_OK)
async def detect_faces(
    payload: FaceVisionRequest,
    service: PipelineService = Depends(get_pipeline),
) -> FaceVisionResult:
    """Run SCRFD + ArcFace style processing and persist results."""

    try:
        return service.process_face_image(Path(payload.image_path), metadata=payload.metadata or {})
    except PipelineServiceError as exc:  # pragma: no cover - exercised in integration tests
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc


@router.post("/search/faces", response_model=FaceSearchResponse, status_code=status.HTTP_200_OK)
async def search_faces(
    payload: FaceSearchRequest,
    service: PipelineService = Depends(get_pipeline),
) -> FaceSearchResponse:
    """Perform a KNN lookup for similar faces."""

    try:
        query_source = "embedding"
        embedding: List[float]
        if payload.image_path:
            embedding = service.generate_embedding(Path(payload.image_path))
            query_source = "image"
        elif payload.embedding is not None:
            embedding = [float(value) for value in payload.embedding]
        else:  # pragma: no cover - validated by Pydantic but guards the type checker
            raise PipelineServiceError("No valid search input provided")

        response = service.search_faces(embedding, k=payload.k, threshold=payload.threshold)
        response.query_source = query_source
        return response
    except PipelineServiceError as exc:  # pragma: no cover - exercised in integration tests
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc
