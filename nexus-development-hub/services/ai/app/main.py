from __future__ import annotations

from typing import List

from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI()


@app.get("/health")
async def health() -> dict:
    """Health check endpoint."""
    return {"status": "ok"}


@app.get("/")
async def root() -> dict:
    return {"message": "AI service"}


class IngestPayload(BaseModel):
    """Minimal schema for embedding ingestion requests."""

    embeddings: List[List[float]]
    dry_run: bool = False


@app.post("/ingest")
async def ingest(payload: IngestPayload) -> dict:
    """Accept batched embeddings and optionally run a dry-run."""

    count = len(payload.embeddings)
    status = "dry-run" if payload.dry_run else "ingested"
    return {"status": status, "count": count, "dry_run": payload.dry_run}
