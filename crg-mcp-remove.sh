#!/bin/bash
# crg-mcp-remove.sh — xóa code-review-graph khỏi .mcp.json của target project
#                     giữ nguyên các MCP khác; xóa file nếu không còn entry nào
#
# Usage: ./crg-mcp-remove.sh /path/to/project

set -euo pipefail

PROJECT_PATH="${1:-$(pwd)}"
PROJECT_PATH=$(realpath "$PROJECT_PATH")
MCP_FILE="${PROJECT_PATH}/.mcp.json"

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
    print("[crg] .mcp.json deleted (no MCP servers left)")
else:
    data["mcpServers"] = servers
    mcp_file.write_text(json.dumps(data, indent=2) + "\n")
    print("[crg] code-review-graph removed (other servers preserved)")
PYEOF
