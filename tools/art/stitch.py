"""Join overlapping panels left-to-right into one plate, then scale to the exact plate size.

usage: python tools/art/stitch.py <panel1> <panel2> ... [--overlap PX] [--size WxH | --layer NAME] -o OUT

Panels are first scaled to the first panel's height; neighbours overlap by --overlap px
(measured at that height) and are blended with a linear feather. --layer reads the size
from sizes.json next to OUT (e.g. --layer gameplay).
"""
import argparse
import json
import os
import sys

import numpy as np
from PIL import Image


def stitch(panels, overlap):
    h = panels[0].height
    arrays = [np.asarray(p.convert("RGBA").resize((round(p.width * h / p.height), h), Image.LANCZOS), np.float32)
              for p in panels]
    out = arrays[0]
    for nxt in arrays[1:]:
        o = min(overlap, out.shape[1], nxt.shape[1])
        w = np.linspace(0.0, 1.0, o + 2, dtype=np.float32)[1:-1][None, :, None] if o else None
        seam = out[:, out.shape[1] - o:] * (1.0 - w) + nxt[:, :o] * w if o else np.zeros((h, 0, 4), np.float32)
        out = np.concatenate([out[:, :out.shape[1] - o], seam, nxt[:, o:]], axis=1)
    return Image.fromarray(np.clip(np.round(out), 0, 255).astype(np.uint8), "RGBA")


def target_size(args):
    if args.size:
        w, h = args.size.lower().split("x")
        return int(w), int(h)
    if args.layer:
        sizes = json.load(open(os.path.join(os.path.dirname(os.path.abspath(args.out)), "sizes.json")))
        return tuple(sizes[args.layer])
    return None


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument("panels", nargs="+")
    ap.add_argument("--overlap", type=int, default=0)
    ap.add_argument("--size")
    ap.add_argument("--layer")
    ap.add_argument("-o", "--out", required=True)
    args = ap.parse_args(argv)
    img = stitch([Image.open(p) for p in args.panels], args.overlap)
    size = target_size(args)
    if size:
        img = img.resize(size, Image.LANCZOS)
    img.save(args.out)
    print(f"wrote {args.out} {img.width}x{img.height}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
