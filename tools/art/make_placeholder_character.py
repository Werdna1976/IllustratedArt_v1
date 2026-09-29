"""Generate placeholder character parts in the standard 23-part layout (+ glint), as individual
PNGs ready for pack_parts.py — the same path real art takes.

usage: python tools/art/make_placeholder_character.py <parts_dir> [--palette officer|player]

Parts are flat-shaded rounded shapes lit from the upper left; far parts are 25% darker.
Officer: navy uniform, dark helmet with a red visor, stun baton in the weapon slot, red glint.
"""
import argparse
import os
import sys

import numpy as np
from PIL import Image

import pack_parts

FAR_DARKEN = 0.75
PALETTES = {
    "officer": {"skin": (176, 140, 118), "helmet": (40, 44, 54), "uniform": (29, 42, 68), "trousers": (24, 30, 46),
                "boot": (18, 18, 22), "metal": (70, 76, 88), "weapon": (36, 36, 40), "light": (255, 40, 40)},
    "player": {"skin": (196, 158, 128), "helmet": (30, 28, 26), "uniform": (32, 34, 40), "trousers": (28, 30, 36),
               "boot": (20, 20, 24), "metal": (120, 126, 136), "weapon": (170, 176, 184), "light": (200, 255, 58)},
}


def role(name):
    base = name.replace("_near", "").replace("_far", "")
    return {"head": "skin", "head_attack": "skin", "head_hurt": "skin", "torso": "uniform", "pelvis": "trousers",
            "arm_upper": "uniform", "arm_lower": "uniform", "thigh": "trousers", "shin": "trousers", "foot": "boot",
            "hand_open": "skin", "hand_fist": "skin", "hand_grip": "skin", "katana": "weapon", "saya": "metal",
            "glint": "light"}[base]


def shape(w, h, rgb, radius_frac=0.35):
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    shade = 1.15 - 0.35 * ((xx / max(w - 1, 1) + yy / max(h - 1, 1)) * 0.5)
    img = np.zeros((h, w, 4), np.float32)
    img[..., :3] = np.clip(np.array(rgb, np.float32)[None, None, :] * shade[..., None], 0, 255)
    r = min(w, h) * radius_frac
    cx, cy = np.clip(xx, r + 4, w - 5 - r), np.clip(yy, r + 4, h - 5 - r)
    img[..., 3] = np.where((xx - cx) ** 2 + (yy - cy) ** 2 <= r * r, 255, 0)
    return img


def draw(name, size, pal):
    w, h = size
    img = shape(w, h, pal[role(name)])
    if name.startswith("head"):
        img[4:h // 3, :, :3] = pal["helmet"]  # helmet / hair cap
        img[h // 3:h // 3 + 10, w // 2:, :3] = pal["light"] if name != "head_hurt" else (90, 20, 20)  # visor
    if name == "katana":
        img[..., 3] = 0
        img[10:22, 4:264, :3], img[10:22, 4:264, 3] = pal["weapon"], 255  # baton / blade body
        img[10:22, 250:264, :3] = pal["light"]  # tip
    if name == "glint":
        yy, xx = np.mgrid[0:h, 0:w]
        star = (np.abs(xx - w / 2) < 3) | (np.abs(yy - h / 2) < 3)
        img[..., :3], img[..., 3] = pal["light"], np.where(star, 255, 0)
    if name.endswith("_far"):
        img[..., :3] *= FAR_DARKEN
    return Image.fromarray(img.astype(np.uint8), "RGBA")


def glow_mask(img, pal, region=None):
    a = np.asarray(img).copy()
    light = np.all(a[..., :3] == np.array(pal["light"]), axis=-1) & (a[..., 3] > 0)
    out = np.zeros_like(a)
    out[..., 3] = 255
    out[light, :3] = pal["light"]
    return Image.fromarray(out, "RGBA")


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument("parts_dir")
    ap.add_argument("--palette", default="officer", choices=sorted(PALETTES))
    args = ap.parse_args(argv)
    pal = PALETTES[args.palette]
    os.makedirs(args.parts_dir, exist_ok=True)
    for name, size in {**pack_parts.BRIEF, **pack_parts.OPTIONAL}.items():
        img = draw(name, size, pal)
        img.save(os.path.join(args.parts_dir, name + ".png"))
        if name in ("katana", "glint"):
            glow_mask(img, pal).save(os.path.join(args.parts_dir, name + "_emit.png"))
    print(f"wrote {len(pack_parts.BRIEF) + len(pack_parts.OPTIONAL)} parts to {args.parts_dir}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
