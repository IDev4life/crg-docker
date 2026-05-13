#!/bin/bash
# crg-build.sh — full build graph cho project
# Usage: ./crg-build.sh /path/to/your/project

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

PROJECT_PATH="${1:-$(pwd)}"
PROJECT_NAME=$(basename "$PROJECT_PATH")

CRG_DATA_DIR="${CRG_DATA_DIR:-${SCRIPT_DIR}/data/${PROJECT_NAME}}"
mkdir -p "$CRG_DATA_DIR"

echo "[crg] Building graph cho: $PROJECT_NAME"
echo "[crg] Path: $PROJECT_PATH"
echo "[crg] Data dir: $CRG_DATA_DIR"

docker run --rm \
  -v "${PROJECT_PATH}:/workspace:ro" \
  -v "${CRG_DATA_DIR}:/data" \
  -e CRG_DATA_DIR=/data \
  -e CRG_REPO_ROOT=/workspace \
  code-review-graph:local \
  code-review-graph build

echo "[crg] Done! Graph saved: ${CRG_DATA_DIR}"