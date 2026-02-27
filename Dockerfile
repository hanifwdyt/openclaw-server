FROM ghcr.io/openclaw/openclaw:latest

# Create minimal config so gateway starts without onboarding
# Config will be overwritten by volume mount if persistent storage is set
RUN mkdir -p /home/node/.openclaw/workspace && \
    echo '{"gateway":{"mode":"local","bind":"lan","port":18789},"agent":{"model":"openrouter/anthropic/claude-sonnet-4"}}' > /home/node/.openclaw/openclaw.json

EXPOSE 18789

CMD ["node", "dist/index.js", "gateway", "--bind", "lan", "--port", "18789"]
