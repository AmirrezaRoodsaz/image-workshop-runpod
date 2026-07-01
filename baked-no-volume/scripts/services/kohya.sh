#!/usr/bin/env bash
# Kohya SS LoRA training GUI on :7860, login admin / WEB_PASSWORD
cd /workspace/kohya_ss
exec python3.11 kohya_gui.py \
    --listen 0.0.0.0 --server_port 7860 --headless \
    --username admin --password "${WEB_PASSWORD:-comfy}"
