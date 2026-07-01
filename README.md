# image-workshop-runpod

Two **completely separate** ways to run the same ComfyUI + Kohya studio on RunPod.
Each lives in its own folder, builds its **own image**, and is used independently.

| Folder | Method | Image | Use it when |
| --- | --- | --- | --- |
| [`baked-no-volume/`](baked-no-volume/) | **A — Baked, no volume** | `image-workshop-baked` | **NOW** (GPU shortage). Everything is inside the image, so it runs on **any GPU in any region** with no network volume. |
| [`thin-with-volume/`](thin-with-volume/) | **B — Thin + volume** | `image-workshop-volume` | **LATER** (shortage over). Small image; models live on a **network volume** you can add/update live with no rebuild. |

> [!NOTE]
> Right now we are building **Method A** (`baked-no-volume/`). Method B is scaffolded and waiting; we'll build it fully when you no longer need to chase GPUs across regions.

## How they differ

| | A — Baked, no volume | B — Thin + volume |
| --- | --- | --- |
| Image size | large (~80–120 GB) | small (~15–20 GB) |
| Where models live | **inside the image** | on a **network volume** |
| Network volume needed? | **No** | Yes |
| Runs on any region/GPU? | **Yes** | Only the volume's region |
| Add/change a model | edit list → **rebuild image** | add **live**, no rebuild |
| First deploy on a fresh host | slower (big pull) | fast pull + 0 download once volume is filled |

Both run on every current GPU (RTX 5090, RTX Pro 6000, H100, H200, A100, 4090) — built on CUDA 12.8 / PyTorch cu128.

## Full documentation

Beginner guides (English + Farsi) and the design spec are in the Obsidian vault under `_Assets/Runpod/`:
`RunPod-Image-Workshop-Guide-EN.md` · `RunPod-Image-Workshop-Guide-FA.md` · `RunPod-Image-Workshop-Spec.md`
