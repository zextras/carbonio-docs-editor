#!/bin/bash

# SPDX-FileCopyrightText: 2022 Zextras <https://www.zextras.com>
#
# SPDX-License-Identifier: AGPL-3.0-only

set -e

# This script runs INSIDE the container
# It installs dependencies, prepares yap, and builds the package
#
# Usage (inside container): ./build-in-container.sh <thirds-dir|none> <core-dir|none> <distro> [package-dir]

THIRDS_DIR=$1
CORE_DIR=$2
DISTRO=$3
PACKAGE_DIR=${4:-/project}

if [ -z "$DISTRO" ]; then
    echo "Usage: $0 <thirds-dir|none> <core-dir|none> <distro> [package-dir]"
    exit 1
fi

echo "==> Building $PACKAGE_DIR for $DISTRO"

install_packages() {
    local dir=$1
    local label=$2

    if [ "$dir" = "none" ] || [ -z "$dir" ]; then
        return
    fi

    echo "==> Installing $label from $dir"

    if [ -f /etc/debian_version ]; then
        apt-get update
        find "$dir" -name '*.deb' -exec dpkg -i {} + || apt-get install -f -y
    elif [ -f /etc/redhat-release ]; then
        # Enable EPEL for additional dependencies
        echo "==> Enabling EPEL repository"
        yum install -y epel-release

        # Use yum localinstall to resolve dependencies automatically
        echo "==> Installing RPM packages with dependency resolution"
        yum install -y "$dir"/*.rpm
    else
        echo "Error: Unknown distribution"
        exit 1
    fi
    echo "==> $label installed"
}

# Install Node.js (not available in default repos)
echo "==> Installing Node.js"
if [ -f /etc/debian_version ]; then
    apt-get update
    apt-get install -y ca-certificates gnupg wget
    mkdir -p /etc/apt/keyrings
    wget -qO- https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
        | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" \
        > /etc/apt/sources.list.d/nodesource.list
    apt-get update
    apt-get install -y nodejs
elif [ -f /etc/redhat-release ]; then
    SYS_ARCH=$(uname -m)
    cat > /etc/yum.repos.d/nodesource-nodejs.repo <<NODEREPO
[nodesource-nodejs]
name=Node.js Packages for Linux RPM based distros - ${SYS_ARCH}
baseurl=https://rpm.nodesource.com/pub_22.x/nodistro/nodejs/${SYS_ARCH}
priority=9
enabled=1
gpgcheck=1
gpgkey=https://rpm.nodesource.com/gpgkey/ns-operations-public.key
module_hotfixes=1
NODEREPO
    yum makecache --disablerepo="*" --enablerepo="nodesource-nodejs"
    yum install -y nodejs
fi

# Install third-party dependencies (carbonio-thirds: openssl, poco, etc.)
install_packages "$THIRDS_DIR" "third-party dependencies (carbonio-thirds)"

# Install core dependencies (carbonio-docs-core)
install_packages "$CORE_DIR" "core dependencies (carbonio-docs-core)"

# Prepare yap
echo "==> Running yap prepare $DISTRO"
yap prepare "$DISTRO"

# Build package
echo "==> Running yap build $DISTRO $PACKAGE_DIR"
yap build "$DISTRO" "$PACKAGE_DIR"

echo "==> Build complete!"
