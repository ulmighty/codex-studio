# DOCS Lane Brief

## Goals
- Deliver cohesive documentation covering pipeline architecture, operations, and compliance guardrails.
- Curate lane-specific docs into a unified handbook with navigation for operators and auditors.
- Provide update checklists ensuring ARTIFACTS.md changes sync with docs revisions.
- Maintain offline-friendly output formats (Markdown/PDF) without relying on SaaS tooling.

## Primary Files and Directories
- `docs/` – top-level documentation site with subpages per lane.
- `docs/handbook/` – compiled operator and auditor guides.
- `README.md` – keep charter and quickstart instructions accurate.
- `docs/changelog.md` – track releases, seeds, and dependency versions.

## Acceptance Checks
- Documentation build command (e.g., `mkdocs build` or static generator) runs offline and produces deterministic output.
- Every lane’s `ARTIFACTS.md` is reflected in docs or cross-linked.
- Quickstart instructions verified by dry-run from clean checkout.
- `ARTIFACTS.md` enumerates new doc pages, diagrams, and outstanding content gaps.

## CI Steps
- `scripts/verify-structure.sh`
- `mkdocs build --strict` (or equivalent chosen static site tool)
- `markdownlint docs/**/*.md README.md`
