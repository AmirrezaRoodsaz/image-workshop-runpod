#!/usr/bin/env bash
# Install every custom node listed in nodes.list into ComfyUI/custom_nodes.
# For each repo: git clone, then pip install its requirements.txt if it has one.
# One bad node is logged and skipped, not fatal.
set -uo pipefail

LIST="$(dirname "$0")/nodes.list"
DEST="/workspace/ComfyUI/custom_nodes"
mkdir -p "$DEST"

fail=0
while IFS= read -r url; do
    url="${url%%#*}"                       # strip inline comments
    url="$(echo "$url" | xargs)"           # trim whitespace
    [ -z "$url" ] && continue              # skip blank/comment lines

    name="$(basename "$url" .git)"
    if [ -d "$DEST/$name" ]; then
        echo "== skip (exists): $name"
        continue
    fi

    echo "== clone: $name"
    if ! git clone --depth 1 "$url" "$DEST/$name"; then
        echo "!! FAILED clone: $url"; fail=1; continue
    fi
    if [ -f "$DEST/$name/requirements.txt" ]; then
        python3.11 -m pip install -r "$DEST/$name/requirements.txt" \
            || { echo "!! FAILED pip: $name"; fail=1; }
    fi
done < "$LIST"

[ "$fail" -eq 0 ] && echo "== all nodes OK" || echo "== finished with some failures (see !! above)"
exit 0   # never abort the image build over a single bad node
