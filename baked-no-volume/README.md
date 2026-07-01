# Method A — Baked, no volume (`image-workshop-baked`)

**Use this now, during the GPU shortage.** Everything is baked *inside* the image, so it runs on **any GPU in any region** with **no network volume** — maximum freedom to grab whatever GPU is available.

> [!NOTE]
> Being built step by step. Right now: skeleton + manifests. The `Dockerfile`, `scripts/`, `supervisor/` files come next.

## What's inside the image

- ComfyUI + ComfyUI-Manager + the custom nodes in [`build/nodes.list`](build/nodes.list)
- The models in [`build/models.list`](build/models.list) — **downloaded at build time and baked in**
- Kohya SS, FileBrowser, JupyterLab, code-server, SSH

## Target

- **GPU:** any current NVIDIA (RTX 5090, RTX Pro 6000, H100, H200, A100, 4090)
- **Base:** CUDA 12.8 · Python 3.11 · PyTorch cu128
- **Image:** Docker Hub, **private** — `<dockerhub-user>/image-workshop-baked`

## The trade-off (important)

Because models are baked in, **changing a model or node means rebuilding the image** (~100 GB). For quick experiments instead, use ComfyUI-Manager's Model Manager / Install Custom Nodes *live* on a running pod — but those live changes are **lost when the pod is terminated** (no volume here). Promote keepers into the lists and rebuild occasionally.

## The two files you edit

| File | Edit to… |
| --- | --- |
| [`build/nodes.list`](build/nodes.list) | add/remove ComfyUI custom nodes |
| [`build/models.list`](build/models.list) | add/remove models that get **baked in** |

Edit → `git commit` → `git push` → rebuild → deploy a fresh pod.

## Ports

8188 ComfyUI · 7860 Kohya SS · 8080 FileBrowser · 8888 JupyterLab · 7777 code-server · 22 SSH

## Build (summary)

Build on a cheap RunPod **CPU pod** (~200 GB disk), not on your Mac:

```bash
git clone https://github.com/AmirrezaRoodsaz/image-workshop-runpod.git
cd image-workshop-runpod/baked-no-volume
export HF_TOKEN=...  CIVITAI_TOKEN=...  DOCKERHUB_USER=...
docker login -u "$DOCKERHUB_USER"
bash build-on-runpod.sh      # (added in a later step)
```

## Secrets

Tokens are **build-time only** (used on the build pod to download the models that get baked in; never committed, never in the image layers). Copy `.env.example` → `.env`. `WEB_PASSWORD` is set at runtime on the RunPod Template.
