"""Generate the placeholder fighter parts sheet (spec §5.6, art guide §4).

usage: python tools/art/make_placeholder_fighter.py <out_dir>

Writes parts.png (2048x2048, 400 px/m, transparent), parts.json ({name: [x, y, w, h]}) and
the _n/_emit companion maps. Deterministic, so re-running produces identical files.
"""
import json
import os
import sys

import numpy as np
from PIL import Image

import make_maps

SHEET = 2048
PAD = 32
FAR_DARKEN = 0.75

# name: (w, h, rgb) at 400 px/m. "_near/_far" pairs are generated from the base entries below.
BASE = {
    "head": (90, 110, (196, 158, 128)),
    "torso": (110, 230, (38, 72, 84)),
    "pelvis": (100, 90, (34, 40, 52)),
    "blade": (400, 24, (150, 160, 170)),
    "glint": (40, 40, (255, 40, 40)),
}
PAIRED = {
    "arm_upper": (50, 130, (104, 116, 138)),
    "arm_lower": (45, 120, (104, 116, 138)),
    "hand": (45, 45, (196, 158, 128)),
    "thigh": (60, 170, (46, 46, 62)),
    "shin": (50, 170, (46, 46, 62)),
    "foot": (90, 40, (26, 26, 32)),
}


def part_specs():
    specs = dict(BASE)
    for name, (w, h, rgb) in PAIRED.items():
        specs[name + "_near"] = (w, h, rgb)
        specs[name + "_far"] = (w, h, tuple(int(c * FAR_DARKEN) for c in rgb))
    return specs


def draw_part(name, w, h, rgb):
    """Rounded rectangle lit from the upper left; blade gets a glowing cyan edge, glint a red star."""
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    shade = 1.15 - 0.35 * ((xx / max(w - 1, 1) + yy / max(h - 1, 1)) * 0.5)
    img = np.zeros((h, w, 4), np.float32)
    img[..., :3] = np.clip(np.array(rgb, np.float32)[None, None, :] * shade[..., None], 0, 255)
    r = min(w, h) * 0.35
    cx = np.clip(xx, r, w - 1 - r)
    cy = np.clip(yy, r, h - 1 - r)
    inside = (xx - cx) ** 2 + (yy - cy) ** 2 <= r * r
    img[..., 3] = np.where(inside, 255, 0)
    if name == "blade":
        img[: h // 3, 60:, :3] = (40, 255, 255)  # energy edge (bright, saturated -> glows)
        img[:, :60, :3] = (30, 30, 36)  # hilt
    if name == "glint":
        star = (np.abs(xx - w / 2) < 3) | (np.abs(yy - h / 2) < 3)
        img[..., :3] = (255, 30, 30)
        img[..., 3] = np.where(star | inside & ((xx - w / 2) ** 2 + (yy - h / 2) ** 2 < 36), 255, 0)
    return Image.fromarray(img.astype(np.uint8), "RGBA")


def pack(specs):
    """Shelf-pack parts (tallest first) with PAD spacing. Returns {name: [x, y, w, h]}."""
    rects, x, y, shelf_h = {}, PAD, PAD, 0
    for name in sorted(specs, key=lambda n: (-specs[n][1], n)):
        w, h, _ = specs[name]
        if x + w + PAD > SHEET:
            x, y, shelf_h = PAD, y + shelf_h + PAD, 0
        rects[name] = [x, y, w, h]
        x += w + PAD
        shelf_h = max(shelf_h, h)
    assert y + shelf_h + PAD <= SHEET, "parts do not fit the sheet"
    return rects


def main(argv):
    out = argv[0]
    os.makedirs(out, exist_ok=True)
    specs = part_specs()
    rects = pack(specs)
    sheet = Image.new("RGBA", (SHEET, SHEET), (0, 0, 0, 0))
    for name, (x, y, w, h) in rects.items():
        sheet.paste(draw_part(name, *specs[name]), (x, y))
    path = os.path.join(out, "parts.png")
    sheet.save(path)
    with open(os.path.join(out, "parts.json"), "w") as f:
        json.dump(rects, f, indent=1, sort_keys=True)
    make_maps.main([path, "--force"])
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
