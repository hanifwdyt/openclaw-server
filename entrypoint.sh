#!/bin/bash
set -e

CONFIG_FILE="/home/node/.openclaw/openclaw.json"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "No config found, creating initial config..."
  mkdir -p /home/node/.openclaw/workspace
  cat > "$CONFIG_FILE" << 'EOF'
{
  "gateway": {
    "mode": "local",
    "bind": "lan",
    "port": 18789,
    "controlUi": {
      "allowedOrigins": ["https://openclaw.hanif.app", "http://openclaw.hanif.app"]
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "openrouter/anthropic/claude-sonnet-4"
      }
    }
  }
}
EOF
fi

exec node dist/index.js gateway --bind lan --port 18789
