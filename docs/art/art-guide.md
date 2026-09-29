# Ghostline Art Guide — sizes, prompts, delivery

For generating art in external AI tools (Midjourney for distant scenery; GPT-image or Stable Diffusion / Flux for near-ground plates and characters). Numbers come from the technical spec (`docs/superpowers/specs/2026-09-27-illustrated-platformer-design.md` §4, §5.6); if they ever disagree, the spec wins.

## 1. Quick reference

| Asset | Recommended tool | Final size (px) | Transparent? | Companion maps | File |
|---|---|---|---|---|---|
| Sky | Midjourney | 3,392 × 1,280 | No | — | `art/levels/<lvl>/sky.png` |
| Far background | Midjourney | 4,800 × 1,344 | Top edge: yes | `_emit` if lit windows/signs | `far.png` |
| Mid background | Midjourney → cutout | 6,784 × 1,408 | Yes (above skyline) | `_emit` | `mid.png` |
| Near background | GPT-image / SD-Flux | 10,816 × 1,600 | Yes | `_n`, `_emit` | `near.png` |
| Gameplay plate | GPT-image / SD-Flux | 14,784 × 1,792 | Yes | `_n`, `_emit` | `gameplay.png` |
| Foreground props | GPT-image / SD-Flux | per prop, 167 px/m (e.g. 1.2 × 9 m post ≈ 200 × 1,500) | Yes | `_emit` | `fg_<name>.png` |
| Character parts sheet | GPT-image / SD-Flux | 2,048 × 2,048 (bosses 4,096²) at **400 px/m** | Yes | `_n`, `_emit` | `art/characters/<name>/parts.png` |

Plate sizes above are for the **default horizontal section** (134.4 × 16.2 m, 7 screens). Other section shapes (vertical climbs, arenas, train loops) get their own sizes from the same formula — ask for a size table per section when a level is planned.

**You only need to make the colour art.** `tools/art/make_maps.py` generates starter `_n` (normal) and `_emit` (glow) maps from it; paint over the glow mask when you want exact control.

## 2. Scenery plates

### How big things are on a plate
Every layer has its own density (pixels per metre). Use it to size things so scale reads correctly:

| Layer | px per metre | A 3 m door is… | A 30 m building is… |
|---|---|---|---|
| Gameplay | 100 | 300 px tall | 3,000 px (taller than the plate — crop) |
| Near | 67 | 200 px | 2,000 px |
| Mid | 33 | 100 px | 1,000 px |
| Far | 17 | 50 px | 500 px |

The player is 1.8 m ≈ **180 px** tall on the gameplay plate. Walkable floor sits in the bottom ~10% of the gameplay plate.

### Making a very wide plate
No tool outputs 14,784 px directly. Build plates from panels:
1. Generate a **key panel** that sets the look (Midjourney `--ar 21:9` or `--ar 3:1`).
2. Extend sideways with **pan / outpaint** (Midjourney *Pan ←/→*, GPT-image edit "extend the scene to the right", SD outpainting) until the width covers the plate at the target height. Keep the horizon line at the same height across panels.
3. Upscale (2×, or 4× for gameplay/near) so the **height reaches the final plate height**, then scale to the exact size in the table.
4. Hide seams with a 256 px overlap blend or a paint-over.

### Style rules for every plate
- **Key light from the upper left** (about 45°) on every layer and character, so the lit parts match.
- **Farther means lower contrast and saturation.** The game adds fog on top, so fade layers only moderately.
- No text, logos, UI, watermarks or characters baked into plates. Neon signs use invented glyphs.
- Transparent layers: the sky must show through above the silhouettes. Leave the area above the skyline **empty (alpha 0)**, not painted as sky.
- Gameplay plate: painted ground and platforms must line up with where collision will be. Paint **backdrop and architecture**, not the walkable surfaces themselves; walkable platforms are separate pieces added later.

## 3. Prompt templates

### Shared style block (paste into every prompt)
> hand-painted illustrated concept art, cyberpunk megacity, Ghost in the Shell atmosphere, painterly brush texture, clean readable shapes, cinematic lighting, key light from upper left, side-on orthographic view, flat 2D background layer for a side-scrolling game

### Level palette line (pick the level's line)
| Levels | Palette line |
|---|---|
| 1–2 | dark cramped underground, saturated magenta and cyan neon, wet reflections, steam, low ceilings |
| 3–4 | industrial orange furnace glow against steel blue, massive machinery, motion, rain |
| 5 | cool blue, flooded, reflective water, fog, quiet abandoned |
| 6 | bright clean warm white and gold, glass, gardens, unnaturally perfect |
| 7 | deep navy night, white lightning, storm clouds, vast vertical scale, aviation lights |
| 8 | luminous cyan white and gold, holographic, surreal architecture |

### Midjourney (sky, far, mid)
```
<shared style block>, <palette line>, <layer description> --ar 3:1 --style raw --no text, letters, logo, people, characters, frame, border
```
- Layer descriptions: sky: *"sky only, clouds and city glow on the horizon, no buildings"*. Far: *"distant skyline silhouettes, hazy, low detail"*. Mid: *"mid-distance city blocks, simplified detail, atmospheric haze"*.
- Lock the look across a level with **`--sref <url of the level's key panel>`** and keep the same `--seed` while panning.
- Midjourney cannot output transparency: for **far/mid**, generate against a flat sky colour, then cut the skyline out (remove.bg, Photoshop *Select Sky*, or SD rembg), leaving alpha above it.

