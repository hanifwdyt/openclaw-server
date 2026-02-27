FROM ghcr.io/openclaw/openclaw:latest
EXPOSE 18789
CMD ["node", "dist/index.js", "gateway", "--bind", "lan", "--port", "18789", "--allow-unconfigured"]
