# syntax=docker/dockerfile:1
# =============================================================================
#  image-workshop-baked — Dockerfile
#  Method A: everything baked into the image, no network volume needed.
#
#  Built in STEPS. This file currently contains:
#    [STEP 1] Base layers  <-- you are here
#  Coming next:
#    [STEP 2] ComfyUI + ComfyUI-Manager
#    [STEP 3] custom nodes (build/nodes.list)
#    [STEP 4] Kohya SS + FileBrowser + JupyterLab + code-server
#    [STEP 5] supervisord + start.sh
#    [STEP 6] models (build/models.list)  <-- the big, last layer
# =============================================================================


# -----------------------------------------------------------------------------
# [STEP 1] BASE LAYERS
# -----------------------------------------------------------------------------

# The starting point: an official NVIDIA image that already contains CUDA 12.8
# and cuDNN on Ubuntu 22.04. CUDA 12.8 is REQUIRED for the RTX 5090 (Blackwell)
# and is backward-compatible with older cards (4090, A100, H100, H200, etc.).
# "devel" (not "runtime") because some custom nodes compile code during install.
FROM nvidia/cuda:12.8.1-cudnn-devel-ubuntu22.04

# --- Environment defaults ---------------------------------------------------
# DEBIAN_FRONTEND=noninteractive : never stop the build to ask a question.
# PYTHONUNBUFFERED=1             : show Python logs immediately (good for debugging).
# PIP_NO_CACHE_DIR=1             : don't keep pip's download cache -> smaller image.
# PIP_ROOT_USER_ACTION=ignore    : silence pip's "you are root" warning.
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_ROOT_USER_ACTION=ignore \
    SHELL=/bin/bash

# --- System packages --------------------------------------------------------
# One big install so it's a single cached layer. What each is for:
#   git                     : clone ComfyUI and custom nodes
#   wget, curl, aria2       : download models (aria2 = fast multi-connection)
#   ca-certificates         : HTTPS works
#   build-essential, cmake  : compile native bits some nodes need
#   ffmpeg                  : video nodes (VideoHelperSuite, frame interpolation)
#   libgl1, libglib2.0-0    : image libraries OpenCV/Pillow rely on
#   openssh-server          : SSH access to the pod
#   software-properties-common : lets us add the deadsnakes PPA below
#   unzip, nano, tmux       : small quality-of-life tools
# The `rm -rf /var/lib/apt/lists/*` at the end trims the layer size.
# Make apt robust over the (rootless) build network: no HTTP pipelining
# (which truncates index files -> "package not found"), force IPv4, retry.
RUN printf 'Acquire::ForceIPv4 "true";\nAcquire::http::Pipeline-Depth "0";\nAcquire::Retries "5";\n' \
        > /etc/apt/apt.conf.d/99network
