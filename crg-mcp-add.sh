#!/bin/bash
# crg-mcp-add.sh — thêm code-review-graph vào .mcp.json của target project (merge, giữ MCP khác)
#
# Usage: ./crg-mcp-add.sh /path/to/project

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

PROJECT_PATH="${1:-$(pwd)}"
PROJECT_PATH=$(realpath "$PROJECT_PATH")
MCP_FILE="${PROJECT_PATH}/.mcp.json"

python3 - <<PYEOF
import json
from pathlib import Path

mcp_file = Path("${MCP_FILE}")
data = json.loads(mcp_file.read_text()) if mcp_file.exists() else {}
data.setdefault("mcpServers", {})

data["mcpServers"]["code-review-graph"] = {
    "command": "${SCRIPT_DIR}/crg-mcp.sh",
    "args": ["${PROJECT_PATH}"]
}

mcp_file.write_text(json.dumps(data, indent=2) + "\n")
verb = "updated" if mcp_file.exists() else "created"
print(f"[crg] .mcp.json {verb}: ${MCP_FILE}")
PYEOF

echo "[crg] NOTE: path is machine-specific — add .mcp.json to .gitignore if not already"
