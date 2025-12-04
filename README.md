# Carbonio Docs Editor

A Carbonio service for document editing capabilities with service discovery and proxy integration.

## Overview

Carbonio Docs Editor is a document editing service that runs as part of the Carbonio suite. It provides document editing functionality through a web interface and integrates with HashiCorp Consul for service discovery and management.

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

## Installation

1. Run the setup script as root:
```bash
sudo carbonio-docs-editor setup
```

This will:
- Configure Consul service discovery
- Generate routing configurations
- Set up ACL policies and tokens
- Start the services

## Service Configuration

The service uses:
- **Port**: 10000 for the main service
- **Proxy Port**: 20000 for upstream connectivity
- **Protocol**: HTTP
- **Service ID**: Generated automatically per instance

## Development

### Build System
- Uses Jenkins for CI/CD
- Supports multiple Linux distributions (Ubuntu, Rocky Linux)
- Builds both DEB and RPM packages
- Node.js dependency management

### Configuration Files
- `carbonio-docs-editor-template.hcl`: Consul service template
- `intentions.json`: Service mesh intentions
- `policies.json`: ACL policies
- `service-protocol.json`: Protocol configuration

## Architecture

The service follows a microservices pattern with:
- Main application service
- Envoy sidecar proxy for traffic management
- Consul for service discovery and configuration
- Automatic routing based on service IDs

## Security

- Consul ACL policies for service access control
- Token-based authentication
- Specific HTTP path permissions for preview service integration
- Systemd security hardening with sandboxing
