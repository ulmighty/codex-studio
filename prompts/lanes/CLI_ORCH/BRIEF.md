# CLI_ORCH Lane Brief

## Goals
- Deliver a command-line orchestrator that triggers the end-to-end FaceTrace pipeline offline.
- Provide runbooks for sequencing VISION_PKG, AUDIO_PKG, and INDEXER_PKG components with deterministic seeds.
- Expose progress telemetry and error codes consumable by BACKEND_API and TESTS_QA.
- Ensure CLI never mutates directories owned by other lanes without explicit contracts.

## Primary Files and Directories
- `apps/cli/` – CLI entrypoints, orchestration logic, and environment bootstrap scripts.
- `configs/pipeline.yaml` – reference only for stage ordering and asset paths; coordinate updates with API team.
- `tests/cli/` – regression tests covering dry-run, full-run, and failure reporting scenarios.
- `docs/cli.md` – operator instructions for offline execution (final polishing delegated to DOCS lane).

## Acceptance Checks
- `python -m apps.cli run --sample-config configs/pipeline.yaml` completes using fixture media and reports deterministic run IDs.
- Dry-run mode produces plan output without executing heavy inference.
- Error scenarios bubble exit codes documented in README, with no partial artifacts left behind.
- `ARTIFACTS.md` captures CLI commands, environment variables, and log retention policies.

## CI Steps
- `pytest tests/cli --maxfail=1 --disable-warnings -q`
- `ruff check apps/cli tests/cli`
- `scripts/verify-structure.sh`
