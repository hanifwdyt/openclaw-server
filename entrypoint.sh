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
exec node dist/index.js gateway --bind lan --port 18789
