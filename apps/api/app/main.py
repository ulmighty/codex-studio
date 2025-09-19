"""FastAPI entrypoint exposing FaceTrace pipeline endpoints."""
from __future__ import annotations

import os
from pathlib import Path

from fastapi import FastAPI, Request, status
from fastapi.responses import JSONResponse

from .routers import ingest, search
from .services.pipeline import PipelineService, PipelineServiceError


def create_app() -> FastAPI:
    """Instantiate the FastAPI application and wire dependencies."""

    app = FastAPI(
        title="FaceTrace API",
        description="Media-forensics pipeline providing ingestion, vision, and audio tooling.",
        version="0.1.0",
    )

    config_path = Path(os.getenv("PIPELINE_CONFIG", "configs/pipeline.yaml"))
    app.state.pipeline_service = PipelineService(config_path=config_path)

    app.include_router(ingest.router)
    app.include_router(search.router)

    @app.get("/health", tags=["system"], status_code=status.HTTP_200_OK)
    async def health() -> dict[str, str]:
        """Simple health-check endpoint."""

        return {"status": "ok"}

    @app.exception_handler(PipelineServiceError)
    async def pipeline_exception_handler(
        request: Request, exc: PipelineServiceError
    ) -> JSONResponse:
        """Translate pipeline errors into JSON API responses."""

        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={"detail": str(exc)},
        )

    return app


app = create_app()
