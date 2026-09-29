# Cyberpunk: Ghostline — Player Character Art Brief (v3: dual blades)

*Self-contained brief for generating the playable character's art. Every pixel requirement is here; you don't need the rest of the project.*

> **What's new in v3 (2026-09-28):**
> - **Two blades** (a long special Ghostblade and a short blade) worn in **hip sheaths**. There's no back scabbard any more.
> - **Two-layer grip hands**, so the fingers actually wrap the handles.
> - **Mid-length swept-back hair** as separate moving locks.
> - A **sturdier build**: thick legs, chunky boots, and a bulky plated cybernetic arm.
> - **Keep** the approved face and the current jacket torso design.
> - Use `proportion_reference_v2.webp` for proportions.

## 1. What this art is for

A 2.5D side-scrolling action platformer with hand-painted backgrounds. The character is a **cutout puppet**: every body part is painted **once**, as a separate PNG, and the game animates it by rotating the parts at their joints. There is no frame-by-frame animation and no 3D model.

- Every part must match the others exactly in style, lighting and colour.
- Each part is drawn **once, straight, in a neutral orientation**. The game bends it.
- Joints have **rounded overlapping ends** (about 30 px past the joint) so rotation never shows a gap.

## 2. The character

A disgraced former corporate enforcer turned street fighter in a rain-soaked neon megacity (*Ghost in the Shell* atmosphere). Mid-30s, **compact and powerful**. **Faces right, side view (profile).** The game mirrors it to face left.

- **Face:** keep the approved face (lean, thin cheek scar, focused).
- **Hair:** **mid-length and swept back**, chin-to-collar length, dark. It's painted as a close **hair cap on the head** plus **two separate locks** that swing (see `hair_*` parts).
- **Clothing:** a cropped, high-collar tactical jacket in near-black and charcoal, keeping the current torso design (lime collar lining and piping, yellow shoulder stripe). Heavy dark cargo trousers with knee pads. **Chunky armoured boots** with neon lime soles and toe caps.
- **Right arm, cybernetic (near side):** **bulky and plated**. Gunmetal and brushed steel, visible pistons at the elbow, a thick forearm, and small lime status lights. It must look strong, never thin.
- **Left arm, organic (far side):** jacket sleeve and a gloved hand with lime knuckle plates.
- **Ghostblade (long, left hand):** a slim single-edged long blade about 1.3 m long, gently curved, dark steel with a **bright lime energy edge** and faint circuit etching near the guard. The grip is wrapped in lime and black cord with an angular guard. This is the special blade.
- **Short blade (right, cybernetic hand):** a straight single-edged blade about 0.75 m long in **plain polished steel**, with a black grip wrapped in **yellow** cord and a small square guard. No glow.
- **Sheaths:** a long dark-lacquer sheath for the Ghostblade and a short one for the short blade, both **worn at the hips** on belt hangers. The long sheath hangs on the near (right) hip angled back and down; the short sheath hangs on the far (left) hip. Each hand cross-draws.

**Palette:** base fabric `#141417` `#23252b` `#34373f`; bionic metal `#4a4f58` `#8a9099`; lime accent `#b6ff1a`; warning yellow `#ffd400`; Ghostblade glow `#c8ff3a`. **No pink, magenta, cyan or blue** in the costume.

**Style:** hand-painted illustrated concept art, painterly brush texture, clean readable silhouette. **Key light from the upper left**, a cool bounce from the lower right, and no ground shadow.

## 3. Scale and format (strict)

| Rule | Value |
|---|---|
| Density | **400 pixels per metre**; the full character is **720 px** tall |
| Format | PNG, 8-bit **RGBA**, sRGB, **transparent** background, no shadow |
| Canvas | Each part is its **own PNG** at the exact size below, filling it (≤ 4 px empty border) |
| Near / far | "Near" = the side facing the camera. "Far" parts are the same shapes **~25% darker**. |
| Text / logos | None |

**Proportions (match `proportion_reference_v2.webp`):** at 720 px tall, the head is about 120 px from hair to jaw (roughly 1/6 of the height). The neck is almost hidden by the collar. The chest is 130–140 px front to back, the hips 145 px, the thighs about 90 px thick and the shins about 75 px (with the boot shaft). Boots are about 130 × 70 px, and the legs are about 48% of the height. The overall read is **compact and powerful**, not tall and thin.

## 4. Parts to deliver

Pivot = the joint the part rotates around, in the part's own canvas.

### Body

