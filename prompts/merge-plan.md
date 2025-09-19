# FaceTrace Merge Plan

Each lane ships as an isolated PR merged through the Merge Queue using squash merges. Labels follow the pattern `lane:<slug>` plus quality gates (`qc:pending`, `qc:approved`). Dependencies reflect required upstream artefacts.

| PR ID | Lane | Summary | Depends On | Required Labels |
|-------|------|---------|------------|-----------------|
| PR-0 | Orchestrator | Repo scaffolding, guardrails, merge automation. | _None_ | `lane:orchestrator`, `qc:approved` |
| PR-1 | VISION_PKG | Offline face/place/event detection & embeddings with privacy blur. | PR-0 | `lane:vision`, `qc:pending` → `qc:approved` |
| PR-2 | AUDIO_PKG | Offline EVP/orb/shadow analysis & Whisper transcripts with disclaimer. | PR-0 | `lane:audio`, `qc:pending` → `qc:approved` |
| PR-3 | INDEXER_PKG | FAISS ingest + search services for embeddings. | PR-1, PR-2 | `lane:indexer`, `qc:pending` → `qc:approved` |
| PR-4 | BACKEND_API | FastAPI service wiring device manager + packages. | PR-1, PR-2, PR-3 | `lane:backend`, `qc:pending` → `qc:approved` |
| PR-5 | CLI_ORCH | Offline CLI orchestrator with deterministic runs. | PR-1, PR-2, PR-3 | `lane:cli`, `qc:pending` → `qc:approved` |
| PR-6 | WEB_UI | Dark Next.js UI with privacy + disclaimer enforcement. | PR-4 | `lane:web`, `qc:pending` → `qc:approved` |
| PR-7 | TESTS_QA | Unified tests, fixtures, and coverage gating. | PR-1, PR-2, PR-3, PR-5 | `lane:qa`, `qc:pending` → `qc:approved` |
| PR-8 | SECURITY_QC | Automated guardrails, risk register, security CI. | PR-1, PR-2, PR-3, PR-4, PR-5 | `lane:security`, `qc:pending` → `qc:approved` |
| PR-9 | PERF_TUNING | Benchmarking & optimization scripts respecting determinism. | PR-1, PR-2, PR-3, PR-4, PR-5 | `lane:perf`, `qc:pending` → `qc:approved` |
| PR-10 | DOCS | Consolidated handbook + quickstart updates. | PR-1 … PR-9 | `lane:docs`, `qc:pending` → `qc:approved` |

## Label Protocol
- `qc:pending` is set automatically on PR open; QC Arbiter flips to `qc:approved` after review.
- `ready-for-queue` (optional) can be applied once CI passes; workflow will enqueue on `qc:approved` regardless.
- Additional cross-cutting labels: `needs-security-review`, `needs-perf-benchmark`, `docs-required` help route reviews.

## Blocking Rules
- PR-3 must not merge before VISION_PKG and AUDIO_PKG provide stable embedding schemas.
- BACKEND_API and CLI_ORCH (PR-4/PR-5) share contracts; coordinate to avoid race conditions in `projects/FacialRecog/configs/pipeline.yaml`.
- WEB_UI waits for BACKEND_API endpoints to stabilize; security/perf/doc lanes execute after core functionality is in place.
- Merge Queue enforces sequential processing; ensure each PR sets `merge_method: squash` via queue entry.
