# PERF_TUNING Lane Brief

## Goals
- Profile the entire FaceTrace pipeline and remove bottlenecks while preserving determinism.
- Implement hardware-aware optimizations aligned with `device_manager` auto-tuning logic.
- Benchmark inference, indexing, and UI rendering using offline fixtures with reproducible metrics.
- Coordinate with SECURITY_QC to ensure optimizations do not weaken sandboxing or privacy controls.

## Primary Files and Directories
- `perf/` – benchmark suites, result logs, and tuning scripts.
- `perf/reports/` – markdown/JSON summaries for each release.
- `scripts/perf/` – reusable profiling command wrappers.
- `configs/pipeline.yaml` – reference only for runtime settings; propose adjustments via config PRs.

## Acceptance Checks
- Baseline benchmark script (`scripts/perf/run.sh`) executes end-to-end pipeline using fixture media offline.
- Reports track throughput/latency deltas against previous release and flag regressions beyond agreed thresholds.
- Optimizations documented with toggle-able feature flags and deterministic fallback paths.
- `ARTIFACTS.md` records benchmark environment, seed usage, and recommended tuning parameters.

## CI Steps
- `scripts/verify-structure.sh`
- `scripts/perf/run.sh --smoke`
- `pytest perf/tests --maxfail=1 --disable-warnings -q`
