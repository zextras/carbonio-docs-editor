#!/bin/sh
echo "[sidecar] Waiting for consul agent..."
until consul members >/dev/null 2>&1; do sleep 1; done
echo "[sidecar] Consul agent ready."
if [ -n "${SETUP_SCRIPT}" ]; then
  (${SETUP_SCRIPT} || true)
fi
consul services register /etc/zextras/service-discover/carbonio-docs-editor.hcl

# See registry.dev.zextras.com/dev/carbonio-sidecar base entrypoint - just start sidecar in this case
exec /usr/local/bin/entrypoint.sh do_start