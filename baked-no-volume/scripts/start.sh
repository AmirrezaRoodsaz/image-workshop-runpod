#!/usr/bin/env bash
# Entrypoint: runs once when the pod boots, then hands off to supervisord.
set -e

# Password for the web services (FileBrowser / Kohya / Jupyter / code-server).
: "${WEB_PASSWORD:=comfy}"
export WEB_PASSWORD

# --- SSH ---
mkdir -p /root/.ssh && chmod 700 /root/.ssh
ssh-keygen -A                                   # generate host keys
# RunPod injects your public key as $PUBLIC_KEY — allow it in for SSH.
if [ -n "${PUBLIC_KEY:-}" ]; then
    echo "$PUBLIC_KEY" > /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/authorized_keys
fi
mkdir -p /var/run/sshd /var/log

echo "== starting services (web password: $WEB_PASSWORD) =="
exec supervisord -c /workspace/supervisor/supervisord.conf
