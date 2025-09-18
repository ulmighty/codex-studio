#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

missing=()
lanes=(
  VISION_PKG
  AUDIO_PKG
  INDEXER_PKG
  BACKEND_API
  CLI_ORCH
  WEB_UI
  TESTS_QA
  DOCS
  SECURITY_QC
  PERF_TUNING
)

for lane in "${lanes[@]}"; do
  brief="prompts/lanes/${lane}/BRIEF.md"
  artifacts="prompts/lanes/${lane}/ARTIFACTS.md"
  [[ -f "$brief" ]] || missing+=("$brief")
  [[ -f "$artifacts" ]] || missing+=("$artifacts")
  if [[ -f "$brief" ]]; then
    if ! grep -q "## Goals" "$brief"; then
      missing+=("${brief} (missing '## Goals' section)")
    fi
    if ! grep -q "## Acceptance Checks" "$brief"; then
      missing+=("${brief} (missing '## Acceptance Checks' section)")
    fi
    if ! grep -q "## CI Steps" "$brief"; then
      missing+=("${brief} (missing '## CI Steps' section)")
    fi
  fi
  if [[ -f "$artifacts" ]] && ! grep -q "Status" "$artifacts"; then
    missing+=("${artifacts} (missing status annotation)")
  fi
done

[[ -f "prompts/ARTIFACTS.md" ]] || missing+=("prompts/ARTIFACTS.md")
[[ -f "prompts/merge-plan.md" ]] || missing+=("prompts/merge-plan.md")
[[ -f "scripts/verify-structure.sh" ]] || missing+=("scripts/verify-structure.sh")
[[ -f ".github/workflows/qc-arbiter-merge.yml" ]] || missing+=(".github/workflows/qc-arbiter-merge.yml")
[[ -f "README.md" ]] || missing+=("README.md")

if [[ ${#missing[@]} -gt 0 ]]; then
  printf 'Structure verification failed. Missing or invalid artifacts:\n' >&2
  for item in "${missing[@]}"; do
    printf ' - %s\n' "$item" >&2
  done
  exit 1
fi

echo "FaceTrace structure check passed for lanes: ${lanes[*]}"
