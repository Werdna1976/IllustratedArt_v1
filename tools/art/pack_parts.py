"""Pack a character's part PNGs into the sheet the game's cutout rig uses.

usage: python tools/art/pack_parts.py <parts_dir> <char_dir>

Reads <parts_dir>/<part>.png (+ optional <part>_emit.png glow masks and a manifest.json with
joint data) and writes to <char_dir>:
  parts.png / parts_emit.png  2048x2048 sheets (glow is black where a part has no mask)
  parts_n.png                 normal map (via make_maps, only when stale)
  parts.json                  {part: [x, y, w, h]}
  pivots.json                 {part: {"pivot": [x, y], "distal": [x, y] | null}} in part-canvas px
Prints OK/WARN per part (missing, size differs from the brief); returns the number of warnings.
"""
import json
import os
import sys

from PIL import Image

import make_maps

SHEET = 2048
PAD = 16
LIMBS = ("arm_upper", "arm_lower", "thigh", "shin")

# docs/art/player-character-brief.md §4 (+ optional glint for enemies' attack tell)
BRIEF = {
    "head": (90, 110), "head_attack": (90, 110), "head_hurt": (90, 110),
    "torso": (110, 230), "pelvis": (100, 90),
    "arm_upper_near": (50, 130), "arm_lower_near": (45, 120), "arm_upper_far": (50, 130), "arm_lower_far": (45, 120),
    "hand_open_near": (45, 45), "hand_open_far": (45, 45), "hand_fist_near": (45, 45), "hand_fist_far": (45, 45),
    "hand_grip_near": (45, 45), "hand_grip_far": (45, 45),
    "thigh_near": (60, 170), "thigh_far": (60, 170), "shin_near": (50, 170), "shin_far": (50, 170),
    "foot_near": (90, 40), "foot_far": (90, 40), "katana": (440, 32), "saya": (440, 32),
}
OPTIONAL = {"glint": (40, 40)}


def default_pivot(name, w, h):
    """Brief pivots when the delivery has no joint data."""
    if name.startswith(LIMBS):
        return {"pivot": [w / 2, 25], "distal": [w / 2, h - 25]}
    if name.startswith("head"):
        return {"pivot": [w / 2, h - 4], "distal": None}
    if name == "torso":
        return {"pivot": [w / 2, h - 12], "distal": None}
    if name.startswith("hand"):
        return {"pivot": [w / 2, 8], "distal": None}
    if name.startswith("foot"):
        return {"pivot": [25, h / 2], "distal": None}
    if name == "katana":
        return {"pivot": [105, h / 2], "distal": None}
    if name == "saya":
        return {"pivot": [120, h / 2], "distal": None}
    return {"pivot": [w / 2, h / 2], "distal": None}


def shelf_pack(sizes):
    rects, x, y, shelf = {}, PAD, PAD, 0
    for name in sorted(sizes, key=lambda n: (-sizes[n][1], n)):
        w, h = sizes[name]
        if x + w + PAD > SHEET:
            x, y, shelf = PAD, y + shelf + PAD, 0
        rects[name] = [x, y, w, h]
        x += w + PAD
        shelf = max(shelf, h)
    if y + shelf + PAD > SHEET:
        raise ValueError("parts do not fit a 2048x2048 sheet")
    return rects


def main(argv):
    src, out = argv[0], argv[1]
    os.makedirs(out, exist_ok=True)
    manifest = {}
    if os.path.exists(os.path.join(src, "manifest.json")):
        manifest = json.load(open(os.path.join(src, "manifest.json"))).get("assets", {})
    warnings = 0
    images = {}
    for name, size in {**BRIEF, **OPTIONAL}.items():
        path = os.path.join(src, name + ".png")
        if not os.path.exists(path):
            if name in BRIEF:
                print(f"WARN {name}: missing")
                warnings += 1
            continue
        img = Image.open(path).convert("RGBA")
        if img.size != size:
            print(f"WARN {name}: {img.width}x{img.height}, brief says {size[0]}x{size[1]}")
            warnings += 1
        else:
            print(f"OK {name}")
        images[name] = img
    rects = shelf_pack({n: im.size for n, im in images.items()})
    sheet = Image.new("RGBA", (SHEET, SHEET), (0, 0, 0, 0))
    emit = Image.new("RGBA", (SHEET, SHEET), (0, 0, 0, 0))
    pivots = {}
    for name, img in images.items():
        x, y, w, h = rects[name]
        sheet.paste(img, (x, y))
        emit.paste(Image.new("RGBA", img.size, (0, 0, 0, 255)), (x, y), img)  # black, alpha-shaped
        mask = os.path.join(src, name + "_emit.png")
        if os.path.exists(mask):
            emit.paste(Image.open(mask).convert("RGBA"), (x, y))
        joint = manifest.get(name + ".png", {})
        if "recommended_joint_center" in joint:
            pivots[name] = {"pivot": joint["recommended_joint_center"], "distal": joint.get("distal_joint_center")}
        else:
            pivots[name] = default_pivot(name, w, h)
    sheet.save(os.path.join(out, "parts.png"))
    emit.save(os.path.join(out, "parts_emit.png"))
    json.dump(rects, open(os.path.join(out, "parts.json"), "w"), indent=1, sort_keys=True)
    json.dump(pivots, open(os.path.join(out, "pivots.json"), "w"), indent=1, sort_keys=True)
    make_maps.main([os.path.join(out, "parts.png"), "--if-stale"])
    print(f"{len(images)} parts packed, {warnings} warnings")
    return warnings


if __name__ == "__main__":
    main(sys.argv[1:])
