FROM node:22-bookworm-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install OpenClaw globally
RUN npm install -g openclaw@latest

# Setup directories with correct ownership
RUN mkdir -p /home/node/.openclaw/workspace \
    && chown -R node:node /home/node

USER node
WORKDIR /home/node

EXPOSE 18789

CMD ["openclaw", "gateway", "--bind", "lan", "--port", "18789"]
