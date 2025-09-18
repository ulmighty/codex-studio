# AUDIO_PKG Lane Brief

## Goals
- Implement offline audio forensics pipeline including EVP capture, spectral orb/shadow analysis, and Whisper transcription (via local whisper.cpp builds).
- Ensure every transcript and inference output is tagged with the “may be inaccurate” disclaimer per guardrail 6.
- Produce embeddings aligned with `INDEXER_PKG` schema and expose hooks for BACKEND_API ingestion.
- Maintain deterministic behaviour through explicit sampling seeds and cached model fingerprints recorded in `ARTIFACTS.md`.

## Primary Files and Directories
- `packages/audio/` – EVP capture, preprocessing, Whisper wrappers, and embedding utilities.
- `configs/pipeline.yaml` – read-only for model paths; coordinate changes with BACKEND_API before editing.
- `tests/audio/` – pytest suite using tiny fixture clips located under `tests/fixtures/audio/`.
- `docs/audio.md` – operational notes and calibration guidance (final polish by `DOCS`).

## Acceptance Checks
- Offline transcription demo (`python -m packages.audio.cli sample.wav`) finishes without network access, storing disclaimer-tagged transcripts.
- EVP/orb/shadow analyzers emit deterministic feature vectors for the same sample across runs.
- Privacy policy audit: confirm no raw microphone access persists beyond processing window and logs exclude PII.
- `ARTIFACTS.md` lists build commands for whisper.cpp binaries and verifies SHA256 sums of bundled assets.

## CI Steps
- `pytest tests/audio --maxfail=1 --disable-warnings -q`
- `ruff check packages/audio tests/audio`
- `scripts/verify-structure.sh`