RUN apt-get update && apt-get install -y --no-install-recommends \
        git wget curl aria2 ca-certificates \
        build-essential cmake \
        ffmpeg libgl1 libglib2.0-0 \
        openssh-server \
        software-properties-common \
        unzip \
    && rm -rf /var/lib/apt/lists/*

# --- Python 3.11 ------------------------------------------------------------
# Ubuntu 22.04 ships Python 3.10. We add the "deadsnakes" PPA to get 3.11,
# then make `python` and `python3` point to it, and install pip.
RUN add-apt-repository -y ppa:deadsnakes/ppa \
    && apt-get update && apt-get install -y --no-install-recommends \
        python3.11 python3.11-venv python3.11-dev \
    && rm -rf /var/lib/apt/lists/* \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1 \
    && update-alternatives --install /usr/bin/python  python  /usr/bin/python3.11 1 \
    && curl -sS https://bootstrap.pypa.io/get-pip.py | python3.11 \
    && python3.11 -m pip install --upgrade pip setuptools wheel

# --- PyTorch (cu128 build) --------------------------------------------------
# Install PyTorch built for CUDA 12.8 (the "cu128" wheels). This is the line
# that makes the RTX 5090 / Blackwell work. Same wheels also run on older GPUs.
RUN python3.11 -m pip install \
        torch torchvision torchaudio \
        --index-url https://download.pytorch.org/whl/cu128

# --- Workspace --------------------------------------------------------------
# Everything we install (ComfyUI, models, etc.) will live under /workspace.
WORKDIR /workspace

# --- Quick sanity check (runs during build, not at runtime) -----------------
# Prints the torch + CUDA version into the build log so we can confirm the
# base is correct. If this line fails, the base layer is wrong.
RUN python3.11 -c "import torch; print('torch', torch.__version__, '| cuda build', torch.version.cuda)"

# -----------------------------------------------------------------------------
# [STEP 2] ComfyUI + ComfyUI-Manager
# -----------------------------------------------------------------------------

# Clone ComfyUI itself and install its Python requirements.
# (torch is already installed from STEP 1; pip leaves it as-is.)
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /workspace/ComfyUI \
    && python3.11 -m pip install -r /workspace/ComfyUI/requirements.txt

# ComfyUI-Manager: the in-browser panel to install custom nodes and download
# models LIVE on a running pod (no rebuild). Lives inside ComfyUI's custom_nodes.
RUN git clone https://github.com/ltdrdata/ComfyUI-Manager.git \
        /workspace/ComfyUI/custom_nodes/ComfyUI-Manager \
    && python3.11 -m pip install -r \
        /workspace/ComfyUI/custom_nodes/ComfyUI-Manager/requirements.txt

# -----------------------------------------------------------------------------
# [STEP 3] Custom nodes (from build/nodes.list)
# -----------------------------------------------------------------------------

# Copy the manifest + installer, then run it. The installer clones each node
# and pip-installs its requirements. Editing nodes.list later changes this
# layer (and everything after it) on the next rebuild.
COPY build/nodes.list build/install_nodes.sh /workspace/build/
RUN bash /workspace/build/install_nodes.sh

# -----------------------------------------------------------------------------
# [STEP 4] Tooling: JupyterLab + FileBrowser + code-server + Kohya SS
# -----------------------------------------------------------------------------

# JupyterLab (notebook + browser terminal), FileBrowser (web file manager),
# code-server (VS Code in the browser). These are small and rarely change, so
# they're one cached layer, separate from the heavier Kohya install below.
RUN python3.11 -m pip install jupyterlab \
    && curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash \
    && curl -fsSL https://code-server.dev/install.sh | sh

# Kohya SS (LoRA training GUI, runs on port 7860). Cloned with its sd-scripts
# submodule. We install its Python requirements but NOT torch — the cu128 torch
# from STEP 1 stays. ponytail: known risk — Kohya pins some deps; if a version
# clash shows up at build time, pin the offending package here.
RUN git clone --recursive https://github.com/bmaltais/kohya_ss.git /workspace/kohya_ss \
    && python3.11 -m pip install -r /workspace/kohya_ss/requirements.txt || \
       echo "!! kohya requirements had issues — review at build time"

# -----------------------------------------------------------------------------
# [STEP 5] Glue: supervisord + service launchers + entrypoint
# -----------------------------------------------------------------------------

# supervisord keeps all 6 services running at once.
RUN python3.11 -m pip install supervisor

# Copy the launchers, supervisord config, and entrypoint into the image.
COPY scripts/   /workspace/scripts/
COPY supervisor/ /workspace/supervisor/
RUN chmod +x /workspace/scripts/start.sh /workspace/scripts/services/*.sh

# Doors into the running pod: ComfyUI, Kohya, FileBrowser, Jupyter, code-server, SSH.
EXPOSE 8188 7860 8080 8888 7777 22

# On boot: run start.sh (sets password + SSH, then launches supervisord).
ENTRYPOINT ["bash", "/workspace/scripts/start.sh"]

# -----------------------------------------------------------------------------
# [STEP 6] Models (from build/models.list) — the big, final layer
# -----------------------------------------------------------------------------

# Tokens come in as BUILD SECRETS (never written to a layer). They're read into
# env vars only for this one RUN, used to download the models, then gone.
# build-on-runpod.sh passes them with: --secret id=hf_token --secret id=civitai_token
COPY build/models.list build/download_models.sh /workspace/build/
RUN --mount=type=secret,id=hf_token --mount=type=secret,id=civitai_token \
    HF_TOKEN="$(cat /run/secrets/hf_token 2>/dev/null || true)" \
    CIVITAI_TOKEN="$(cat /run/secrets/civitai_token 2>/dev/null || true)" \
    bash /workspace/build/download_models.sh

# -----------------------------------------------------------------------------
# END OF STEP 6.  The image is complete. Next: build-on-runpod.sh (real build).
# -----------------------------------------------------------------------------
