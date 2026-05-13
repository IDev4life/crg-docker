# code-review-graph — Docker Setup cho Local Dev

Link repo gốc: https://github.com/tirth8205/code-review-graph

## Cấu trúc

```
crg-docker/
├── Dockerfile          # Image definition
├── docker-compose.yml  # Service definitions
├── crg-build.sh        # Full build graph (lần đầu hoặc rebuild hoàn toàn)
├── crg-update.sh       # Incremental update graph (chạy thủ công)
├── crg-watch.sh        # Auto-update graph khi file thay đổi (1 project, foreground)
├── crg-register.sh     # Đăng ký project vào daemon (multi-graph)
├── crg-viz.sh          # Export visualization ra HTML
├── crg-mcp.sh          # Wrapper cho Claude Code MCP
├── data/               # Graph data lưu local — mỗi project 1 subfolder (gitignored)
│   ├── my-app/
│   │   └── graph.db
│   └── other-api/
│       └── graph.db
└── README.md
```

---

## Bước 1 — Build image

```bash
cd crg-docker/
docker build -t code-review-graph:local .
```

---

## Setup đơn giản (1 project, không dùng daemon)

```bash
# Build graph
./crg-build.sh ~/dev/project/my-app

# Add MCP vào Claude Code
claude mcp add code-review-graph -- ~/dev/project/dev1sme/crg-docker/crg-mcp.sh ~/dev/project/my-app

# Update graph thủ công khi code thay đổi
./crg-update.sh ~/dev/project/my-app

# Hoặc auto-watch (foreground)
./crg-watch.sh ~/dev/project/my-app
```

---

## Setup multi-graph (nhiều project, dùng daemon)

Daemon tự động rebuild graph khi file thay đổi — không cần chạy thủ công.

### Yêu cầu

Tất cả projects phải nằm chung 1 thư mục cha (`PROJECTS_DIR`):

```
$HOME/projects/
├── my-app/
├── other-api/
└── data-service/
```

Set env var (nên thêm vào `.bashrc` / `.zshrc`):

```bash
export PROJECTS_DIR=$HOME/projects
```

### Đăng ký project

```bash
# Đăng ký my-app
./crg-register.sh ~/projects/my-app

# Đăng ký với alias tuỳ chỉnh
./crg-register.sh ~/projects/other-api my-api
```

Script tự động:
- Thêm project vào `watch.toml` của daemon
- Register data dir: `./data/<alias>/graph.db`

### Build graph lần đầu

```bash
./crg-build.sh ~/projects/my-app
./crg-build.sh ~/projects/other-api
```

### Start daemon

```bash
docker compose up -d crg-daemon
```

Daemon chạy ngầm, tự detect file thay đổi và rebuild graph.

### Add MCP vào Claude Code

Mỗi project cần 1 MCP instance riêng:

```bash
claude mcp add code-review-graph -- ~/dev/project/dev1sme/crg-docker/crg-mcp.sh ~/projects/my-app
```

Để dùng nhiều project trong cùng session Claude Code, thêm nhiều MCP với tên khác nhau:

```bash
claude mcp add crg-my-app   -- ~/dev/project/dev1sme/crg-docker/crg-mcp.sh ~/projects/my-app
claude mcp add crg-other-api -- ~/dev/project/dev1sme/crg-docker/crg-mcp.sh ~/projects/other-api
```

---

## Update graph thủ công

```bash
# Incremental update (nhanh, chỉ parse file thay đổi)
./crg-update.sh ~/projects/my-app

# Full rebuild
./crg-build.sh ~/projects/my-app
```

---

## Xem visualization (Web UI)

```bash
./crg-viz.sh ~/projects/my-app

# Chỉ định output file
./crg-viz.sh ~/projects/my-app ~/Desktop/my-app-graph.html
```

File HTML lưu vào `crg-docker/viz/<project-name>.html`.

---

## Xem status graph

```bash
docker run --rm \
  -v ~/projects/my-app:/workspace:ro \
  -v "$(pwd)/data/my-app:/data" \
  -e CRG_DATA_DIR=/data \
  -e CRG_REPO_ROOT=/workspace \
  code-review-graph:local \
  code-review-graph status
```

---

## Migration từ setup cũ (1 graph.db flat)

Nếu đang có `data/graph.db` từ setup cũ:

```bash
# Tạo subfolder, move db vào đúng chỗ
mkdir -p data/my-app
mv data/graph.db data/my-app/graph.db
```

---

## Lưu ý

- Data lưu tại `crg-docker/data/<project>/` — không xóa trừ khi muốn rebuild từ đầu.
- Workspace mount `:ro` — container không thể sửa source code.
- Project dùng git: chỉ index tracked files, gitignored files tự động bỏ qua.
- Daemon và MCP share cùng `graph.db` — SQLite WAL mode handle concurrent read/write an toàn.
- Daemon dùng volume `crg-daemon-config` (tên cố định) để lưu registry và watch.toml.