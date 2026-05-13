FROM python:3.12-slim

# Cài system deps cần thiết cho Tree-sitter
RUN apt-get update && apt-get install -y \
    git \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Cài code-review-graph với tất cả optional deps
RUN pip install --no-cache-dir \
    "code-review-graph[embeddings,communities]"

# Thư mục chứa project được mount vào
WORKDIR /workspace

# Thư mục lưu graph data (persistent volume)
ENV CRG_DATA_DIR=/data
ENV CRG_REPO_ROOT=/workspace

# Tạo thư mục data
RUN mkdir -p /data

CMD ["code-review-graph", "serve"]