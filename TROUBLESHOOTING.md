# FaceTrace Troubleshooting Guide

This guide covers the most common failure modes observed while operating the FaceTrace stack offline. Resolve issues locally before escalating to QC Arbiter; document root causes and fixes in lane-specific `ARTIFACTS.md` files.

## Repository Verification Failures
**Symptoms:** `./scripts/verify-structure.sh` exits non-zero.

**Resolution:**
1. Read the missing artifact list printed by the script.
2. Restore or regenerate the referenced `prompts/lanes/*/BRIEF.md` or `ARTIFACTS.md` files.
3. Ensure each BRIEF includes `## Goals`, `## Acceptance Checks`, and `## CI Steps` headings.
4. Re-run the script before committing.

## Missing or Misplaced Models
**Symptoms:** CLI run halts with `FileNotFoundError` pointing at `models/` paths, or Whisper initialisation fails.

**Resolution:**
1. Confirm the model filenames match those referenced in `projects/FacialRecog/configs/pipeline.yaml`.
2. Validate SHA256 hashes against the values logged in `prompts/lanes/AUDIO_PKG/ARTIFACTS.md` and `prompts/lanes/VISION_PKG/ARTIFACTS.md`.
3. Check file permissions; the orchestrator requires read access for the service account running the pipeline.
4. After staging models, restart the CLI or backend process to force a fresh load.

## Whisper Accuracy Concerns
**Symptoms:** Analysts flag incorrect transcripts or missing speakers.

**Resolution:**
1. Verify the mandated disclaimer **“Automated transcription. May contain inaccuracies.”** is present wherever transcripts appear.
2. Inspect audio quality—run RNNoise preprocessing via the `audio.preprocessing.denoise` toggle and reprocess the clip.
3. Consider switching to a larger Whisper GGML build if GPU VRAM allows (see `HARDWARE.md`).
4. For mission-critical excerpts, route through manual review and attach confirmation notes to the investigation export.

## Determinism Drift
**Symptoms:** Repeat runs generate different hashes or embeddings.

**Resolution:**
1. Confirm pipeline seeds in `projects/FacialRecog/configs/pipeline.yaml` are fixed integers and not regenerated on each run.
2. Check that CUDA/cuDNN determinism flags are enabled (set `CUDA_LAUNCH_BLOCKING=1` and `CUBLAS_WORKSPACE_CONFIG=:16:8`).
3. Ensure no model weights or fixtures changed between runs; compare commit hashes and `ARTIFACTS.md` entries.
4. If hardware changed, rebaseline benchmarks and document the new fingerprints.

## GPU Memory Exhaustion
**Symptoms:** Inference fails with CUDA OOM errors.

**Resolution:**
1. Reduce batch size in `projects/FacialRecog/configs/pipeline.yaml` for the offending stage (`vision.batch_size`, `audio.transcription.batch_size`).
2. Switch Whisper to a smaller model or pin the transcription stage to a dedicated GPU.
3. Confirm no extraneous processes are consuming VRAM (inspect `nvidia-smi`).
4. Review `HARDWARE.md` to ensure the node meets minimum VRAM requirements.

## Web UI Fails to Load Offline Assets
**Symptoms:** Browser console logs `Failed to load resource` or attempts to reach external CDNs.

**Resolution:**
1. Run `npm install --offline` to ensure dependencies resolve from local cache.
2. Confirm `apps/web/next.config.js` (when available) disables remote images and fonts.
3. Verify fixture media exists under `apps/web/public/` and matches paths used by components.
4. Clear the browser cache or use a private window to avoid stale service worker assets.

## API Health Check Failures
**Symptoms:** `/healthz` returns 500 or `uvicorn` crashes on start.

**Resolution:**
1. Inspect logs for missing environment variables; supply defaults via `.env.offline` and load them in `projects/FacialRecog/apps/api/app/main.py`.
2. Ensure FAISS shards and model paths referenced in configuration exist.
3. Verify database paths or queue directories are writable by the API process.
4. Restart the service after applying fixes and rerun targeted tests from `tests/api/`.

## Merge Queue Rejections
**Symptoms:** PR not enqueued or removed from queue.

**Resolution:**
1. Confirm all required CI jobs are green (lint, tests, structure verification, security scans where applicable).
2. Check that the PR carries `qc:approved` after review.
3. Review workflow logs for the queue job to see if branch protections or missing status checks blocked the merge.
4. Update the PR description with reproduction steps and link to any relevant `TROUBLESHOOTING.md` entries.

For unresolved issues, gather logs, hardware profiles, and repro steps, then notify the QC Arbiter. Always update this document when new failure modes are identified.

