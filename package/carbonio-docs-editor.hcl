services {
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
  port = 9980
}
