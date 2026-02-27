FROM ghcr.io/openclaw/openclaw:latest

USER root

# Create persistent dirs
RUN mkdir -p /home/node/.openclaw/workspace \
    && chown -R node:node /home/node

COPY --chown=node:node entrypoint.sh /home/node/entrypoint.sh
RUN chmod +x /home/node/entrypoint.sh

USER node
WORKDIR /home/node

EXPOSE 18789

ENTRYPOINT ["/home/node/entrypoint.sh"]
