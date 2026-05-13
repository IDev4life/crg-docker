#!/bin/bash
# crg-update.sh — incremental update graph (nhanh hơn build, chỉ parse file thay đổi)
# Usage: ./crg-update.sh /path/to/your/project
#        ./crg-update.sh  # dùng thư mục hiện tại

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

echo "[crg] Updating graph: $PROJECT_NAME"
echo "[crg] Path: $PROJECT_PATH"
echo "[crg] Data: $CRG_DATA_DIR"

docker run --rm \
  -v "${PROJECT_PATH}:/workspace:ro" \
  -v "${CRG_DATA_DIR}:/data" \
  -e CRG_DATA_DIR=/data \
  -e CRG_REPO_ROOT=/workspace \
  code-review-graph:local \
  code-review-graph update

echo "[crg] Done!"
