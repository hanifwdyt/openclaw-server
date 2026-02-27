FROM ghcr.io/openclaw/openclaw:latest

EXPOSE 18789

# Use the official image's WORKDIR (where dist/index.js lives)
# Config is created via env vars and will persist in mounted volume
CMD ["node", "dist/index.js", "gateway", "--bind", "lan", "--port", "18789"]
