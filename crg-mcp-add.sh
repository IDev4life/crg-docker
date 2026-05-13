#!/bin/bash
# crg-mcp-add.sh — ghi .mcp.json vào target project để enable code-review-graph MCP
#
# Usage:
#   ./crg-mcp-add.sh /path/to/project          # add
#   ./crg-mcp-add.sh /path/to/project remove   # remove

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

PROJECT_PATH="${1:-$(pwd)}"
PROJECT_PATH=$(realpath "$PROJECT_PATH")
ACTION="${2:-add}"
MCP_FILE="${PROJECT_PATH}/.mcp.json"

if [[ "$ACTION" == "remove" ]]; then
  if [[ -f "$MCP_FILE" ]]; then
    rm -f "$MCP_FILE"
    echo "[crg] .mcp.json removed: $MCP_FILE"
  else
    echo "[crg] Not found: $MCP_FILE"
  fi
  exit 0
fi

printf '{\n  "mcpServers": {\n    "code-review-graph": {\n      "command": "%s",\n      "args": ["%s"]\n    }\n  }\n}\n' \
  "${SCRIPT_DIR}/crg-mcp.sh" "${PROJECT_PATH}" > "$MCP_FILE"

echo "[crg] .mcp.json written: $MCP_FILE"
echo "[crg] NOTE: path is machine-specific — add .mcp.json to .gitignore if not already"
