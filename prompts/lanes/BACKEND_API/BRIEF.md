# BACKEND_API Lane Brief

## Goals
- Deliver the FastAPI backend serving media-forensics APIs for ingestion, search, and analytics.
- Integrate with hardware auto-tuning in `projects/FacialRecog/apps/api/app/services/device_manager.py` without bypassing its logic.
- Wire adapters for VISION_PKG, AUDIO_PKG, and INDEXER_PKG outputs while preserving deterministic responses.
- Expose admin endpoints for queue management and index refresh gated by authentication middleware.

## Primary Files and Directories
- `projects/FacialRecog/apps/api/` – FastAPI application modules, routers, schemas, and dependency wiring.
- `projects/FacialRecog/apps/api/app/services/device_manager.py` – read-only for orchestrator; only extend via provided hooks or configuration.
- `projects/FacialRecog/configs/pipeline.yaml` – register pipeline stages, ensuring version bumps recorded in ARTIFACTS.
- `tests/api/` – API contract tests and fixture payloads for regression coverage.

## Acceptance Checks
- `uvicorn projects.FacialRecog.apps.api.app.main:app --reload` (or equivalent) starts locally using only offline dependencies.
- Integration tests confirm search endpoints return deterministic ordering with identical inputs.
- Privacy enforcement: assets retrieved through API respect blurred-face and disclaimer rules from VISION_PKG/AUDIO_PKG.
- `ARTIFACTS.md` documents exposed endpoints, configuration defaults, and seed management.

## CI Steps
- `pytest projects/FacialRecog/tests/api --maxfail=1 --disable-warnings -q`
- `ruff check projects/FacialRecog/apps/api projects/FacialRecog/tests/api`
- `scripts/verify-structure.sh`
