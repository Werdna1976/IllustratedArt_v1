"""Validate delivered art against the art guide.

usage: python tools/art/check_art.py <dir>

Prints `OK <path>` or `FAIL <path>: <reasons>` per colour PNG (companion _n/_emit maps are
checked alongside their colour file), then `N ok, M failed`. Exit code 1 on any failure.
"""
import json
import os
import sys

import numpy as np
from PIL import Image

CHAR_SIZES = {(2048, 2048), (4096, 4096)}
NEEDS_NORMAL = {"gameplay", "near"}


def _has_transparency(img):
    if img.mode != "RGBA":
        return False
    return int(np.asarray(img)[..., 3].min()) < 255


def _companions(path, size, required):
    errs = []
    stem = os.path.splitext(path)[0]
    for suffix in ("_n", "_emit"):
        comp = stem + suffix + ".png"
        if os.path.exists(comp):
            if Image.open(comp).size != size:
                errs.append(f"{suffix} map size differs from colour map")
        elif suffix in required:
            errs.append(f"missing {suffix} map")
    return errs


def check_file(path):
    img = Image.open(path)
    name = os.path.splitext(os.path.basename(path))[0]
    errs = []
    if name == "parts":
        if img.size not in CHAR_SIZES:
            errs.append(f"size {img.size[0]}x{img.size[1]}, expected 2048x2048 or 4096x4096")
        if not _has_transparency(img):
            errs.append("needs RGBA with transparent background")
        errs += _companions(path, img.size, {"_n", "_emit"})
        return errs
    if name != "sky" and not _has_transparency(img):
        errs.append("needs RGBA with transparency above the silhouette")
    sizes_path = os.path.join(os.path.dirname(path), "sizes.json")
    if os.path.exists(sizes_path):
        sizes = json.load(open(sizes_path))
        if name in sizes and list(img.size) != list(sizes[name]):
            w, h = sizes[name]
            errs.append(f"size {img.size[0]}x{img.size[1]}, expected {w}x{h}")
    errs += _companions(path, img.size, {"_n"} if name in NEEDS_NORMAL else set())
    return errs


def main(argv):
    ok = failed = 0
    for root, _dirs, files in os.walk(argv[0]):
        if {"_source", "_strips"} & set(root.split(os.sep)):
            continue  # raw sources and generated strips are not deliveries
        for f in sorted(files):
            if not f.endswith(".png") or f.endswith(("_n.png", "_emit.png", "_solid.png")):
                continue
            path = os.path.join(root, f)
            errs = check_file(path)
            if errs:
                failed += 1
                print(f"FAIL {path}: {'; '.join(errs)}")
            else:
                ok += 1
                print(f"OK {path}")
    print(f"{ok} ok, {failed} failed")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
