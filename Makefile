# code-review-graph — Docker wrapper
#
# Usage:
#   make build PROJECT=~/dev/my-app
#   make update PROJECT=~/dev/my-app
#   make watch PROJECT=~/dev/my-app
#   make viz PROJECT=~/dev/my-app
#   make register PROJECT=~/dev/my-app ALIAS=my-app
#   make status PROJECT=~/dev/my-app
#   make daemon-up
#   make daemon-down
#   make clean PROJECT=~/dev/my-app
#
# crg-mcp.sh vẫn dùng trực tiếp (stdio wrapper cho Claude Code):
#   claude mcp add code-review-graph -- ./crg-mcp.sh ~/dev/my-app

SHELL := /bin/bash
.DEFAULT_GOAL := help

IMAGE := code-review-graph:local
SCRIPT_DIR := $(shell cd "$(dir $(abspath $(lastword $(MAKEFILE_LIST))))" && pwd)
DATA_DIR := $(SCRIPT_DIR)/data
VIZ_DIR := $(SCRIPT_DIR)/viz

ifdef PROJECT
  PROJECT_PATH := $(shell realpath $(PROJECT))
  PROJECT_NAME := $(shell basename $(PROJECT_PATH))
  PROJECT_DATA := $(DATA_DIR)/$(PROJECT_NAME)
else
  PROJECT_PATH :=
  PROJECT_NAME :=
  PROJECT_DATA :=
endif

ALIAS ?= $(PROJECT_NAME)
PROJECTS_DIR ?= $(HOME)/projects

# Docker run base command
DOCKER_RUN := docker run --rm \
  -v "$(PROJECT_PATH):/workspace:ro" \
  -v "$(PROJECT_DATA):/data" \
  -e CRG_DATA_DIR=/data \
  -e CRG_REPO_ROOT=/workspace \
  $(IMAGE)

# ── Guards ──────────────────────────────────────────────

.PHONY: _require-project _require-image

_require-project:
ifndef PROJECT
	$(error PROJECT required. Usage: make $(MAKECMDGOALS) PROJECT=/path/to/project)
endif

_require-image:
	@if ! docker image inspect $(IMAGE) &>/dev/null; then \
		echo "[crg] Building image..."; \
		docker build -t $(IMAGE) $(SCRIPT_DIR); \
	fi

# ── Targets ─────────────────────────────────────────────

.PHONY: image build update watch viz status register daemon-up daemon-down daemon-logs clean list help

image: ## Build Docker image
	docker build -t $(IMAGE) $(SCRIPT_DIR)

build: _require-project _require-image ## Full build graph
	@mkdir -p "$(PROJECT_DATA)"
	@echo "[crg] Building graph: $(PROJECT_NAME)"
	@echo "[crg] Path: $(PROJECT_PATH)"
	@echo "[crg] Data: $(PROJECT_DATA)"
	$(DOCKER_RUN) code-review-graph build
	@echo "[crg] Done! Graph saved: $(PROJECT_DATA)"

update: _require-project _require-image ## Incremental update graph
	@mkdir -p "$(PROJECT_DATA)"
	@echo "[crg] Updating graph: $(PROJECT_NAME)"
	$(DOCKER_RUN) code-review-graph update
	@echo "[crg] Done!"

watch: _require-project _require-image ## Auto-update graph on file changes (foreground)
	@mkdir -p "$(PROJECT_DATA)"
	@echo "[crg] Watching: $(PROJECT_NAME)"
	@echo "[crg] Ctrl+C to stop"
	docker run --rm -it \
		--name "crg-watch-$(PROJECT_NAME)-$$$$" \
		-v "$(PROJECT_PATH):/workspace:ro" \
		-v "$(PROJECT_DATA):/data" \
		-e CRG_DATA_DIR=/data \
		-e CRG_REPO_ROOT=/workspace \
		$(IMAGE) code-review-graph watch

viz: _require-project _require-image ## Export graph visualization to HTML
	@mkdir -p "$(VIZ_DIR)"
	@echo "[crg] Generating visualization: $(PROJECT_NAME)"
	$(DOCKER_RUN) code-review-graph visualize > "$(VIZ_DIR)/$(PROJECT_NAME).html"
	@echo "[crg] Saved: $(VIZ_DIR)/$(PROJECT_NAME).html"
	@if command -v xdg-open &>/dev/null; then \
		xdg-open "$(VIZ_DIR)/$(PROJECT_NAME).html"; \
	elif command -v open &>/dev/null; then \
		open "$(VIZ_DIR)/$(PROJECT_NAME).html"; \
	else \
		echo "[crg] Open: file://$(VIZ_DIR)/$(PROJECT_NAME).html"; \
	fi

status: _require-project _require-image ## Show graph status
	$(DOCKER_RUN) code-review-graph status

register: _require-project _require-image ## Register project into daemon
	@PROJECT_PATH="$(PROJECT_PATH)" \
	 ALIAS="$(ALIAS)" \
	 PROJECTS_DIR="$(PROJECTS_DIR)" \
	 SCRIPT_DIR="$(SCRIPT_DIR)" \
	 $(SCRIPT_DIR)/crg-register.sh "$(PROJECT_PATH)" "$(ALIAS)"

daemon-up: _require-image ## Start daemon (auto-rebuild on file changes)
	docker compose up -d crg-daemon

daemon-down: ## Stop daemon
	docker compose down crg-daemon

daemon-logs: ## Show daemon logs
	docker compose logs -f crg-daemon

clean: _require-project ## Remove graph data for a project
	@if [ -d "$(PROJECT_DATA)" ]; then \
		echo "[crg] Removing: $(PROJECT_DATA)"; \
		rm -rf "$(PROJECT_DATA)"; \
		echo "[crg] Done!"; \
	else \
		echo "[crg] No data found: $(PROJECT_DATA)"; \
	fi

list: ## List all projects with graph data
	@echo "[crg] Projects with graph data:"
	@if [ -d "$(DATA_DIR)" ]; then \
		for d in $(DATA_DIR)/*/; do \
			if [ -f "$$d/graph.db" ]; then \
				name=$$(basename "$$d"); \
				size=$$(du -sh "$$d/graph.db" | cut -f1); \
				echo "  $$name ($$size)"; \
			fi; \
		done; \
	else \
		echo "  (none)"; \
	fi

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
