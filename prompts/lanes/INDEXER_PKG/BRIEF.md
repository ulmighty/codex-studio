# INDEXER_PKG Lane Brief

## Goals
- Provide a deterministic FAISS-based index builder that ingests embeddings from VISION_PKG and AUDIO_PKG.
- Support incremental updates and compaction without blocking search availability for BACKEND_API.
- Define canonical metadata schema (`indexes/faiss/schema.json`) consumed by downstream lanes.
- Enforce offline operation: no remote stores, no background downloads, and reproducible index sharding.

## Primary Files and Directories
- `packages/indexer/` – FAISS wrapper modules, ingest pipeline, and search utilities.
- `indexes/` – persisted FAISS shards, manifest files, and snapshots (store under git-lfs or .gitignored as appropriate).
- `configs/pipeline.yaml` – update only to register index definitions shared with BACKEND_API and CLI_ORCH.
- `tests/indexer/` – deterministic index creation tests using synthetic embeddings committed in fixtures.

## Acceptance Checks
- Index build command (`python -m packages.indexer.build --config configs/pipeline.yaml`) completes using offline fixtures.
- Search results remain consistent across runs by verifying hashed top-K output.
- Manifest integrity check ensures all shards list SHA256s and version numbers.
- `ARTIFACTS.md` captures FAISS version, compile options, and snapshot layout.

## CI Steps
- `pytest tests/indexer --maxfail=1 --disable-warnings -q`
- `ruff check packages/indexer tests/indexer`
- `scripts/verify-structure.sh`
