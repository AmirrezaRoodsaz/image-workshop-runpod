#!/usr/bin/env bash
# Build the image on a RunPod CPU pod and push it to Docker Hub.
#
# Run from inside the baked-no-volume/ folder, after:
#   export HF_TOKEN=...  CIVITAI_TOKEN=...  DOCKERHUB_USER=...
#   docker login -u "$DOCKERHUB_USER"
#
# Tokens are passed as BUILD SECRETS (never baked into the image).
set -euo pipefail

: "${DOCKERHUB_USER:?set DOCKERHUB_USER (your lowercase Docker Hub username)}"
: "${HF_TOKEN:?set HF_TOKEN (HuggingFace token, for gated FLUX.2)}"
: "${CIVITAI_TOKEN:=}"                       # optional (only needed for CivitAI models)

IMAGE="${IMAGE:-$DOCKERHUB_USER/image-workshop-baked:latest}"

echo "== building $IMAGE =="
DOCKER_BUILDKIT=1 docker buildx build \
    --secret id=hf_token,env=HF_TOKEN \
    --secret id=civitai_token,env=CIVITAI_TOKEN \
    -t "$IMAGE" \
    --push \
    .

echo "== done: pushed $IMAGE =="
