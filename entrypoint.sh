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
        "primary": "openrouter/anthropic/claude-haiku-4-5-20251001"
      }
    }
  }
}
EOF
chown node:node "$CONFIG_FILE"
else
echo "Config exists, preserving..."
fi

# Always patch config to fix known issues
echo "Patching config..."
node -e "
  const fs=require('fs');
  const c=JSON.parse(fs.readFileSync('$CONFIG_FILE'));
  // Remove gateway.token - causes bad gateway when invalid/stale
  if(c.gateway && c.gateway.token) delete c.gateway.token;
  // Ensure controlUi settings
  if(!c.gateway)c.gateway={};
  if(!c.gateway.controlUi)c.gateway.controlUi={};
  c.gateway.controlUi.dangerouslyDisableDeviceAuth=true;
  // Ensure model is haiku 4.5
  if(!c.agents)c.agents={};
  if(!c.agents.defaults)c.agents.defaults={};
  if(!c.agents.defaults.model)c.agents.defaults.model={};
  c.agents.defaults.model.primary='openrouter/anthropic/claude-haiku-4-5-20251001';
  fs.writeFileSync('$CONFIG_FILE',JSON.stringify(c,null,2));
"

# Generate gateway token via env if not already set (avoids config-based token issues)
if [ -z "$OPENCLAW_GATEWAY_TOKEN" ]; then
  export OPENCLAW_GATEWAY_TOKEN=$(openssl rand -hex 32)
  echo "Generated gateway token via env var"
fi

# Drop to node user and start gateway
exec su -s /bin/bash node -c "export OPENCLAW_GATEWAY_TOKEN='$OPENCLAW_GATEWAY_TOKEN' && cd /app && exec node dist/index.js gateway --bind lan --port 18789"
