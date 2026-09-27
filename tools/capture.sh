#!/usr/bin/env bash
# Runs the main scene in a window at WxH and saves the rendered frame after N frames
# (via the DebugCapture autoload), then quits. Fixed 60 fps so runs are repeatable.
# usage: tools/capture.sh <name> <WxH> <frames> [user args, e.g. --spawn-x=67 --autorun]
# Output: .godot/captures/<name>.png (git-ignored). Prints the path and any script errors.
set -euo pipefail
GODOT="${GODOT:-/c/GoDot/Godot_v4.7.2-stable_win64.exe}"
cd "$(dirname "$0")/.."
NAME=$1; RES=$2; FRAMES=$3; shift 3
OUT=.godot/captures
mkdir -p "$OUT"; rm -f "$OUT/$NAME.png"
"$GODOT" --path . --resolution "$RES" --fixed-fps 60 -- --capture="res://$OUT/$NAME.png" --capture-frames="$FRAMES" "$@" >"$OUT/$NAME.log" 2>&1
grep -E 'SCRIPT ERROR|^ERROR' "$OUT/$NAME.log" | sort -u | head -5 || true
[[ -f "$OUT/$NAME.png" ]] && echo "$OUT/$NAME.png" || { echo "capture failed; see $OUT/$NAME.log"; exit 1; }