| File | Canvas W × H | How to draw it | Pivot |
|---|---|---|---|
| `head.png` | 120 × 130 | Approved face in profile, with the **hair as a close cap only** (the locks are separate); short neck stub (~12 px) under the jaw | Neck base, bottom centre |
| `head_attack.png` / `head_hurt.png` | 120 × 130 | Same head: gritted teeth and narrowed eyes / wincing | Bottom centre |
| `hair_upper.png` | 70 × 100 | Upper swept-back lock (from the crown toward the back), **hanging straight down**, rounded top | Top centre (root) |
| `hair_lower.png` | 60 × 90 | Lower lock / tips continuing the upper lock, hanging straight down | Top centre |
| `torso.png` | 150 × 250 | **Keep the current torso design** (jacket, collar, piping, yellow stripe), repainted at this size **without the back-scabbard strap**; belt hangers for both sheaths | Waist, bottom centre |
| `pelvis.png` | 140 × 100 | Hips, belt, cargo-trouser top | Centre |
| `arm_upper_near.png` | 80 × 175 | **Bulky cybernetic** upper arm, plated shoulder cap, hanging down | Shoulder, top centre |
| `arm_lower_near.png` | 72 × 165 | **Bulky cybernetic** forearm with pistons and lime lights, hanging down | Elbow, top centre |
| `arm_upper_far.png` | 70 × 175 | Jacket-sleeve upper arm, 25% darker | Top centre |
| `arm_lower_far.png` | 64 × 165 | Sleeve and cuff forearm, 25% darker | Top centre |
| `thigh_near.png` / `thigh_far.png` | 95 × 215 | Thick thigh in heavy cargo trousers, hanging down | Hip, top centre |
| `shin_near.png` / `shin_far.png` | 80 × 215 | Shin with knee pad and boot shaft | Knee, top centre |
| `foot_near.png` / `foot_far.png` | 130 × 70 | **Chunky armoured boot**: ankle and foot with volume (not paper-thin), toe right, sole flat along the bottom | Ankle, 35 px from the left, 25 px from the top |

### Hands (two layers for grips)

A gripping hand is painted as **two layers**: the **back** (palm and thumb, drawn *behind* the handle) and the **front** (fingers curled *over* the handle). The game puts the handle between them, so the hand really wraps the grip. The handle runs **horizontally through the fist at 32 px from the top**; leave it empty.

| File | Canvas | How to draw it | Pivot |
|---|---|---|---|
| `hand_grip_near_back.png` / `hand_grip_near_front.png` | 72 × 72 | Cybernetic hand gripping (back = palm and thumb, front = metal fingers) | Wrist, top centre |
| `hand_grip_far_back.png` / `hand_grip_far_front.png` | 64 × 64 | Gloved hand gripping (same split) | Wrist, top centre |
| `hand_open_near.png` / `hand_fist_near.png` | 72 × 72 | Cybernetic open hand / fist | Wrist, top centre |
| `hand_open_far.png` / `hand_fist_far.png` | 64 × 64 | Gloved open hand / fist | Wrist, top centre |

### Blades and sheaths (drawn horizontally: pommel or mouth at the left, tip at the right)

| File | Canvas | How to draw it | Pivot |
|---|---|---|---|
| `ghostblade.png` | 520 × 36 | Long special blade: ~100 px grip (lime/black wrap), angular guard at ~x 110, ~400 px curved blade, cutting edge along the bottom | Grip point **60 px from the left**, mid-height |
| `shortblade.png` | 300 × 28 | Short blade: ~75 px grip (black/yellow wrap), square guard at ~x 80, ~210 px straight blade | Grip point **40 px from the left**, mid-height |
| `sheath_long.png` | 470 × 40 | Empty long sheath, dark lacquer, lime band, belt hanger near the mouth | Hanger **70 px from the left**, mid-height |
| `sheath_short.png` | 260 × 34 | Empty short sheath, dark lacquer, yellow band, belt hanger near the mouth | Hanger **50 px from the left**, mid-height |

### Glow masks (same canvas, black except the glowing pixels)

- `ghostblade_emit.png`: the lime energy edge (bright core, soft falloff).
- `arm_upper_near_emit.png`, `arm_lower_near_emit.png`: the lime status lights.
- *Optional:* the boot soles and collar piping, very subtle.

## 5. Consistency checks

- Near/far pairs match in shape, with the far one darker (apart from the cybernetic near arm, which differs by design).
- A standing assembly is about 720 px tall. The head is about 1/6 of the height, the collar hides the neck, and the build reads compact and powerful.
- Grip layers: stacking `…_back`, a handle, then `…_front` looks like a real fist around the handle.
- Hair locks join the head's hair cap seamlessly when hanging straight.

## 6. Deliver

Put all PNGs in one folder, `player_parts_v3/`, plus a `reference_v3.png` (the full character standing with both blades sheathed at the hips, and a second pose in the drawn dual-blade stance). Joint data (`manifest.json` with each part's joint centres) is very welcome, as before.
