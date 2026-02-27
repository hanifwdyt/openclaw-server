FROM ghcr.io/openclaw/openclaw:latest

# Create config directory and minimal config for gateway startup
RUN mkdir -p /home/node/.openclaw/workspace && \
    printf '{"gateway":{"mode":"local","bind":"lan","port":18789},"agents":{"defaults":{"model":{"primary":"openrouter/anthropic/claude-sonnet-4"}}}}\n' \
    > /home/node/.openclaw/openclaw.json && \
    chown -R node:node /home/node/.openclaw

EXPOSE 18789

CMD ["node", "dist/index.js", "gateway", "--bind", "lan", "--port", "18789"]
