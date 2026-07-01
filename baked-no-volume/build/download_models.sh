#!/usr/bin/env bash
# Download every model in models.list into ComfyUI/models/<folder>.
# HF URLs get the HF_TOKEN header; CivitAI URLs get CIVITAI_TOKEN appended.
# Skip-if-exists. One bad line is logged and skipped, never fatal.
set -uo pipefail

LIST="$(dirname "$0")/models.list"
ROOT="/workspace/ComfyUI/models"
fail=0

while IFS='|' read -r folder url fname; do
    folder="$(echo "$folder" | xargs)"
    url="$(echo "$url" | xargs)"
    fname="$(echo "$fname" | xargs)"

    [ -z "$folder" ] && continue           # blank line
    case "$folder" in \#*) continue ;; esac # comment line
    if [ -z "$url" ] || [ -z "$fname" ]; then
        echo "!! bad line (need folder|url|filename): $folder"; continue
    fi

    dir="$ROOT/$folder"; dest="$dir/$fname"; mkdir -p "$dir"
    if [ -s "$dest" ]; then echo "== skip (exists): $folder/$fname"; continue; fi

    hdr=()
    case "$url" in
        *huggingface.co*)
            [ -n "${HF_TOKEN:-}" ] && hdr=(--header="Authorization: Bearer $HF_TOKEN") ;;
        *civitai.com*)
            if [ -n "${CIVITAI_TOKEN:-}" ]; then
                [[ "$url" == *\?* ]] && url="${url}&token=$CIVITAI_TOKEN" \
                                     || url="${url}?token=$CIVITAI_TOKEN"
            fi ;;
    esac

    echo "== download: $folder/$fname"
    if ! aria2c -x16 -s16 -c --auto-file-renaming=false "${hdr[@]}" -d "$dir" -o "$fname" "$url"; then
        echo "!! FAILED: $folder/$fname"; rm -f "$dest"; fail=1
    fi
done < "$LIST"

[ "$fail" -eq 0 ] && echo "== all models OK" || echo "== finished with failures (see !! above)"
exit 0
