#!/bin/bash
# crg-mcp-remove.sh — xóa code-review-graph khỏi .mcp.json của target project
#                     giữ nguyên các MCP khác; xóa file nếu không còn entry nào
#
# Usage:
#   ./crg-mcp-remove.sh /path/to/project                    # xóa graph chính project
#   ./crg-mcp-remove.sh /path/to/project /path/to/other-repo # xóa graph repo khác
#   ./crg-mcp-remove.sh /path/to/project --all               # xóa tất cả crg-* entries

set -euo pipefail

PROJECT_PATH="${1:-$(pwd)}"
PROJECT_PATH=$(realpath "$PROJECT_PATH")
REMOVE_ARG="${2:-$PROJECT_PATH}"
MCP_FILE="${PROJECT_PATH}/.mcp.json"

if [[ ! -f "$MCP_FILE" ]]; then
  echo "[crg] Not found: $MCP_FILE"
  exit 0
fi

if [[ "$REMOVE_ARG" == "--all" ]]; then
  MCP_KEY="--all"
else
  GRAPH_PATH=$(realpath "$REMOVE_ARG")
  GRAPH_NAME=$(basename "$GRAPH_PATH")
  MCP_KEY="crg-${GRAPH_NAME}"
fi

python3 - <<PYEOF
import json, sys
from pathlib import Path

mcp_file = Path("${MCP_FILE}")
data = json.loads(mcp_file.read_text())
servers = data.get("mcpServers", {})
mcp_key = "${MCP_KEY}"

if mcp_key == "--all":
    removed = [k for k in servers if k.startswith("crg-")]
    if not removed:
        print("[crg] No crg-* entries in .mcp.json — nothing to remove")
        sys.exit(0)
    for k in removed:
        del servers[k]
    print(f"[crg] Removed {len(removed)} entries: {', '.join(removed)}")
else:
    if mcp_key not in servers:
        print(f"[crg] {mcp_key} not in .mcp.json — nothing to remove")
        sys.exit(0)
    del servers[mcp_key]
    print(f"[crg] {mcp_key} removed")

if not servers:
    mcp_file.unlink()
    print("[crg] .mcp.json deleted (no MCP servers left)")
else:
    data["mcpServers"] = servers
    mcp_file.write_text(json.dumps(data, indent=2) + "\n")
    print("[crg] Other servers preserved")
PYEOF
