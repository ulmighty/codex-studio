# FaceTrace Orchestration

FaceTrace is an offline media-forensics stack that unifies vision, audio, indexing, and delivery surfaces under strict privacy, security, and determinism guardrails. This repository coordinates lane-specific workstreams that deliver the full experience through sequential pull requests managed by the merge queue.

## Charter
- Uphold offline-first principles: every workflow must succeed without public network access.
- Preserve privacy by default, including automatic blurring of unlabeled faces and explicit transcription disclaimers.
- Maintain deterministic behaviour across runs by pinning model fingerprints, seeds, and dependency versions.
- Document every lane deliverable in the corresponding `ARTIFACTS.md` file so QC can audit and reproduce the stack.

## Repository Layout
- `apps/` – application entry points (CLI orchestrator, FastAPI backend, Next.js web UI).
- `packages/` – reusable inference and indexing libraries for the vision, audio, and indexer lanes.
- `tests/` – shared fixtures and integration smoke tests owned by the TESTS_QA lane.
- `prompts/` – lane briefs, merge plan, and artifact ledgers that drive the roadmap.
- `scripts/` – repository automation, including structure verification and future perf/security tooling.
- `docs/` – canonical operator and auditor documentation (populated as the DOCS lane lands).

## Offline Quickstart & Run Steps
1. **Clone and branch**
   ```bash
   git clone git@github.com:facetrace/orchestrator.git
   cd orchestrator
   git checkout -b feature/<lane>/<ticket>
   ```
2. **Verify the scaffolding** – run `./scripts/verify-structure.sh` after every pull to confirm mandatory briefs and artifact ledgers remain intact.
3. **Provision runtimes** – FaceTrace targets Python 3.11+, Node.js 18 LTS, and a recent C++ toolchain for native extensions such as `whisper.cpp`.
   ```bash
   python -m venv .venv
   source .venv/bin/activate
   pip install -r requirements.txt  # offline mirror only

   pushd apps/web
   npm install --offline
   popd
   ```
