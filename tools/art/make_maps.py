"""Generate starter companion maps for a colour PNG.

usage: python tools/art/make_maps.py <png> [--strength 2.0] [--glow 0.8] [--force]

Writes <stem>_n.png (normal map, OpenGL/+Y-up as Godot expects) and <stem>_emit.png
(glow mask from bright, saturated pixels) next to the input. An existing map is kept
unless --force, so hand-painted masks are never lost.
"""
import argparse
import os
import sys

import numpy as np
from PIL import Image


def _box_blur(a):
    p = np.pad(a, 1, mode="edge")
    return sum(p[y:y + a.shape[0], x:x + a.shape[1]] for y in range(3) for x in range(3)) / 9.0


def make_normal(img, strength=2.0):
    a = np.asarray(img.convert("RGBA"), dtype=np.float32) / 255.0
    lum = _box_blur(a[..., 0] * 0.299 + a[..., 1] * 0.587 + a[..., 2] * 0.114)
    dy, dx = np.gradient(lum)
    n = np.stack([-dx * strength, dy * strength, np.ones_like(lum)], axis=-1)
    n /= np.linalg.norm(n, axis=-1, keepdims=True)
    rgb = np.round((n * 0.5 + 0.5) * 255.0)
    rgb[a[..., 3] == 0] = (128, 128, 255)
    out = np.dstack([rgb, a[..., 3] * 255.0]).astype(np.uint8)
    return Image.fromarray(out, "RGBA")


def _smoothstep(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def make_emissive(img, threshold=0.8):
    a = np.asarray(img.convert("RGBA"), dtype=np.float32) / 255.0
    rgb = a[..., :3]
    mx, mn = rgb.max(axis=-1), rgb.min(axis=-1)
    sat = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1e-6), 0.0)
    mask = _smoothstep(threshold - 0.1, threshold + 0.1, mx) * _smoothstep(0.35, 0.6, sat)
    out = np.dstack([rgb * mask[..., None], a[..., 3]]) * 255.0
    return Image.fromarray(np.round(out).astype(np.uint8), "RGBA")


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument("png")
    ap.add_argument("--strength", type=float, default=2.0)
    ap.add_argument("--glow", type=float, default=0.8)
    ap.add_argument("--force", action="store_true")
    args = ap.parse_args(argv)
    img = Image.open(args.png)
    stem = os.path.splitext(args.png)[0]
    for suffix, make in (("_n", lambda: make_normal(img, args.strength)), ("_emit", lambda: make_emissive(img, args.glow))):
        path = stem + suffix + ".png"
        if os.path.exists(path) and not args.force:
            print("kept", path)
            continue
        make().save(path)
        print("wrote", path)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
