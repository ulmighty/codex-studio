#!/usr/bin/env bash
set -e
ROOT="$(dirname "$0")/.."
cd "$ROOT"
npm install
npm run build
