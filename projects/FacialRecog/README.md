# 🔍 FacialRecog

FacialRecog is the offline-first media forensics stack inside the codex-studio monorepo. It bundles deterministic vision, audio, and indexing utilities with a FastAPI service and operator tooling designed for air-gapped review environments.

## 🚀 Quickstart

```bash
bash projects/FacialRecog/scripts/dev.sh
```

Use `--check` to run prerequisite validation without launching long-lived services.

## 🧩 Project Layout

```
projects/FacialRecog/
├─ apps/
│  ├─ api/                # FastAPI surface exposing ingest/search routes
│  └─ facetrace_cli/      # Operator CLI orchestration helpers
├─ packages/
│  ├─ audio/              # EVP extraction, diarisation, transcription
│  ├─ vision/             # Detection, embeddings, scene simulation
│  └─ perf/               # Synthetic benchmarking harness
├─ configs/
│  └─ pipeline.yaml       # Sample pipeline configuration stub
├─ scripts/
│  └─ dev.sh              # Workspace bootstrap & service runner
├─ tests/                 # Pytest suites for audio + perf lanes
└─ ARTIFACTS.md           # Movement ledger for repo hygiene
```

## 🛠 Services

| Service | Port | Description |
| --- | --- | --- |
| FastAPI | 8000 | `uvicorn` entrypoint defined in `projects.FacialRecog.apps.api.app.main` |
| Web UI | 3000 | Placeholder Next.js slot (`apps/webui` or `apps/facialrecog`) started by the dev script when present |

The dev script will report process IDs and clean up both services when you exit with `CTRL+C`.

## 🧠 Models & Pipelines

Model paths and deterministic seeds live in [`projects/FacialRecog/configs/pipeline.yaml`](configs/pipeline.yaml). Duplicate the stub, point it at your offline model cache, and record checksum + seed changes in `ARTIFACTS.md`.

## 🔐 Privacy Disclaimer

Every transcription or inference surfaced by FacialRecog must include the statement: **"Automated transcription. May contain inaccuracies."** Ensure the disclaimer accompanies stored transcripts, analyst exports, and any UI elements that render Whisper outputs.

## 🧪 Testing & Tooling

- `python -m pytest projects/FacialRecog/tests`
- `python -m projects.FacialRecog.packages.perf.cli --dry-run`
- `pnpm -C projects/FacialRecog/apps/api lint` *(when a Node toolchain is configured)*

The developer script provisions a `.venv` within the project, installs editable packages, and launches available services.

## 🆘 Troubleshooting

Refer to the shared [TROUBLESHOOTING.md](../../TROUBLESHOOTING.md) playbook for remediation steps covering model placement, deterministic seeds, and offline bootstrap issues.
