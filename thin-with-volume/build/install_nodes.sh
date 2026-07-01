#!/usr/bin/env bash
# Install every custom node in nodes.list into ComfyUI/custom_nodes.
# Uses $PYTHON if set, else python3 (works on any base template).
set -uo pipefail

LIST="$(dirname "$0")/nodes.list"
DEST="${WORKSPACE:-/workspace}/ComfyUI/custom_nodes"
PY="${PYTHON:-python3}"
mkdir -p "$DEST"

fail=0
while IFS= read -r url; do
    url="${url%%#*}"; url="$(echo "$url" | xargs)"
    [ -z "$url" ] && continue
    name="$(basename "$url" .git)"
    if [ -d "$DEST/$name" ]; then echo "== skip (exists): $name"; continue; fi
    echo "== clone: $name"
    if ! git clone --depth 1 "$url" "$DEST/$name"; then
        echo "!! FAILED clone: $url"; fail=1; continue
    fi
    [ -f "$DEST/$name/requirements.txt" ] && \
        $PY -m pip install -r "$DEST/$name/requirements.txt" || { echo "!! pip issue: $name"; fail=1; }
done < "$LIST"

[ "$fail" -eq 0 ] && echo "== all nodes OK" || echo "== finished with some failures (see !! above)"
exit 0
