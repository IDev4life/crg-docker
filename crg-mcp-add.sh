#!/bin/bash
# crg-mcp-add.sh — add/remove code-review-graph entry trong .mcp.json của target project
#
# Usage:
#   ./crg-mcp-add.sh /path/to/project          # add (merge, không xóa MCP khác)
#   ./crg-mcp-add.sh /path/to/project remove   # remove chỉ entry code-review-graph

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

PROJECT_PATH="${1:-$(pwd)}"
PROJECT_PATH=$(realpath "$PROJECT_PATH")
ACTION="${2:-add}"
MCP_FILE="${PROJECT_PATH}/.mcp.json"

if [[ "$ACTION" == "remove" ]]; then
  if [[ ! -f "$MCP_FILE" ]]; then
    echo "[crg] Not found: $MCP_FILE"
    exit 0
  fi
  python3 - <<PYEOF
import json, sys
from pathlib import Path

mcp_file = Path("${MCP_FILE}")
data = json.loads(mcp_file.read_text())
servers = data.get("mcpServers", {})

if "code-review-graph" not in servers:
    print("[crg] code-review-graph not in .mcp.json — nothing to remove")
    sys.exit(0)

del servers["code-review-graph"]

if not servers:
    mcp_file.unlink()
    print("[crg] .mcp.json removed (no MCP servers left): ${MCP_FILE}")
else:
    data["mcpServers"] = servers
    mcp_file.write_text(json.dumps(data, indent=2) + "\n")
    print("[crg] code-review-graph removed from .mcp.json (other servers preserved)")
PYEOF
  exit 0
fi

# add — merge vào .mcp.json hiện có
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
action = "updated" if mcp_file.exists() else "created"
print(f"[crg] .mcp.json {action}: ${MCP_FILE}")
PYEOF

echo "[crg] NOTE: path is machine-specific — add .mcp.json to .gitignore if not already"
