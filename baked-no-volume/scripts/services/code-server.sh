#!/usr/bin/env bash
# code-server (VS Code in browser) on :7777, login = WEB_PASSWORD
export PASSWORD="${WEB_PASSWORD:-comfy}"
exec code-server --bind-addr 0.0.0.0:7777 --auth password /workspace
