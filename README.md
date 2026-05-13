# code-review-graph — Docker Setup cho Local Dev

Link repo gốc: https://github.com/tirth8205/code-review-graph

## Cấu trúc

```
crg-docker/
├── Dockerfile          # Image definition
├── docker-compose.yml  # Service definitions (crg + crg-daemon)
├── Makefile            # CLI gọn: make build, make update, ...
├── crg-mcp.sh          # Wrapper cho Claude Code MCP (stdio)
├── crg-register.sh     # Đăng ký project vào daemon (multi-graph)
├── crg-build.sh        # Full build graph
├── crg-update.sh       # Incremental update graph
├── crg-watch.sh        # Auto-update graph khi file thay đổi
├── crg-viz.sh          # Export visualization ra HTML
├── data/               # Tất cả state (gitignored)
│   ├── .registry/
│   │   ├── registry.json   # danh sách repos đã register
│   │   └── watch.toml      # config daemon
│   ├── my-app/
│   │   └── graph.db
│   └── other-api/
│       └── graph.db
├── viz/                # HTML visualization output
└── README.md
```

---

## Quick Reference

```bash
make help               # Xem tất cả commands
make image              # Build Docker image
make build   PROJECT=~/dev/my-app    # Full build graph
make update  PROJECT=~/dev/my-app   # Incremental update
make watch   PROJECT=~/dev/my-app   # Auto-update (foreground)
make viz     PROJECT=~/dev/my-app   # Export visualization
make status  PROJECT=~/dev/my-app   # Xem graph status
make list                           # Liệt kê projects đã build
make clean   PROJECT=~/dev/my-app   # Xóa graph data
```

---

## Bước 1 — Build image

```bash
make image
```

---

## Setup đơn giản (1 project, không dùng daemon)

```bash
# Build graph
make build PROJECT=~/dev/my-app

# Add MCP vào Claude Code
claude mcp add code-review-graph -- /path/to/crg-docker/crg-mcp.sh ~/dev/my-app

# Update graph khi code thay đổi
make update PROJECT=~/dev/my-app

# Hoặc auto-watch (foreground)
make watch PROJECT=~/dev/my-app
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
# Đăng ký my-app (alias = tên folder)
make register PROJECT=~/projects/my-app

# Đăng ký với alias tuỳ chỉnh
make register PROJECT=~/projects/other-api ALIAS=my-api
```

Script tự động:

- Thêm project vào `watch.toml` của daemon
- Register data dir: `./data/<alias>/graph.db`

### Build graph lần đầu

```bash
make build PROJECT=~/projects/my-app
make build PROJECT=~/projects/other-api
```

### Start daemon

```bash
make daemon-up
```

Daemon chạy ngầm, tự detect file thay đổi và rebuild graph.

### Xem daemon logs

```bash
make daemon-logs
```

### Add MCP vào Claude Code

Mỗi project cần 1 MCP instance riêng:

```bash
claude mcp add code-review-graph -- /path/to/crg-docker/crg-mcp.sh ~/projects/my-app
```

Dùng nhiều project trong cùng session Claude Code — thêm MCP với tên khác nhau:

```bash
claude mcp add crg-my-app    -- /path/to/crg-docker/crg-mcp.sh ~/projects/my-app
claude mcp add crg-other-api -- /path/to/crg-docker/crg-mcp.sh ~/projects/other-api
```

---

## Quản lý graph

```bash
# Xem projects đã build
make list

# Xem status 1 project
make status PROJECT=~/projects/my-app

# Incremental update (nhanh)
make update PROJECT=~/projects/my-app

# Full rebuild
make build PROJECT=~/projects/my-app

# Xóa graph data
make clean PROJECT=~/projects/my-app
```

---

## Visualization

```bash
make viz PROJECT=~/projects/my-app
```

File HTML lưu vào `crg-docker/viz/<project-name>.html`, tự mở browser.

---

## Migration từ setup cũ (1 graph.db flat)

Nếu đang có `data/graph.db` từ setup cũ:

```bash
mkdir -p data/my-app
mv data/graph.db data/my-app/graph.db
```

---

## Lưu ý

- Data lưu tại `crg-docker/data/<project>/` — không xóa trừ khi muốn rebuild từ đầu.
- Workspace mount `:ro` — container không thể sửa source code.
- Project dùng git: chỉ index tracked files, gitignored files tự động bỏ qua.
- Daemon và MCP share cùng `graph.db` — SQLite WAL mode handle concurrent read/write an toàn.
- Registry và watch.toml lưu tại `./data/.registry/` — visible trên host, backup/reset cùng `./data/`.
