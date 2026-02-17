<!--
SPDX-FileCopyrightText: 2022 Zextras <https://www.zextras.com>

SPDX-License-Identifier: CC-BY-SA-4.0
-->

# Carbonio Docs Editor

A document editing service for the Carbonio suite, providing web-based office document editing powered by Collabora Online with service mesh integration.

## Overview

Carbonio Docs Editor is a packaging and configuration project that builds [Collabora Online](https://github.com/CollaboraOnline/online) with Zextras branding and integration patches, producing DEB and RPM packages for deployment within the Carbonio email and collaboration platform. It provides document editing functionality through a web interface and integrates with HashiCorp Consul for service discovery and management.

## Components

### Core Service

- **Main Service**: Runs on port 10000 using Collabora Online (coolwsd)
- **Sidecar Proxy**: Envoy-based proxy for service mesh integration
- **Service Discovery**: Consul-based service registration and routing

### Key Files

- `carbonio-docs-editor`: Setup script for service configuration
- `carbonio-docs-editor.service`: Systemd service for the main application
- `carbonio-docs-editor-sidecar.service`: Systemd service for the Envoy sidecar
- `carbonio-docs-routes-generator.py`: Python script for generating Consul routing configurations

## Features

- Document editing via web interface
- Service mesh integration with Consul Connect
- Automatic service discovery and routing
- Support for multiple service instances
- HTTP protocol support with specific path permissions

## Quick Start

```bash
# See all available commands
make help

# Build for Ubuntu 22.04 (Zextras devs with Artifactory access)
make build TARGET=ubuntu-jammy

# Build with locally built dependencies (community contributors)
make build TARGET=ubuntu-jammy \
  THIRDS_DIR=../carbonio-thirds/artifacts \
  CORE_DIR=../carbonio-docs-core/artifacts

# Clean build artifacts
make clean
```

### Prerequisites

- [yap](https://github.com/nicholasgasior/yap) >= 1.48
- Podman or Docker installed
- Make
- (Optional) Pre-built artifacts from [carbonio-thirds](https://github.com/zextras/carbonio-thirds) and [carbonio-docs-core](https://github.com/zextras/carbonio-docs-core)

### Build Dependencies

This project requires packages from two sibling projects at build time:

- **carbonio-thirds** — provides `carbonio-openssl` and `carbonio-poco`
- **carbonio-docs-core** — provides `carbonio-docs-core`

Zextras developers with Artifactory access can build without providing these locally. Community contributors should build both projects first, then pass their artifact directories via `THIRDS_DIR` and `CORE_DIR`.

### Supported Targets

- `ubuntu-jammy` - Ubuntu 22.04 LTS
- `ubuntu-noble` - Ubuntu 24.04 LTS
- `rocky-8` - Rocky Linux 8
- `rocky-9` - Rocky Linux 9

### Configuration

You can customize the build by setting environment variables:

```bash
# Use a specific container runtime
make build TARGET=ubuntu-jammy CONTAINER_RUNTIME=docker

# Specify dependency directories
make build TARGET=rocky-9 \
  THIRDS_DIR=../carbonio-thirds/artifacts \
  CORE_DIR=../carbonio-docs-core/artifacts
```

## Installation

These packages are distributed as part of the [Carbonio platform](https://zextras.com/carbonio). To install:

### Ubuntu (Jammy/Noble)

```bash
apt-get install <package-name>
```

### Rocky Linux (8/9)

```bash
yum install <package-name>
```

## Service Configuration

The service uses:

- **Port**: 10000 for the main service
- **Proxy Port**: 20000 for upstream connectivity
- **Protocol**: HTTP
- **Service ID**: Generated automatically per instance

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for information on how to contribute to this project.

## License

This project is licensed under the GNU Affero General Public License v3.0 - see the [LICENSE.md](LICENSE.md) file for details.
