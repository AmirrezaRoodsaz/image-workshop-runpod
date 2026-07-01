#!/usr/bin/env bash
# ComfyUI on :8188 (open — sits behind RunPod's proxy)
cd /workspace/ComfyUI
exec python3.11 main.py --listen 0.0.0.0 --port 8188
