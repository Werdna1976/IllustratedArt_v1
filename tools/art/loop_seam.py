"""Help make and verify seamless horizontal loops (the *_loop.png plates).

usage:
  python tools/art/loop_seam.py wrap <png>           -> <stem>_wrapped.png, shifted half a width so
                                                        the seam sits in the middle; inpaint it there
  python tools/art/loop_seam.py unwrap <png> -o OUT  -> shifts a wrapped file back
  python tools/art/loop_seam.py check <png>          -> OK / FAIL: compares the right->left edge jump
                                                        with ordinary column-to-column change
"""
import argparse
import os
import sys

import numpy as np
from PIL import Image

SEAM_FACTOR = 3.0  # an edge jump this many times the average column change reads as a seam
SEAM_FLOOR = 8.0   # ...but differences below this (0-255 levels) are never a seam


def _shift(path, out):
    a = np.asarray(Image.open(path).convert("RGBA"))
    Image.fromarray(np.roll(a, -(a.shape[1] // 2), axis=1)).save(out)
    print("wrote", out)


def seam_score(path):
    a = np.asarray(Image.open(path).convert("RGBA"), np.float32)
    seam = np.abs(a[:, -1] - a[:, 0]).mean()
    typical = np.abs(np.diff(a, axis=1)).mean()
    return seam, typical


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", choices=["wrap", "unwrap", "check"])
    ap.add_argument("png")
    ap.add_argument("-o", "--out")
    args = ap.parse_args(argv)
    if args.cmd == "wrap":
        _shift(args.png, args.out or os.path.splitext(args.png)[0] + "_wrapped.png")
    elif args.cmd == "unwrap":
        a = np.asarray(Image.open(args.png).convert("RGBA"))
        out = args.out or args.png.replace("_wrapped", "")
        Image.fromarray(np.roll(a, a.shape[1] // 2, axis=1)).save(out)
        print("wrote", out)
    else:
        seam, typical = seam_score(args.png)
        ok = seam <= max(SEAM_FACTOR * typical, SEAM_FLOOR)
        print(f"{'OK' if ok else 'FAIL'} {args.png}: edge jump {seam:.1f}, typical {typical:.1f}")
        return 0 if ok else 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
