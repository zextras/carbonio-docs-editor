FROM registry.dev.zextras.com/dev/carbonio-sidecar:latest

# Service registration (template, processed by routes generator)
COPY package/carbonio-docs-editor-template.hcl /etc/zextras/service-discover/templates/

# Setup files
COPY package/service-protocol.json /etc/carbonio/docs-editor/service-discover/
COPY package/intentions.json       /etc/carbonio/docs-editor/service-discover/
COPY package/policies.json         /etc/carbonio/docs-editor/service-discover/

# Routes generator (generates HCL, service-resolver, service-router)
COPY package/carbonio-docs-routes-generator.py /usr/lib/carbonio-docs-routes-generator.py

# Setup script
COPY package/carbonio-docs-editor /usr/local/bin/carbonio-docs-editor
RUN chmod +x /usr/local/bin/carbonio-docs-editor

ENV SERVICE_NAME=carbonio-docs-editor
ENV SETUP_SCRIPT="carbonio-docs-editor setup"
ENV TOKEN_FILE=/etc/carbonio/docs-editor/service-discover/token
