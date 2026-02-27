FROM ghcr.io/openclaw/openclaw:latest

# Cache bust to force fresh base image pull (update date to force rebuild)
ARG OPENCLAW_VERSION=2026.2.27
LABEL openclaw.rebuild="${OPENCLAW_VERSION}"

USER root
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
RUN printf '#!/bin/sh\ncd /app && exec node dist/index.js "$@"\n' > /usr/local/bin/openclaw && chmod +x /usr/local/bin/openclaw

EXPOSE 18789

ENTRYPOINT ["/entrypoint.sh"]
