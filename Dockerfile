FROM ghcr.io/openclaw/openclaw:latest

EXPOSE 18789

# Debug: keep container alive so we can inspect
CMD ["sh", "-c", "echo '=== WORKDIR ===' && pwd && echo '=== LS ===' && ls -la && echo '=== HOME ===' && echo $HOME && echo '=== WHOAMI ===' && whoami && echo '=== CONFIG DIR ===' && ls -la /home/node/.openclaw/ 2>/dev/null || echo 'no .openclaw dir' && echo '=== OPENCLAW BIN ===' && which openclaw 2>/dev/null || echo 'no openclaw bin' && echo '=== NODE MODULES BIN ===' && ls /usr/local/bin/openclaw 2>/dev/null || echo 'not in /usr/local/bin' && echo '=== STAYING ALIVE ===' && tail -f /dev/null"]
