#!/bin/bash
# crg-register.sh — đăng ký project vào daemon (Option 1 + 2 combined)
#
# Usage:
#   ./crg-register.sh /path/to/project [alias]
#   PROJECTS_DIR=/path/to/projects ./crg-register.sh /path/to/project
#
# Sau khi register:
#   - crg-daemon tự watch project này (auto-rebuild khi file thay đổi)
#   - crg-mcp.sh đọc graph từ ./data/<alias>/graph.db
#
# PROJECTS_DIR phải là parent chứa project, và phải khớp với mount trong docker-compose.yml
# Default: $HOME/projects

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECTS_DIR="${PROJECTS_DIR:-$HOME/projects}"

PROJECT_PATH="${1:-$(pwd)}"
PROJECT_PATH=$(realpath "$PROJECT_PATH")
ALIAS="${2:-$(basename "$PROJECT_PATH")}"

# Validate project nằm trong PROJECTS_DIR
if [[ "$PROJECT_PATH" != "${PROJECTS_DIR%/}"* ]]; then
  echo "[crg] ERROR: Project phải nằm trong PROJECTS_DIR."
  echo "[crg]   Project     : $PROJECT_PATH"
  echo "[crg]   PROJECTS_DIR: $PROJECTS_DIR"
  echo ""
  echo "[crg] Fix: export PROJECTS_DIR=$(dirname "$PROJECT_PATH")"
  echo "       sau đó chạy lại script này."
  exit 1
fi

# Tính container path
REL_PATH="${PROJECT_PATH#${PROJECTS_DIR%/}/}"
CONTAINER_PATH="/workspace/${REL_PATH}"

echo "[crg] Registering project..."
echo "[crg]   Alias       : $ALIAS"
echo "[crg]   Host path   : $PROJECT_PATH"
echo "[crg]   Container   : $CONTAINER_PATH"
echo "[crg]   Data dir    : ${SCRIPT_DIR}/data/${ALIAS}/"
echo ""

# Build image nếu chưa có
if ! docker image inspect code-review-graph:local &>/dev/null; then
  echo "[crg] Building image..." >&2
  docker build -t code-review-graph:local "${SCRIPT_DIR}"
fi

# Tạo data dir trên host
mkdir -p "${SCRIPT_DIR}/data/${ALIAS}"

# Register vào crg-daemon-config volume (registry + watch.toml)
docker run --rm \
  -v "crg-daemon-config:/root/.code-review-graph" \
  -v "${SCRIPT_DIR}/data:/data" \
  code-review-graph:local \
  python3 -c "
from pathlib import Path
from code_review_graph.registry import Registry

# Register vào registry với data_dir per-project
r = Registry(Path('/root/.code-review-graph/registry.json'))
entry = r.register('${CONTAINER_PATH}', alias='${ALIAS}', data_dir='/data/${ALIAS}')
print(f'[crg] Registry: {entry}')

# Add vào watch.toml để daemon tự watch
toml_path = Path('/root/.code-review-graph/watch.toml')
content = toml_path.read_text() if toml_path.exists() else ''
if '${CONTAINER_PATH}' in content:
    print('[crg] watch.toml: ${ALIAS} already registered')
else:
    new_entry = '\n[[repos]]\npath = \"${CONTAINER_PATH}\"\nalias = \"${ALIAS}\"\n'
    toml_path.parent.mkdir(parents=True, exist_ok=True)
    toml_path.write_text(content + new_entry)
    print('[crg] watch.toml: added ${ALIAS}')
"

echo ""
echo "[crg] Done! Next steps:"
echo ""
echo "  # 1. Build graph lần đầu"
echo "  ./crg-build.sh ${PROJECT_PATH}"
echo ""
echo "  # 2. Start daemon (auto-rebuild khi file thay đổi)"
echo "  docker compose up -d crg-daemon"
echo ""
echo "  # 3. Add MCP vào Claude Code (nếu chưa)"
echo "  claude mcp add code-review-graph -- ${SCRIPT_DIR}/crg-mcp.sh ${PROJECT_PATH}"
