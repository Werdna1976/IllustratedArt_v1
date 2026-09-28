"""Prepare delivered level art for the game (spec §7; M3 plan Task 4).

usage: python tools/art/import_art.py <levels_dir> [--force]
(normally run through tools/import_art.sh, which also makes maps, checks and imports)

For every section folder with art: slices plates (and their _n/_emit maps) into <=2048 px strips
in <section>/_strips/, copies fg_*.png props, writes Godot .import files (BC7 + mipmaps; normal-map
flag for _n), a manifest.json the game reads, and traces gameplay_solid.png (white = solid) into
collision_traced.json. Unchanged sections are skipped. Returns/prints the number imported.
"""
import argparse
import json
import os
import re
import shutil
import sys

import numpy as np
from PIL import Image

STRIP_MAX = 2048
CELL = 10
LAYERS = ["sky", "far", "mid", "near", "gameplay", "mid_loop", "near_loop", "fg_loop"]
IMPORT_TEMPLATE = """[remap]

importer="texture"
type="CompressedTexture2D"

[params]

compress/mode=2
compress/high_quality=true
compress/normal_map={normal}
mipmaps/generate=true
"""


def _sources(section):
    return [os.path.join(section, f) for f in os.listdir(section)
            if f.endswith(".png") or f in ("section.json", "gameplay_collision.json")]


def _is_section(path):
    return os.path.isdir(path) and os.path.basename(path) != "_strips" and any(
        f.endswith(".png") for f in os.listdir(path))


def _write_png(img, path):
    img.save(path)
    normal = 1 if re.search(r"_n(_\d+)?$", os.path.splitext(path)[0]) else 0  # layer_n_03 or fg_prop_n
    with open(path + ".import", "w", newline="\n") as f:
        f.write(IMPORT_TEMPLATE.format(normal=normal))


def _slice(section, strips, layer):
    img = Image.open(os.path.join(section, layer + ".png")).convert("RGBA")
    widths = [min(STRIP_MAX, img.width - x) for x in range(0, img.width, STRIP_MAX)]
    entry = {"widths": widths, "height": img.height, "has_n": False, "has_emit": False}
    for suffix in ("", "_n", "_emit"):
        src = os.path.join(section, layer + suffix + ".png")
        if not os.path.exists(src):
            continue
        comp = Image.open(src).convert("RGBA")
        if comp.size != img.size:
            print(f"FAIL {src}: size differs from {layer}.png, skipped")
            continue
        x = 0
        for i, w in enumerate(widths):
            _write_png(comp.crop((x, 0, x + w, img.height)), os.path.join(strips, f"{layer}{suffix}_{i:02d}.png"))
            x += w
        if suffix:
            entry["has" + suffix] = True
    return entry


def trace_solid(mask, size):
    """White areas of a mask -> [x, y, w, h] rects in plate px (10 px cells, merged)."""
    m = np.asarray(mask.convert("L").resize(size, Image.NEAREST)) > 127
    rows, cols = size[1] // CELL, size[0] // CELL
    cells = m[:rows * CELL, :cols * CELL].reshape(rows, CELL, cols, CELL).mean(axis=(1, 3)) > 0.5
    open_rects = {}  # (x, w) -> [x, y, w, h] still growing downwards
    done = []
    for r in range(rows):
        runs, c = set(), 0
        while c < cols:
            if cells[r, c]:
                start = c
                while c < cols and cells[r, c]:
                    c += 1
                runs.add((start, c - start))
            c += 1
        for key in list(open_rects):
            if key not in runs:
                done.append(open_rects.pop(key))
        for x, w in runs:
            if (x, w) in open_rects:
                open_rects[(x, w)][3] += CELL
            else:
                open_rects[(x, w)] = [x * CELL, r * CELL, w * CELL, CELL]
    done.extend(open_rects.values())
    return sorted(done, key=lambda rc: (rc[1], rc[0]))


def import_section(section):
    strips = os.path.join(section, "_strips")
    if os.path.isdir(strips):
        shutil.rmtree(strips)
    os.makedirs(strips)
    manifest = {"props": []}
    for layer in LAYERS:
        if os.path.exists(os.path.join(section, layer + ".png")):
            manifest[layer] = _slice(section, strips, layer)
    for f in sorted(os.listdir(section)):
        if f.startswith("fg_") and f.endswith(".png") and not f.startswith("fg_loop") \
                and not f.endswith(("_n.png", "_emit.png")):
            for suffix in ("", "_n", "_emit"):
                src = os.path.join(section, f[:-4] + suffix + ".png")
                if os.path.exists(src):
                    _write_png(Image.open(src).convert("RGBA"), os.path.join(strips, os.path.basename(src)))
            manifest["props"].append(f)
    solid = os.path.join(section, "gameplay_solid.png")
    if os.path.exists(solid):
        plate = os.path.join(section, "gameplay.png")
        size = Image.open(plate).size if os.path.exists(plate) else Image.open(solid).size
        with open(os.path.join(strips, "collision_traced.json"), "w") as f:
            json.dump(trace_solid(Image.open(solid), size), f)
    with open(os.path.join(strips, "manifest.json"), "w") as f:
        json.dump(manifest, f, indent=1)
    with open(os.path.join(strips, "stamp.json"), "w") as f:
        json.dump({"sources": len(_sources(section))}, f)


def _up_to_date(section):
    stamp = os.path.join(section, "_strips", "stamp.json")
    if not os.path.exists(stamp):
        return False
    t = os.path.getmtime(stamp)
    return all(os.path.getmtime(s) < t for s in _sources(section))


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument("levels_dir")
    ap.add_argument("--force", action="store_true")
    args = ap.parse_args(argv)
    count = 0
    for name in sorted(os.listdir(args.levels_dir)):
        section = os.path.join(args.levels_dir, name)
        if not _is_section(section):
            continue
        if not args.force and _up_to_date(section):
            print(f"up to date {section}")
            continue
        import_section(section)
        count += 1
        print(f"imported {section}")
    print(f"{count} sections imported")
    return count


if __name__ == "__main__":
    main(sys.argv[1:])
