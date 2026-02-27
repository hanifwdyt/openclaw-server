#!/bin/bash
set -e

CONFIG_DIR="/home/node/.openclaw"
CONFIG_FILE="$CONFIG_DIR/openclaw.json"

# Create config if it doesn't exist
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Creating initial OpenClaw config..."
  mkdir -p "$CONFIG_DIR/workspace"
  cat > "$CONFIG_FILE" <<EOF
{
  "agent": {
    "model": "openrouter/anthropic/claude-sonnet-4"
  },
  "gateway": {
    "bind": "lan",
    "port": 18789
  }
}
EOF
fi

echo "Starting OpenClaw gateway..."
echo "Working dir: $(pwd)"
echo "Files: $(ls dist/index.js 2>/dev/null && echo 'found' || echo 'not found')"

# Use openclaw CLI (npm global binary) instead of node dist/index.js
exec openclaw gateway --bind lan --port 18789
