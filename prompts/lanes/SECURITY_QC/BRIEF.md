# SECURITY_QC Lane Brief

## Goals
- Enforce security guardrails: path traversal prevention, binary execution allowlist (ffmpeg, whisper.cpp main), and offline integrity checks.
- Review all lanes for secrets handling, sandboxing, and compliance with privacy obligations.
- Provide automated scanners or scripts that run quickly in CI and integrate with Merge Queue gating.
- Maintain risk register documenting mitigations, exceptions, and follow-up actions.

## Primary Files and Directories
- `security/` – policies, scripts, and audit reports.
- `scripts/security/` – fast-running static/dynamic security checks.
- `.github/workflows/security.yml` – optional dedicated workflow to run security checks when labels applied.
- `security/RISK_REGISTER.md` – living document capturing issues and resolutions.

## Acceptance Checks
- Security scan script flags disallowed binary executions and path traversal attempts across the repo.
- All lanes deliver `ARTIFACTS.md` entries cross-referenced in the risk register when relevant.
- Merge Queue requires passing security job or recorded waiver approved by QC Arbiter.
- `ARTIFACTS.md` summarises findings, mitigations, and outstanding vulnerabilities.

## CI Steps
- `scripts/verify-structure.sh`
- `scripts/security/run.sh` (to be authored)
- `bandit -r apps packages scripts`
