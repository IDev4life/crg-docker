#!/bin/bash
# crg-viz.sh — export graph visualization ra HTML
# Usage: ./crg-viz.sh /path/to/your/project [output.html]

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

PROJECT_PATH="${1:-$(pwd)}"
PROJECT_NAME=$(basename "$PROJECT_PATH")
CRG_DATA_DIR="${CRG_DATA_DIR:-${SCRIPT_DIR}/data/${PROJECT_NAME}}"
OUTPUT="${2:-${SCRIPT_DIR}/viz/${PROJECT_NAME}.html}"

if ! docker image inspect code-review-graph:local &>/dev/null; then
  echo "[crg] Image chưa có, building..." >&2
  docker build -t code-review-graph:local "${SCRIPT_DIR}"
fi

mkdir -p "$(dirname "$OUTPUT")"

echo "[crg] Generating visualization: $PROJECT_NAME"
echo "[crg] Data: $CRG_DATA_DIR"

docker run --rm \
  -v "${PROJECT_PATH}:/workspace:ro" \
  -v "${CRG_DATA_DIR}:/data" \
  -e CRG_DATA_DIR=/data \
  -e CRG_REPO_ROOT=/workspace \
  code-review-graph:local \
  code-review-graph visualize > "$OUTPUT"

echo "[crg] Saved: $OUTPUT"

# Mở browser
if command -v xdg-open &>/dev/null; then
  xdg-open "$OUTPUT"
elif command -v open &>/dev/null; then
  open "$OUTPUT"
else
  echo "[crg] Open manually: file://${OUTPUT}"
fi
