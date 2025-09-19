# Security Overview

FaceTrace enforces a strict offline-first posture. The current release ships
with the following guardrails to keep data, models, and pipelines isolated.

## Network Egress

- The Nebula DOM Cartographer inference adapter refuses outbound requests by
  default. Payloads must carry an explicit `@allow-network` annotation (or set
  `allowNetwork: true`) before any egress is attempted.
- Requests that do not opt in raise a blocking error and never invoke `fetch`,
  ensuring the pipeline stays air-gapped unless an operator authorises a
  connection.

## File-System Safety

- The Control Room server exposes a hardened `safeJoin` helper that resolves and
  normalises all file paths inside `/workspace/.nexusforge`.
- Directory traversal and symlink escapes are rejected before any read/write
  occurs. Live log streaming re-validates the canonical path on every read so a
  swapped symlink cannot leak data.

## Privacy Controls

- The UI now visualises detected faces with an explicit privacy banner. When
  privacy mode is enabled, any face without a whitelist/label is blurred before
  rendering so unvetted identities never appear in clear text.

## Provenance Tracking

- Project Aura records the SHA-256 hash of the active codebase and configured
  language model into a SQLite provenance database (`~/.cache/project_aura` by
  default).
- Repeated runs update existing rows instead of duplicating them, keeping an
  auditable trail of the latest versions used in production.

## Reporting Issues

Security vulnerabilities should be reported privately to the maintainers.
Please include repro steps and any relevant context so fixes can be triaged
quickly.