### GPT-image (near, gameplay, props, characters)
```
<shared style block>, <palette line>. <layer or part description>. Transparent background. No text, no logos, no characters.
```
- Ask for a **transparent background** explicitly; ask for landscape (1536×1024) for plates and square (1024×1024) for part sheets.
- Keep one conversation per level so it keeps the style; upload the level's key panel as a reference image.

### Stable Diffusion / Flux (near, gameplay, props, characters)
- Positive: `<shared style block>, <palette line>, <description>`. Negative: `text, logo, watermark, frame, people, photo, 3d render, blurry`.
- **ControlNet lineart/depth** from a rough sketch to control layout; **IP-Adapter** with the level key panel for style.
- For characters, train or use a **character LoRA** once the design is final, so every part stays consistent.
- Remove backgrounds with rembg if the model cannot output alpha.

## 4. Characters — parts sheets

### Step 1: reference sheet
Generate a full-body **side view, facing right**, neutral stance, **arms and legs slightly apart from the body** so no limb overlaps the torso. Prompt:
> full-body character reference, side view facing right, neutral standing pose, arms slightly away from body, legs slightly apart, <character description>, <shared style block>, plain transparent background

Player description: *disgraced street fighter, lean, dark tactical streetwear with worn cybernetic arm, short cropped hair, carries an experimental katana-like blade with a cyan energy edge*.

### Step 2: parts sheet
Cut the reference into parts (or prompt a tool to lay out a sheet from the reference). Rules:
- **Canvas 2,048 × 2,048, transparent.** Scale so the full character would be **720 px tall** (400 px/m × 1.8 m).
- **One part per island, at least 32 px transparent padding** between parts.
- **Overlap joints:** each limb part extends ~20–30 px past the joint, rounded, so rotation never shows a gap.
- Paint the **far-side** arm and leg a little darker (they sit behind the body).
- Hands: provide **open**, **fist** and **grip (holding blade)** versions. Face: **neutral**, **attack** and **hurt** versions.
- The **blade** is a separate part, drawn horizontally, with the hilt at the left.

```
+-------------------------------------------------+  2048 x 2048, 400 px/m
| head_neutral  head_attack  head_hurt            |
| torso            pelvis                         |
| arm_upper_near   arm_lower_near   hand_open/fist/grip (near)  |
| arm_upper_far    arm_lower_far    hand_*_far    |
| thigh_near  shin_near  foot_near                |
| thigh_far   shin_far   foot_far                 |
| blade (horizontal, hilt left) ................. |
| fx_slash_arc (optional, white on transparent)   |
+-------------------------------------------------+
```

Approximate part heights at 400 px/m for a 1.8 m fighter: head ≈ 110 px, torso ≈ 230 px, pelvis ≈ 90 px, upper arm ≈ 130 px, forearm ≈ 120 px, thigh ≈ 170 px, shin ≈ 170 px, blade ≈ 400 px long.

**Worked example:** the player (`docs/art/player-character-brief.md`): 23 part PNGs → `python tools/art/pack_parts.py <parts_dir> art/characters/player` → `tools/make_rig.gd` → `scenes/characters/player_rig.tscn` (open it in the 2D editor to see pivots, layering and animations). The officer placeholder (`tools/art/make_placeholder_character.py`) goes through the same steps.

### Step 3: glow and normals
- **Glow (`_emit`):** anything self-lit (blade edge, cybernetic lights, visor) in its own colour on black; everything else black. `make_maps.py` makes a starter mask from bright saturated pixels.
- **Normal (`_n`):** generated by `make_maps.py`; no need to paint.

## 5. Assembly tools (turn small generations into full plates)

| Tool | Use it for |
|---|---|
| `python tools/art/stitch.py p1.png p2.png … --overlap 200 --layer gameplay -o art/levels/l1_station/gameplay.png` | Panel chains: joins outpainted panels left→right with a feathered overlap (px at the first panel's height), then scales to the exact plate size (`--layer` reads `sizes.json`; or `--size WxH`). Build at half size and let it upscale, or upscale first for more detail. |
| `python tools/art/compose_plate.py layout.json -o art/levels/l1_station/gameplay.png` | Modular kits: tiles a base strip (e.g. a tiled wall) across the plate and places kit pieces at pixel positions (`scale`, `flip`). `"loop": true` wraps pieces across the edges for `_loop` plates. Pieces marked `"walkable": true` are exported to `gameplay_collision.json`, which becomes collision. Format is in the script's header. |
| `python tools/art/loop_seam.py wrap near_loop.png` → inpaint the middle → `loop_seam.py unwrap near_loop_wrapped.png -o near_loop.png` → `loop_seam.py check near_loop.png` | Seamless loops: moves the seam to the centre for inpainting, moves it back, then checks the edges match (OK/FAIL). |

## 6. Delivery & checks

- **Levels:** after dropping art into `art/levels/<section>/`, run `bash tools/import_art.sh` — maps, slicing, collision tracing, checks and Godot import in one step.

- Put files at the paths in §1 and run `python tools/art/check_art.py art/` — one line per file: OK, or what's wrong (size, missing alpha, missing companion map).
- PNG, 8-bit RGBA, sRGB. Don't pre-compress; the importer (M3) makes BC7 strips.
- Keep your source panels and prompts in `art/_source/<lvl>/` (git-ignored for now) so any plate can be regenerated.
