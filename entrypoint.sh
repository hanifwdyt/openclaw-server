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
        "primary": "openrouter/anthropic/claude-haiku-4.5"
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
  // Set auth mode to token so internal agent authenticates via OPENCLAW_GATEWAY_TOKEN env
  if(!c.gateway)c.gateway={};
  if(!c.gateway.auth)c.gateway.auth={};
  c.gateway.auth.mode='token';
  // Ensure controlUi settings
  if(!c.gateway.controlUi)c.gateway.controlUi={};
  c.gateway.controlUi.dangerouslyDisableDeviceAuth=true;
  // Ensure model is haiku 4.5
  if(!c.agents)c.agents={};
  if(!c.agents.defaults)c.agents.defaults={};
  if(!c.agents.defaults.model)c.agents.defaults.model={};
  c.agents.defaults.model.primary='openrouter/anthropic/claude-haiku-4.5';
  // Enable HTTP API for debugging
  if(!c.gateway.http)c.gateway.http={};
  if(!c.gateway.http.endpoints)c.gateway.http.endpoints={};
  c.gateway.http.endpoints.chatCompletions={enabled:true};
  c.gateway.http.endpoints.responses={enabled:true};
  // Fix WhatsApp dmPolicy - must be 'open' for auto-reply to work
  if(!c.channels)c.channels={};
  if(!c.channels.whatsapp)c.channels.whatsapp={};
  c.channels.whatsapp.dmPolicy='open';
  if(!c.channels.whatsapp.accounts)c.channels.whatsapp.accounts={};
  if(!c.channels.whatsapp.accounts.default)c.channels.whatsapp.accounts.default={};
  c.channels.whatsapp.accounts.default.dmPolicy='open';
  c.channels.whatsapp.accounts.default.allowFrom=['*'];
  fs.writeFileSync('$CONFIG_FILE',JSON.stringify(c,null,2));
  console.log('Patched config:',JSON.stringify(c,null,2));
"

# Generate gateway token via env if not already set (avoids config-based token issues)
if [ -z "$OPENCLAW_GATEWAY_TOKEN" ]; then
  export OPENCLAW_GATEWAY_TOKEN=$(openssl rand -hex 32)
  echo "Generated gateway token via env var"
fi

# Auto-pair the local device identity with the gateway
# Without this, internal agent gets "pairing required" (1008) on ws://127.0.0.1
IDENTITY_FILE="$CONFIG_DIR/identity/device.json"
PAIRED_FILE="$CONFIG_DIR/devices/paired.json"
if [ -f "$IDENTITY_FILE" ]; then
  mkdir -p "$CONFIG_DIR/devices"
  [ -f "$PAIRED_FILE" ] || echo '{}' > "$PAIRED_FILE"
  node -e "
    const fs=require('fs');
    const device=JSON.parse(fs.readFileSync('$IDENTITY_FILE'));
    const paired=JSON.parse(fs.readFileSync('$PAIRED_FILE'));
    if(!paired[device.deviceId]){
      const crypto=require('crypto');
    const keyObj=crypto.createPublicKey(device.publicKeyPem);
    const rawKey=keyObj.export({type:'spki',format:'der'}).subarray(-32);
    const b64url=rawKey.toString('base64url');
    paired[device.deviceId]={
        deviceId:device.deviceId,publicKey:b64url,
        platform:'linux',clientId:'internal-agent',clientMode:'cli',
        role:'operator',roles:['operator'],
        scopes:['operator.admin','operator.read','operator.write','operator.approvals','operator.pairing'],
        approvedScopes:['operator.admin','operator.read','operator.write','operator.approvals','operator.pairing'],
        tokens:{},createdAtMs:Date.now(),approvedAtMs:Date.now()
      };
      fs.writeFileSync('$PAIRED_FILE',JSON.stringify(paired,null,2));
      console.log('Auto-paired device:',device.deviceId);
    } else { console.log('Device already paired'); }
  "
  chown node:node "$PAIRED_FILE"
fi

# Drop to node user and start gateway
echo "OPENCLAW_GATEWAY_TOKEN is set: $([ -n "$OPENCLAW_GATEWAY_TOKEN" ] && echo 'yes' || echo 'no')"
echo "OPENROUTER_API_KEY is set: $([ -n "$OPENROUTER_API_KEY" ] && echo 'yes' || echo 'no')"
exec su -s /bin/bash node -c "export OPENCLAW_GATEWAY_TOKEN='$OPENCLAW_GATEWAY_TOKEN' && export OPENROUTER_API_KEY='$OPENROUTER_API_KEY' && cd /app && exec node dist/index.js gateway --bind lan --port 18789"
