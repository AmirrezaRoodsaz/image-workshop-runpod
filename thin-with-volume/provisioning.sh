#!/usr/bin/env bash
# =============================================================================
#  Method B provisioning — set up the whole studio at RUNTIME on /workspace.
#
#  Run this ONCE on a running RunPod pod (any Ubuntu + Python + CUDA base,
#  e.g. "RunPod PyTorch"). It installs ComfyUI + Manager + your custom nodes
#  and downloads your models.
#
#  - If /workspace is a NETWORK VOLUME  -> everything persists; run once ever.
#  - If /workspace is ephemeral         -> re-run on each fresh pod (models
#                                          re-download, ~10-15 min). Region-free.
#
#  Usage on the pod:
#      export HF_TOKEN=hf_xxx          # needed for gated FLUX.2
#      export CIVITAI_TOKEN=           # optional
#      git clone https://github.com/AmirrezaRoodsaz/image-workshop-runpod.git
#      bash image-workshop-runpod/thin-with-volume/provisioning.sh
# =============================================================================
set -uo pipefail

WORKSPACE="${WORKSPACE:-/workspace}"
HERE="$(cd "$(dirname "$0")" && pwd)"
PY="${PYTHON:-python3}"

echo "== [1/6] system deps =="
apt-get update && apt-get install -y --no-install-recommends \
    git aria2 ffmpeg libgl1 libglib2.0-0 || true

echo "== [2/6] PyTorch cu128 (needed for RTX 5090 / Blackwell; fine on older GPUs) =="
$PY -m pip install torch torchvision torchaudio \
    --index-url https://download.pytorch.org/whl/cu128

echo "== [3/6] ComfyUI =="
if [ ! -d "$WORKSPACE/ComfyUI" ]; then
    git clone https://github.com/comfyanonymous/ComfyUI.git "$WORKSPACE/ComfyUI"
fi
$PY -m pip install -r "$WORKSPACE/ComfyUI/requirements.txt"

echo "== [4/6] ComfyUI-Manager =="
MGR="$WORKSPACE/ComfyUI/custom_nodes/ComfyUI-Manager"
[ -d "$MGR" ] || git clone https://github.com/ltdrdata/ComfyUI-Manager.git "$MGR"
$PY -m pip install -r "$MGR/requirements.txt" || true

echo "== [5/6] custom nodes =="
WORKSPACE="$WORKSPACE" PYTHON="$PY" bash "$HERE/build/install_nodes.sh"

echo "== [6/6] models =="
HF_TOKEN="${HF_TOKEN:-}" CIVITAI_TOKEN="${CIVITAI_TOKEN:-}" \
    bash "$HERE/build/download_models.sh"

echo ""
echo "== DONE. Start ComfyUI with:"
echo "   cd $WORKSPACE/ComfyUI && $PY main.py --listen 0.0.0.0 --port 8188"
