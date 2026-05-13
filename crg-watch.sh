#!/bin/bash
# crg-watch.sh — auto-update graph khi file thay đổi
# Usage: ./crg-watch.sh /path/to/your/project

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

PROJECT_PATH="${1:-$(pwd)}"
PROJECT_NAME=$(basename "$PROJECT_PATH")
CRG_DATA_DIR="${CRG_DATA_DIR:-${SCRIPT_DIR}/data/${PROJECT_NAME}}"

if ! docker image inspect code-review-graph:local &>/dev/null; then
  echo "[crg] Image chưa có, building..." >&2
  docker build -t code-review-graph:local "${SCRIPT_DIR}"
fi

mkdir -p "$CRG_DATA_DIR"

echo "[crg] Watching: $PROJECT_NAME"
echo "[crg] Path: $PROJECT_PATH"
echo "[crg] Data: $CRG_DATA_DIR"
echo "[crg] Ctrl+C để dừng"

exec docker run --rm -it \
  --name "crg-watch-${PROJECT_NAME}-$$" \
  -v "${PROJECT_PATH}:/workspace:ro" \
  -v "${CRG_DATA_DIR}:/data" \
  -e CRG_DATA_DIR=/data \
  -e CRG_REPO_ROOT=/workspace \
  code-review-graph:local \
  code-review-graph watch
