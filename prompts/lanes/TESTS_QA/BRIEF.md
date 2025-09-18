# TESTS_QA Lane Brief

## Goals
- Establish unified test scaffolding, fixtures, and reporting for all FaceTrace lanes.
- Provide smoke-test pipelines that orchestrate VISION_PKG + AUDIO_PKG + INDEXER_PKG through CLI_ORCH.
- Integrate coverage reporting and CI gating compatible with Merge Queue requirements.
- Ensure tests remain deterministic and complete quickly (<5 minutes) on CI hardware.

## Primary Files and Directories
- `tests/` – shared test utilities, fixtures, and cross-lane scenarios.
- `tests/fixtures/` – curated offline media snippets, transcripts, and expected index outputs.
- `tools/qa/` – helper scripts for running aggregated QA flows.
- `.github/workflows/ci.yml` – coordinate with QC Arbiter for full test plan (co-author with SECURITY_QC if needed).

## Acceptance Checks
- Unified `make test` (or `tox`, `nox`) entrypoint runs lane-level suites and aggregated integration tests.
- Fixture registry documents asset provenance and licensing with no PII.
- Deterministic random seeds shared across tests via central helper module.
- `ARTIFACTS.md` enumerates fixtures, coverage artefacts, and follow-up bugs.

## CI Steps
- `scripts/verify-structure.sh`
- `pytest tests --maxfail=1 --disable-warnings -q` (or orchestrated equivalent once defined)
- `coverage xml` (ensure run time remains under guardrail)
