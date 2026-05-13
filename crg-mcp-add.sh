#!/bin/bash
# crg-mcp-add.sh — thêm code-review-graph vào .mcp.json của target project (merge, giữ MCP khác)
#
# Usage:
#   ./crg-mcp-add.sh /path/to/project                    # graph của chính project đó
#   ./crg-mcp-add.sh /path/to/project /path/to/other-repo # graph repo khác (cross-reference)

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

PROJECT_PATH="${1:-$(pwd)}"
PROJECT_PATH=$(realpath "$PROJECT_PATH")
GRAPH_PATH="${2:-$PROJECT_PATH}"
GRAPH_PATH=$(realpath "$GRAPH_PATH")
GRAPH_NAME=$(basename "$GRAPH_PATH")
MCP_KEY="crg-${GRAPH_NAME}"
MCP_FILE="${PROJECT_PATH}/.mcp.json"

python3 - <<PYEOF
import json
from pathlib import Path

mcp_file = Path("${MCP_FILE}")
data = json.loads(mcp_file.read_text()) if mcp_file.exists() else {}
data.setdefault("mcpServers", {})

data["mcpServers"]["${MCP_KEY}"] = {
    "command": "${SCRIPT_DIR}/crg-mcp.sh",
    "args": ["${GRAPH_PATH}"]
}

mcp_file.write_text(json.dumps(data, indent=2) + "\n")
print(f"[crg] .mcp.json updated: ${MCP_FILE}")
print(f"[crg] MCP server: ${MCP_KEY} → ${GRAPH_PATH}")
PYEOF

echo "[crg] NOTE: path is machine-specific — add .mcp.json to .gitignore if not already"
