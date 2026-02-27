#!/bin/bash
set -e

CONFIG_DIR="/home/node/.openclaw"
CONFIG_FILE="$CONFIG_DIR/openclaw.json"

# Fix ownership (volume might be root-owned)
chown -R node:node "$CONFIG_DIR" 2>/dev/null || true
mkdir -p "$CONFIG_DIR/workspace"

# Only write config if it doesn't exist (preserve persistent state)
if [ ! -f "$CONFIG_FILE" ]; then
echo "No config found, creating initial config..."
cat > "$CONFIG_FILE" << 'EOF'
{
  "gateway": {
    "mode": "local",
    "bind": "lan",
    "port": 18789,
    "trustedProxies": ["0.0.0.0/0"],
    "controlUi": {
      "allowedOrigins": ["https://openclaw.hanif.app", "http://openclaw.hanif.app"],
      "allowInsecureAuth": true,
      "dangerouslyDisableDeviceAuth": true
    }
  },
  "channels": {
    "whatsapp": {
      "enabled": true,
      "dmPolicy": "open",
      "allowFrom": ["*"]
    },
    "telegram": {
      "enabled": true
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
echo "Config exists, preserving..."
# Patch: ensure dangerouslyDisableDeviceAuth is set on existing configs
if ! node -e "const c=JSON.parse(require('fs').readFileSync('$CONFIG_FILE'));process.exit(c.gateway?.controlUi?.dangerouslyDisableDeviceAuth?0:1)" 2>/dev/null; then
  echo "Patching config: adding dangerouslyDisableDeviceAuth..."
  node -e "
    const fs=require('fs');
    const c=JSON.parse(fs.readFileSync('$CONFIG_FILE'));
    if(!c.gateway)c.gateway={};
    if(!c.gateway.controlUi)c.gateway.controlUi={};
    c.gateway.controlUi.dangerouslyDisableDeviceAuth=true;
    fs.writeFileSync('$CONFIG_FILE',JSON.stringify(c,null,2));
  "
fi
fi

# Drop to node user and start gateway
exec su -s /bin/bash node -c "cd /app && exec node dist/index.js gateway --bind lan --port 18789"
