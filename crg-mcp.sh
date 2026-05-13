#!/bin/bash
# crg-mcp.sh — wrapper script để Claude Code dùng code-review-graph qua Docker
#
# Dùng trực tiếp: claude mcp add code-review-graph -- /path/to/crg-docker/crg-mcp.sh /path/to/project
# Hoặc copy sang ~/bin/crg-mcp, khi đó phải set CRG_DOCKER_DIR:
#   CRG_DOCKER_DIR=/home/thomson/dev/project/dev1sme/crg-docker
#   claude mcp add code-review-graph -- ~/bin/crg-mcp /path/to/project

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Nếu copy sang ~/bin/, set CRG_DOCKER_DIR trỏ về thư mục chứa Dockerfile
CRG_DOCKER_DIR="${CRG_DOCKER_DIR:-${SCRIPT_DIR}}"

PROJECT_PATH="${1:-$(pwd)}"
PROJECT_NAME=$(basename "$PROJECT_PATH")

CRG_DATA_DIR="${CRG_DATA_DIR:-${CRG_DOCKER_DIR}/data/${PROJECT_NAME}}"
mkdir -p "$CRG_DATA_DIR"

# Build image nếu chưa có
if ! docker image inspect code-review-graph:local &>/dev/null; then
  echo "[crg-mcp] Building code-review-graph image..." >&2
  docker build -t code-review-graph:local "${CRG_DOCKER_DIR}"
fi

# Chạy MCP server qua stdio
exec docker run --rm -i \
  --name "crg-${PROJECT_NAME}-$$" \
  -v "${PROJECT_PATH}:/workspace:ro" \
  -v "${CRG_DATA_DIR}:/data" \
  -e CRG_DATA_DIR=/data \
  -e CRG_REPO_ROOT=/workspace \
  code-review-graph:local \
  code-review-graph serve