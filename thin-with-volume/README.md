# Method B — Thin image + network volume (`image-workshop-volume`)

**Use this later, when the GPU shortage is over.** The image is small (code + nodes + tooling only). Models live on a **RunPod network volume**, so you add/update them **live, with no rebuild**.

> [!NOTE]
> **Scaffold only for now.** We finish this method after Method A, once you no longer need to chase GPUs across regions. The files here are placeholders.

## How it works

- Image contains ComfyUI + custom nodes + Kohya + tooling — **no models**.
- On first boot, `provisioning.sh` downloads the models in [`build/models.list`](build/models.list) onto the **volume mounted at `/workspace`** (skip-if-exists, so later boots are instant).
- Add more models any time with ComfyUI-Manager's Model Manager or the web downloader — they persist on the volume, no rebuild.

## Target

- **GPU:** any current NVIDIA — but only in the **datacenter where your volume lives**.
- **Base:** CUDA 12.8 · Python 3.11 · PyTorch cu128
- **Image:** Docker Hub, **private** — `<dockerhub-user>/image-workshop-volume`
- **Volume:** create a RunPod network volume (e.g. 200 GB) in a datacenter that stocks the GPUs you want.

## The trade-off

You're tied to **one datacenter's GPU stock** (the volume's region). In exchange you get a tiny image, instant boots once the volume is filled, and live model/node changes with no rebuilds.

## The two files you edit

| File | Edit to… |
| --- | --- |
| [`build/nodes.list`](build/nodes.list) | add/remove custom nodes (still baked into the thin image) |
| [`build/models.list`](build/models.list) | models downloaded **to the volume** on first boot |

## Ports

8188 ComfyUI · 7860 Kohya SS · 8080 FileBrowser · 8888 JupyterLab · 7777 code-server · 22 SSH

## Secrets

Tokens are needed at **runtime** here (the pod downloads models to the volume on first boot), so set `HF_TOKEN` / `CIVITAI_TOKEN` as env vars on the RunPod Template (not baked into the image). `WEB_PASSWORD` gates the web services.
