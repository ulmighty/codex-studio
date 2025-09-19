#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
REPO_ROOT=$(cd "${PROJECT_ROOT}/../.." && pwd)
CHECK_MODE=0

if [[ "${1:-}" == "--check" ]]; then
  CHECK_MODE=1
fi

info() {
  printf '\033[1;34m[facialrecog]\033[0m %s\n' "$*"
}

warn() {
  printf '\033[1;33m[facialrecog]\033[0m %s\n' "$*"
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf '\033[1;31mMissing required command: %s\033[0m\n' "$1" >&2
    exit 1
  fi
}

info "Validating runtime prerequisites"
require_cmd node
require_cmd pnpm
require_cmd python3

if [[ ${CHECK_MODE} -eq 1 ]]; then
  info "--check mode enabled; prerequisites satisfied"
  exit 0
fi

info "Installing JavaScript workspace dependencies (pnpm -w)"
if [[ -f "${REPO_ROOT}/package.json" ]]; then
  (cd "${REPO_ROOT}" && pnpm install -w)
else
  warn "No root package.json detected; skipping pnpm workspace install"
fi

VENV_PATH="${PROJECT_ROOT}/.venv"
if [[ ! -d "${VENV_PATH}" ]]; then
  info "Creating project virtual environment"
  python3 -m venv "${VENV_PATH}"
fi

# shellcheck disable=SC1090
source "${VENV_PATH}/bin/activate"
info "Using Python interpreter: $(python --version 2>&1)"
python -m pip install --upgrade pip >/dev/null
export PYTHONPATH="${PROJECT_ROOT}:${PYTHONPATH:-}"

info "Installing local FacialRecog packages (editable)"
for package_dir in "${PROJECT_ROOT}/packages"/*; do
  if [[ -d "${package_dir}" ]]; then
    if [[ -f "${package_dir}/pyproject.toml" || -f "${package_dir}/setup.py" ]]; then
      info "pip install -e ${package_dir}"
      if ! python -m pip install -e "${package_dir}"; then
        warn "Editable install failed for ${package_dir}; ensure dependencies are mirrored offline"
      fi
    else
      warn "Skipping ${package_dir} (no packaging metadata)"
    fi
  fi
done

API_PID=""
WEB_PID=""

if [[ -d "${PROJECT_ROOT}/apps/api" ]]; then
  info "Starting FastAPI service on http://localhost:8000"
  (cd "${REPO_ROOT}" && uvicorn projects.FacialRecog.apps.api.app.main:app --host 0.0.0.0 --port 8000 &)
  API_PID=$!
  info "FastAPI PID: ${API_PID}"
else
  warn "No API app detected"
fi

start_next_app() {
  local app_dir="$1"
  local label="$2"
  if [[ -f "${app_dir}/package.json" ]]; then
    info "Starting ${label} Next.js app on http://localhost:3000"
    (cd "${app_dir}" && pnpm dev -- --port 3000 &)
    WEB_PID=$!
    info "${label} PID: ${WEB_PID}"
  else
    warn "${label} app missing package.json; skipping"
  fi
}

if [[ -d "${PROJECT_ROOT}/apps/webui" ]]; then
  start_next_app "${PROJECT_ROOT}/apps/webui" "webui"
elif [[ -d "${PROJECT_ROOT}/apps/facialrecog" ]]; then
  start_next_app "${PROJECT_ROOT}/apps/facialrecog" "facialrecog"
else
  warn "No Next.js app found under ${PROJECT_ROOT}/apps"
fi

cleanup() {
  info "Shutting down services"
  if [[ -n "${WEB_PID}" ]]; then
    kill "${WEB_PID}" >/dev/null 2>&1 || true
  fi
  if [[ -n "${API_PID}" ]]; then
    kill "${API_PID}" >/dev/null 2>&1 || true
  fi
}

trap cleanup EXIT

info "Services running. Press CTRL+C to stop."
wait
