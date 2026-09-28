#!/usr/bin/env bash
# One command after dropping level art into art/levels/<section>/:
# slice + manifest + collision trace -> starter maps where missing -> checks -> Godot import.
# usage: bash tools/import_art.sh [levels_dir]
set -uo pipefail
GODOT="${GODOT:-/c/GoDot/Godot_v4.7.2-stable_win64.exe}"
cd "$(dirname "$0")/.."
LEVELS="${1:-art/levels}"
# Normal/glow maps for lit plates: made when missing, remade when older than the colour art
# (new art delivered); maps edited after the colour art are kept as hand-painted.
for f in "$LEVELS"/*/{gameplay,near,mid,mid_loop,near_loop}.png; do
	[[ -f "$f" ]] && python tools/art/make_maps.py "$f" --if-stale | grep -v '^kept' | sed 's/^/maps: /'
done
python tools/art/import_art.py "$LEVELS" | tail -1 | sed 's/^/import: /'
python tools/art/check_art.py "$LEVELS" | grep -E '^FAIL|ok, ' | sed 's/^/check: /'
"$GODOT" --headless --path . --import >/dev/null 2>&1 && echo "godot: imported" || echo "godot: import failed"
