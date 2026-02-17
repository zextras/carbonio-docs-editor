# SPDX-FileCopyrightText: 2022 Zextras <https://www.zextras.com>
#
# SPDX-License-Identifier: AGPL-3.0-only

# Makefile for building carbonio-docs-editor packages using YAP

# Configuration
YAP_IMAGE_PREFIX ?= docker.io/m0rf30/yap
YAP_VERSION ?= 1.48
CONTAINER_RUNTIME ?= $(shell command -v podman >/dev/null 2>&1 && echo podman || echo docker)

# Build options
TARGET ?= ubuntu-jammy
THIRDS_DIR ?= none
CORE_DIR ?= none

# Computed values
YAP_IMAGE = $(YAP_IMAGE_PREFIX)-$(TARGET):$(YAP_VERSION)
CCACHE_DIR ?= $(CURDIR)/.ccache

# SSH key for private git sources (yap uses ~/.ssh/id_rsa)
SSH_KEY_FILE ?= $(CURDIR)/ssh.secret
SSH_KNOWN_HOSTS ?= $(CURDIR)/.ssh_known_hosts
ifneq ($(wildcard $(SSH_KEY_FILE)),)
SSH_MOUNT = -v $(SSH_KEY_FILE):/root/.ssh/id_rsa:ro \
	-v $(SSH_KNOWN_HOSTS):/root/.ssh/known_hosts:ro
else
SSH_MOUNT =
endif

# Container mount options
CONTAINER_OPTS = --rm -ti \
	-v $(CURDIR):/project \
	-v $(CURDIR)/artifacts:/artifacts \
	-v $(CCACHE_DIR):/root/.ccache \
	-e CCACHE_DIR=/root/.ccache \
	$(SSH_MOUNT) \
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

.PHONY: help build debug-build clean ssh-known-hosts

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
	@echo "  debug-build    Start interactive shell in build container"
	@echo "  clean          Remove build artifacts"
	@echo ""
	@echo "Options:"
	@echo "  TARGET         Distribution target (default: ubuntu-jammy)"
	@echo "                 Supported: ubuntu-jammy, ubuntu-noble, rocky-8, rocky-9"
	@echo "  THIRDS_DIR     Directory containing carbonio-thirds packages (optional)"
	@echo "                 Example: ../carbonio-thirds/artifacts"
	@echo "  CORE_DIR       Directory containing carbonio-docs-core packages (optional)"
	@echo "                 Example: ../carbonio-docs-core/artifacts"
	@echo "  SSH_KEY_FILE   Path to SSH private key for private git sources (default: ./ssh.secret)"
	@echo "                 Mounted as /root/.ssh/id_rsa inside the container."
	@echo "                 Required when PKGBUILD sources reference private repositories."
	@echo ""
	@echo "Examples:"
	@echo "  # Build without local dependencies (Zextras devs with Artifactory access)"
	@echo "  make build TARGET=ubuntu-jammy"
	@echo ""
	@echo "  # Build with local dependencies (community contributors)"
	@echo "  make build TARGET=ubuntu-jammy THIRDS_DIR=../carbonio-thirds/artifacts CORE_DIR=../carbonio-docs-core/artifacts"
	@echo ""
	@echo "  # Build with SSH key for private git sources"
	@echo "  make build TARGET=ubuntu-jammy SSH_KEY_FILE=~/.ssh/my_deploy_key"
	@echo ""

## ssh-known-hosts: Generate SSH known_hosts for github.com (used when ssh.secret is present)
$(SSH_KNOWN_HOSTS):
	@echo "==> Generating SSH known_hosts for github.com"
	ssh-keyscan -t ed25519,ecdsa,rsa github.com > $(SSH_KNOWN_HOSTS) 2>/dev/null

## build: Build the carbonio-docs-editor package
build: $(if $(wildcard $(SSH_KEY_FILE)),$(SSH_KNOWN_HOSTS))
	@mkdir -p artifacts $(CCACHE_DIR)
	$(CONTAINER_RUNTIME) run $(CONTAINER_OPTS) $(THIRDS_MOUNT) $(CORE_MOUNT) $(YAP_IMAGE) \
		/project/build-in-container.sh $(THIRDS_ARG) $(CORE_ARG) $(TARGET) 2>&1 | tee build.log

## debug-build: Start interactive shell in build container for manual debugging
debug-build: $(if $(wildcard $(SSH_KEY_FILE)),$(SSH_KNOWN_HOSTS))
	@mkdir -p artifacts $(CCACHE_DIR)
	@echo "Starting interactive shell in build container..."
	@echo "Container info:"
	@echo "  Image: $(YAP_IMAGE)"
	@echo "  Target: $(TARGET)"
	@echo "  Thirds: $(THIRDS_ARG)"
	@echo "  Core: $(CORE_ARG)"
	@echo ""
	@echo "To run the build manually, execute:"
	@echo "  /project/build-in-container.sh $(THIRDS_ARG) $(CORE_ARG) $(TARGET)"
	@echo ""
	$(CONTAINER_RUNTIME) run $(CONTAINER_OPTS) $(THIRDS_MOUNT) $(CORE_MOUNT) $(YAP_IMAGE)

## clean: Remove build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf artifacts .ccache .ssh_known_hosts
	@echo "Clean complete!"
