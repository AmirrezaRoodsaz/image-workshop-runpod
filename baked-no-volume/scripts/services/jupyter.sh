#!/usr/bin/env bash
# JupyterLab on :8888, login token = WEB_PASSWORD
cd /workspace
exec python3.11 -m jupyterlab \
    --ip=0.0.0.0 --port=8888 --allow-root --no-browser \
    --ServerApp.root_dir=/workspace \
    --ServerApp.token="${WEB_PASSWORD:-comfy}"
