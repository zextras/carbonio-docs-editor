# SPDX-FileCopyrightText: 2022 Zextras <https://www.zextras.com>
#
# SPDX-License-Identifier: AGPL-3.0-only

# Makefile for building carbonio-docs-editor packages using YAP

# Configuration
YAP_IMAGE_PREFIX ?= docker.io/m0rf30/yap
YAP_VERSION ?= 1.47
CONTAINER_RUNTIME ?= $(shell command -v podman >/dev/null 2>&1 && echo podman || echo docker)

# Build options
TARGET ?= ubuntu-jammy
THIRDS_DIR ?= none
CORE_DIR ?= none

# Computed values
YAP_IMAGE = $(YAP_IMAGE_PREFIX)-$(TARGET):$(YAP_VERSION)
CCACHE_DIR ?= $(CURDIR)/.ccache

# Container mount options
CONTAINER_OPTS = --rm -ti \
	-v $(CURDIR):/project \
	-v $(CURDIR)/artifacts:/artifacts \
	-v $(CCACHE_DIR):/root/.ccache \
	-e CCACHE_DIR=/root/.ccache \
	--entrypoint bash

# Add carbonio-thirds volume if provided
ifneq ($(THIRDS_DIR),none)
THIRDS_MOUNT = -v $(realpath $(THIRDS_DIR)):/thirds:ro
THIRDS_ARG = /thirds
else
THIRDS_MOUNT =
THIRDS_ARG = none
endif

# Add carbonio-docs-core volume if provided
ifneq ($(CORE_DIR),none)
CORE_MOUNT = -v $(realpath $(CORE_DIR)):/core:ro
CORE_ARG = /core
else
CORE_MOUNT =
CORE_ARG = none
endif

.PHONY: help build clean

.DEFAULT_GOAL := help

## help: Show this help message
help:
	@echo "Carbonio Docs Editor - Build System"
	@echo ""
	@echo "Usage:"
	@echo "  make <target> [TARGET=<distro>] [THIRDS_DIR=<path>] [CORE_DIR=<path>]"
	@echo ""
	@echo "Targets:"
	@echo "  help           Show this help message"
	@echo "  build          Build the carbonio-docs-editor package"
	@echo "  clean          Remove build artifacts"
	@echo ""
	@echo "Options:"
	@echo "  TARGET         Distribution target (default: ubuntu-jammy)"
	@echo "                 Supported: ubuntu-jammy, ubuntu-noble, rocky-8, rocky-9"
	@echo "  THIRDS_DIR     Directory containing carbonio-thirds packages (optional)"
	@echo "                 Example: ../carbonio-thirds/artifacts"
	@echo "  CORE_DIR       Directory containing carbonio-docs-core packages (optional)"
	@echo "                 Example: ../carbonio-docs-core/artifacts"
	@echo ""
	@echo "Examples:"
	@echo "  # Build without local dependencies (Zextras devs with Artifactory access)"
	@echo "  make build TARGET=ubuntu-jammy"
	@echo ""
	@echo "  # Build with local dependencies (community contributors)"
	@echo "  make build TARGET=ubuntu-jammy THIRDS_DIR=../carbonio-thirds/artifacts CORE_DIR=../carbonio-docs-core/artifacts"
	@echo ""

## build: Build the carbonio-docs-editor package
build:
	@mkdir -p artifacts $(CCACHE_DIR)
	$(CONTAINER_RUNTIME) run $(CONTAINER_OPTS) $(THIRDS_MOUNT) $(CORE_MOUNT) $(YAP_IMAGE) \
		/project/build-in-container.sh $(THIRDS_ARG) $(CORE_ARG) $(TARGET)

## clean: Remove build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf artifacts .ccache
	@echo "Clean complete!"
