# FaceTrace Orchestration

## Charter
FaceTrace is an offline media-forensics stack that unifies vision, audio, indexing, and delivery surfaces under strict privacy, security, and determinism guardrails. This repository coordinates lane-specific workstreams that will deliver the full experience through sequential PRs managed by a merge queue.

## Getting Started
1. Clone the repository and ensure you are on a feature branch (never push directly to `main`).
2. Run `./scripts/verify-structure.sh` to confirm the orchestrator scaffolding is intact.
3. Review lane briefs in `prompts/lanes/*/BRIEF.md` for scope, ownership, and CI expectations before starting any implementation work.
4. Record lane deliverables in the corresponding `ARTIFACTS.md` file as you develop; these act as the source of truth for QC.

## Running Lane Prompts
- Each lane executes independently and must submit its own PR using squash merge through the queue.
- Lane PRs must stay within the file boundaries listed in their brief; cross-lane changes require explicit coordination noted in the merge plan.
- Always honour offline requirements (no runtime downloads) and enforce privacy blur + transcription disclaimers described in the briefs.

## Merge Queue Workflow
- Apply `qc:pending` when opening a PR. Once QC approval is granted and the label changes to `qc:approved`, the `QC Arbiter Merge Queue` workflow automatically enqueues the PR for a squash merge.
- Ensure CI pipelines referenced in each brief are green before requesting queue placement.
- If queue submission fails, review workflow logs and address outstanding checks before retrying.

## Contact Points
- QC Arbiter coordinates lane scheduling and approves merge queue entries.
- Security reviews and performance benchmarking occur in dedicated lanes after core functionality lands, as defined in `prompts/merge-plan.md`.
