"""Assemble a plate from a tileable base strip and kit pieces described in a layout JSON.

usage: python tools/art/compose_plate.py <layout.json> -o OUT.png

layout.json (image paths relative to the layout file; px in final plate pixels):
  {"size": [W, H] | "layer": "gameplay",          # "layer" reads sizes.json next to OUT
   "loop": false,                                 # true: pieces crossing an edge wrap around
   "base": {"image": "wall.png", "y": 900, "scale": 1.0},   # tiled across the full width
   "pieces": [{"image": "crate.png", "x": 1200, "y": 1480, "scale": 1.0,
               "flip": false, "walkable": true}]}
Writes OUT.png and, if any piece is walkable, OUT_collision.json: [[x, y, w, h], ...] of the
walkable pieces' opaque bounds (plate px) — the M3 importer turns these into collision.
"""
import argparse
import json
import os
import sys

from PIL import Image, ImageOps


def _load(base_dir, spec):
    img = Image.open(os.path.join(base_dir, spec["image"])).convert("RGBA")
    scale = spec.get("scale", 1.0)
    if scale != 1.0:
        img = img.resize((round(img.width * scale), round(img.height * scale)), Image.LANCZOS)
    if spec.get("flip"):
        img = ImageOps.mirror(img)
    return img


def compose(layout, base_dir, size):
    w, h = size
    plate = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    if "base" in layout:
        tile = _load(base_dir, layout["base"])
        for x in range(0, w, tile.width):
            plate.alpha_composite(tile, (x, layout["base"].get("y", 0)))
    walkables = []
    for spec in layout.get("pieces", []):
        img = _load(base_dir, spec)
        x, y = spec["x"], spec["y"]
        offsets = [0, -w, w] if layout.get("loop") else [0]
        for dx in offsets:
            _paste(plate, img, x + dx, y)
        if spec.get("walkable"):
            bx0, by0, bx1, by1 = img.getbbox() or (0, 0, 0, 0)
            walkables.append([x + bx0, y + by0, bx1 - bx0, by1 - by0])
    return plate, walkables


def _paste(plate, img, x, y):
    # alpha_composite needs a non-negative destination, so crop pieces that start off-canvas.
    src_x, src_y = max(0, -x), max(0, -y)
    if src_x >= img.width or src_y >= img.height or x >= plate.width or y >= plate.height:
        return
    plate.alpha_composite(img.crop((src_x, src_y, img.width, img.height)), (max(0, x), max(0, y)))


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument("layout")
    ap.add_argument("-o", "--out", required=True)
    args = ap.parse_args(argv)
    layout = json.load(open(args.layout))
    if "size" in layout:
        size = tuple(layout["size"])
    else:
        sizes = json.load(open(os.path.join(os.path.dirname(os.path.abspath(args.out)), "sizes.json")))
        size = tuple(sizes[layout["layer"]])
    plate, walkables = compose(layout, os.path.dirname(os.path.abspath(args.layout)), size)
    plate.save(args.out)
    print(f"wrote {args.out} {size[0]}x{size[1]}")
    if walkables:
        path = os.path.splitext(args.out)[0] + "_collision.json"
        json.dump(walkables, open(path, "w"))
        print(f"wrote {path} ({len(walkables)} walkable)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
