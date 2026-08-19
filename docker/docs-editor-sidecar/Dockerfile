# python3 + python3-requests are needed by the routes generator / setup scripts.
# jq is already present in the carbonio-sidecar base. Installing python3 via apt
# in the final stage runs target-arch maintainer scripts (no QEMU => exec format
# error on arm64). Instead, cross-download the target-arch .debs on the
# BUILDPLATFORM (amd64 CI builder) from ports.ubuntu.com and extract them with
# dpkg -x (no maintainer scripts execute). All packages are the same ubuntu
# jammy version as the carbonio-sidecar base, so relocating the interpreter
# tree + its shared libs is ABI-consistent. Everything stages under /usr (not
# bare /lib): jammy is usrmerged so /lib is a symlink to /usr/lib, and COPYing
# into /lib/* fails on some buildkit versions ("cannot copy to non-directory").
#
# Note: python3-requests (and its pure-Python deps certifi/chardet/idna/urllib3/
# six) are Architecture: all — they must NOT carry an :arm64 suffix or apt
# reports "no installation candidate". Only arch-specific packages get :arm64.
FROM --platform=$BUILDPLATFORM ubuntu:jammy AS py
ARG TARGETARCH
RUN set -eux; \
    case "$TARGETARCH" in \
      arm64) TRIPLET=aarch64-linux-gnu ;; \
      amd64) TRIPLET=x86_64-linux-gnu ;; \
      *) echo "unsupported TARGETARCH=$TARGETARCH" >&2; exit 1 ;; \
    esac; \
    dpkg --add-architecture "${TARGETARCH}"; \
    if [ "$TARGETARCH" != "amd64" ]; then \
      sed -i 's|http://archive.ubuntu.com/ubuntu/|[arch=amd64] http://archive.ubuntu.com/ubuntu/|; s|http://security.ubuntu.com/ubuntu/|[arch=amd64] http://security.ubuntu.com/ubuntu/|' /etc/apt/sources.list; \
      printf 'deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports/ jammy main universe\ndeb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports/ jammy-updates main universe\ndeb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports/ jammy-security main universe\n' > /etc/apt/sources.list.d/arm64.list; \
    fi; \
    apt-get update; \
    mkdir -p /dl /x /out; \
    apt-get install -y --download-only --no-install-recommends -o Dir::Cache::archives=/dl \
      python3:${TARGETARCH} python3-requests; \
    for d in /dl/*.deb; do dpkg -x "$d" /x; done; \
    # Relocate the interpreter, stdlib, dist-packages (requests + deps) and the
    # python-specific shared libs the base does not ship. cp -a preserves the
    # soname symlinks. ca-certificates is needed by requests for TLS.
    mkdir -p /out/usr/bin "/out/usr/lib/${TRIPLET}" /out/usr/lib/python3.10 /out/usr/lib/python3 /out/etc/ssl/certs /out/usr/share/ca-certificates; \
    cp -a /x/usr/bin/python3.10            /out/usr/bin/python3.10; \
    ln -s python3.10                       /out/usr/bin/python3; \
    cp -a /x/usr/lib/python3.10/.          /out/usr/lib/python3.10/; \
    cp -a /x/usr/lib/python3/.             /out/usr/lib/python3/; \
    # jammy's python3.10-minimal binary is statically linked against libpython,
    # so libpython3.10.so is not in the closure. Copy every arm64 .so the closure
    # DID provide (mpdec/sqlite/expat/ffi/nsl/uuid/db/readline/libpython-if-present)
    # from both the triplet libdir and bare /lib, preserving soname symlinks.
    for d in "/x/usr/lib/${TRIPLET}" "/x/lib/${TRIPLET}"; do \
      [ -d "$d" ] || continue; \
      find "$d" -maxdepth 1 -name '*.so*' -exec cp -a {} "/out/usr/lib/${TRIPLET}/" \; ; \
    done; \
    cp -a /x/etc/ssl/certs/.               /out/etc/ssl/certs/ 2>/dev/null || true; \
    cp -a /x/usr/share/ca-certificates/.   /out/usr/share/ca-certificates/ 2>/dev/null || true; \
    test -x /out/usr/bin/python3.10

FROM registry.dev.zextras.com/dev/carbonio-sidecar:devel

# Arch-matched python3 interpreter + stdlib + requests, cross-downloaded above.
# No target-arch RUN => QEMU-free multi-arch build.
COPY --from=py /out /

# Service registration (template, processed by routes generator)
COPY package/carbonio-docs-editor-template.hcl /etc/zextras/service-discover/templates/

# Setup files
COPY package/service-protocol.json /etc/carbonio/docs-editor/service-discover/
COPY package/intentions.json       /etc/carbonio/docs-editor/service-discover/
COPY package/policies.json         /etc/carbonio/docs-editor/service-discover/

# Routes generator (generates HCL, service-resolver, service-router)
COPY package/carbonio-docs-routes-generator.py /usr/lib/carbonio-docs-routes-generator.py
<<<<<<< Updated upstream
COPY --chmod=755 docker/docs-editor-sidecar/entrypoint.sh /usr/local/bin/carbonio-docs-editor-entrypoint.sh
||||||| Stash base
COPY docker/docs-editor-sidecar/entrypoint.sh /usr/local/bin/carbonio-docs-editor-entrypoint.sh
RUN chmod +x /usr/local/bin/carbonio-docs-editor-entrypoint.sh
=======
# Entrypoint script (COPY --chmod avoids a target-arch RUN — QEMU-free)
COPY --chmod=755 docker/docs-editor-sidecar/entrypoint.sh /usr/local/bin/carbonio-docs-editor-entrypoint.sh
>>>>>>> Stashed changes

<<<<<<< Updated upstream
# Setup script
COPY --chmod=755 package/carbonio-docs-editor /usr/local/bin/carbonio-docs-editor
||||||| Stash base
# Setup script
COPY package/carbonio-docs-editor /usr/local/bin/carbonio-docs-editor
RUN chmod +x /usr/local/bin/carbonio-docs-editor
=======
# Setup script (COPY --chmod avoids a target-arch RUN — QEMU-free)
COPY --chmod=755 package/carbonio-docs-editor /usr/local/bin/carbonio-docs-editor
>>>>>>> Stashed changes

ENV SERVICE_NAME=carbonio-docs-editor
ENV SETUP_SCRIPT="carbonio-docs-editor setup"
ENV TOKEN_FILE=/etc/carbonio/docs-editor/service-discover/token

ENTRYPOINT ["/usr/local/bin/carbonio-docs-editor-entrypoint.sh"]
