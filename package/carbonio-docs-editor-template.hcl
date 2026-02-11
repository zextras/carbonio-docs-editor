# SPDX-FileCopyrightText: 2022-2025 Zextras <https://www.zextras.com>
#
# SPDX-License-Identifier: AGPL-3.0-only

services {
  check {
    tcp      = "localhost:10000"
    timeout  = "1s"
    interval = "5s"
  }
  meta {
    $METADATA_KEY = "$METADATA_VALUE"
  }
  connect {
    sidecar_service {
      proxy {
        local_service_address = "127.0.0.1"
        upstreams = [
          {
            destination_name = "carbonio-docs-connector"
            local_bind_address = "127.78.0.12"
            local_bind_port = 20000
          }
        ]
      }
    }
  }
  name = "carbonio-docs-editor"
  port = 10000
}
