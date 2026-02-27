#!/bin/bash
set -e

CONFIG_DIR="/home/node/.openclaw"
CONFIG_FILE="$CONFIG_DIR/openclaw.json"

# Fix ownership (volume might be root-owned)
chown -R node:node "$CONFIG_DIR" 2>/dev/null || true

if [ ! -f "$CONFIG_FILE" ]; then
  echo "No config found, creating initial config..."
  mkdir -p "$CONFIG_DIR/workspace"
  cat > "$CONFIG_FILE" << 'EOF'
{
  "gateway": {
    "mode": "local",
    "bind": "lan",
    "port": 18789,
    "controlUi": {
      "allowedOrigins": ["https://openclaw.hanif.app", "http://openclaw.hanif.app"],
      "allowInsecureAuth": true
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
  chown node:node "$CONFIG_FILE"
else
  # Patch existing config: add allowInsecureAuth if missing
  if ! grep -q '"allowInsecureAuth"' "$CONFIG_FILE"; then
    echo "Patching config with allowInsecureAuth..."
    sed -i 's/"allowedOrigins"/"allowInsecureAuth": true,\n      "allowedOrigins"/' "$CONFIG_FILE"
  fi
fi

# Drop to node user and start gateway
exec su -s /bin/bash node -c "cd /app && exec node dist/index.js gateway --bind lan --port 18789"