4. **Stage local models** – download approved model binaries on an air-gapped machine, checksum them, and copy them into `models/` as documented in [Model Placement](#model-placement).
5. **Seed configuration** – duplicate `configs/pipeline.example.yaml` to `configs/pipeline.yaml`, then update model paths, deterministic seeds, and hardware affinities to match your environment. Commit the template only; never push secrets or proprietary media.
6. **Execute the pipeline** – trigger the orchestrator CLI, then bring up the API and UI for validation:
   ```bash
   # Run the deterministic end-to-end sweep with fixture media
   python -m apps.cli run --sample-config configs/pipeline.yaml

   # Launch the backend (FastAPI)
   uvicorn apps.api.main:app --host 0.0.0.0 --port 8000

   # Start the offline web client in another shell
   pushd apps/web
   npm run dev -- --offline
   popd
   ```
   The CLI will emit run IDs, the backend exposes `/healthz` and `/admin/queue` for inspection, and the web UI provides analyst tooling described in the [UX Tour](#ux-tour-ten-pipeline-features).
7. **Run quality gates** – execute lane-specific linters/tests plus `./scripts/verify-structure.sh` before requesting QC approval. The TESTS_QA lane will consolidate them into a single `make test` entry point.
8. **Submit via merge queue** – label the pull request with `qc:pending`. Once approved and all checks are green, the QC Arbiter workflow enqueues your change for squash merge.

> **Note:** All package managers must resolve from pre-seeded mirrors or local caches. Online installs violate the offline charter and will be rejected during QC.

## Model Placement
FaceTrace ships without heavy model binaries. Operators are responsible for staging validated artifacts in the local filesystem referenced by `configs/pipeline.yaml`.

| Model | Expected Location | Notes |
| --- | --- | --- |
| Whisper (tiny/base/medium) GGML | `models/whisper/ggml-<size>.bin` | Build with `whisper.cpp` offline; record SHA256 in `prompts/lanes/AUDIO_PKG/ARTIFACTS.md`. |
| RNNoise (optional denoiser) | `models/audio/rnnoise.onnx` | Enable via `audio.preprocessing.denoise: true` in the config. |
| Vision detection weights | `models/vision/<detector>/model.onnx` | Provide both detector and landmark weights; blur behaviour depends on these being reachable. |
| Face embedding network | `models/vision/<embedder>/model.fp16` | Must align with FAISS index schema specified by INDEXER_PKG. |
| FAISS shards | `indexes/faiss/*.index` | Store in encrypted volumes when handling sensitive cases; reference them in `INDEXER_PKG` configs. |

1. Generate checksums on the staging machine (`shasum -a 256 <file>`).
2. Update `configs/pipeline.yaml` to reference absolute paths or repo-relative paths under `models/`.
3. Record the checksum, provenance, and seed pairing in the relevant `ARTIFACTS.md` entry.
4. Do **not** commit model binaries to the repository unless directed to use Git LFS for synthetic fixtures.

## Whisper Privacy & Accuracy Disclaimers
- Every transcript or inference derived from Whisper must be surfaced with the phrase: **“Automated transcription. May contain inaccuracies.”**
- UI surfaces should couple the disclaimer with timestamp metadata and source attribution.
- Store transcripts alongside disclaimer metadata inside the backend response schema so downstream consumers inherit the guardrail automatically.
- Operators must not share Whisper outputs externally without manual verification and redaction of sensitive audio content.

## UX Tour: Ten Pipeline Features
1. **Offline Project Bootstrap (CLI_ORCH)** – The command-line orchestrator spins up deterministic runs, showing progress per lane and surfacing exit codes that map to remediation steps in `TROUBLESHOOTING.md`.
2. **Evidence Intake Queue (BACKEND_API)** – Analysts upload or register media to the FastAPI backend, which validates checksums, schedules processing, and exposes queue controls under `/admin/queue`.
3. **Vision Privacy Monitor (VISION_PKG)** – The vision toolkit processes frames locally, presenting side-by-side blurred previews so reviewers can verify that unlabeled faces remain obfuscated.
4. **Temporal Scene Timeline (VISION_PKG + WEB_UI)** – The web UI plots detected scenes and events on a scrub-able timeline, enabling quick jumps to notable segments in videos.
5. **Audio Forensics Lab (AUDIO_PKG)** – Spectral orb/shadow visualisations and EVP captures appear in the UI, with sliders for denoise strength powered by offline RNNoise weights.
6. **Whisper Transcript Review Panel (AUDIO_PKG + WEB_UI)** – Transcripts stream into a collapsible panel with the mandated disclaimer, speaker segmentation, and precise timestamps for cross-reference.
7. **Multimodal Search Workspace (INDEXER_PKG)** – Unified FAISS indexes allow analysts to search by face embeddings, acoustic fingerprints, or textual keywords across processed assets.
8. **Device Health & Auto-Tuning (BACKEND_API)** – The backend surfaces GPU/CPU utilisation, fan speeds, and thermal headroom gleaned from the device manager so operators can adjust hardware allocations without downtime.
9. **Investigator Notebook & Export (DOCS + WEB_UI)** – Analysts can annotate findings, capture screenshots, and export offline investigation bundles complete with audit trails for compliance reviews.
10. **QC Guardrail Dashboard (SECURITY_QC + TESTS_QA + PERF_TUNING)** – A consolidated dashboard highlights security scan results, performance baselines, and regression alerts, guiding release readiness before queuing a merge.

## Operational Guardrails
- Each lane must work within its scoped directories listed in the lane briefs under `prompts/lanes/*/BRIEF.md`.
- Offline requirements are mandatory: use cached Python wheels, npm packages, and model binaries.
- Always document changes in the appropriate `ARTIFACTS.md` file; these form the QC source of truth.
- Coordinate cross-lane changes in `prompts/merge-plan.md` and document follow-ups in the risk register when applicable.

## Support & Contact Points
- **QC Arbiter** – coordinates lane scheduling, approves merge queue entries, and validates guardrails.
- **Security Reviewers** – manage sandboxing, binary allowlists, and compliance attestations.
- **Performance Leads** – benchmark inference/indexing throughput and recommend hardware tuning (see `HARDWARE.md`).
- For urgent operational blockers, raise an incident in the shared offline war room and document root causes in `TROUBLESHOOTING.md`.

