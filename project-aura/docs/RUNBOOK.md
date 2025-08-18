# Runbook

## Developing
- Activate the virtual environment and run `ruff`, `mypy`, and `pytest`.
- Profiles are stored in `aura/core/profiles`. Add a new `<app>_profile.yaml` and update `config.yaml`.

## Adding Providers
1. Create a new module under `aura/providers/<category>/<name>.py` implementing the appropriate protocol.
2. Register the provider in `aura/app.py`'s `PROVIDER_MAP` and expose configuration in `config.yaml`.

## Common Tasks
- **Run application:** `python -m aura.app`
- **Smoke test:** `powershell scripts/smoke_check.ps1`
