# VISION_PKG Lane Brief

## Goals
- Build the offline vision toolkit that detects faces, landmarks, scenes, and temporal events from local media.
- Enforce privacy mode by blurring every face that lacks an explicit whitelist label before any asset leaves the package.
- Provide deterministic outputs by seeding all stochastic models and logging model + data versions in `ARTIFACTS.md`.
- Surface embeddings compatible with the FAISS indexer defined in `INDEXER_PKG` without leaking implementation details.

## Primary Files and Directories
- `packages/vision/` – core inference code (detection, embedding, post-processing utilities).
- `configs/pipeline.yaml` – read-only for model path references; treat updates as coordinated changes with BACKEND_API.
- `tests/vision/` – fast-running unit tests using small fixtures stored under `tests/fixtures/vision/`.
- `docs/vision.md` – interface contract and troubleshooting notes (hand off to `DOCS` lane after draft).

## Acceptance Checks
- CLI smoke test (`python -m packages.vision.cli sample.mp4`) completes without network access and emits blurred preview frames.
- Generated metadata JSON contains deterministic hashes for frame batches when executed twice on the same media.
- Blurred outputs verify that unlabelled faces remain obfuscated; labelled faces are untouched.
- `ARTIFACTS.md` enumerates new binaries, cached weights, and deterministic seed choices.

## CI Steps
- `pytest tests/vision --maxfail=1 --disable-warnings -q`
- `ruff check packages/vision tests/vision`
- `scripts/verify-structure.sh`
