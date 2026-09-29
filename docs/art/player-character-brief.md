# Cyberpunk: Ghostline — Player Art Production Spec (v4)

*Production art for the playable character: body parts, turn views, weapons, sheaths and trail effects. It's self-contained, so you can hand it to an image tool as-is. The moves these assets serve are specified in `player-moveset-spec.md`. The visual language is locked by the v5 attack studies (`art/_source/player/opus_attack_handoff_v5/`: `WEAPON_LOCK.png`, `HORIZONTAL_COMBO.png`, `ACROBATIC_COMBO.png`).*

## 1. How the character is animated (read first)

The character is a **cutout puppet**: each body part is one painted PNG, and the game rotates the parts at their joints. On top of that, this spec uses a **hybrid turn system**:

- **Side view (profile)** parts do most of the work: stances, runs, and grounded and airborne horizontal cuts.
- **Turn views:** the head, hair, torso and pelvis also come in **3/4-front** and **3/4-back** versions. The game swaps them in on turn beats (spins, back-side slashes, tucked air turns), the way it swaps between an open hand and a fist.
- **Arms change sides during a turn.** In a back-side beat the cybernetic arm passes behind the body. So **every arm and hand part comes in a NEAR (lit) and a FAR (≈25% darker) version**, and the game swaps shading and layer order.
- There are **no full-pose painted frames**. Every study pose must be reachable by rotating these parts plus the view swaps.

## 2. Character look (unchanged except where noted)

- **Build:** compact and powerful. The approved face, thin cheek scar and focused expression stay.
- **Hair (updated to match the studies):** **long, swept-back dark hair** reaching the shoulder blades. It's painted as a close hair cap on the head plus **three hanging locks** (upper, mid, tips) that swing with movement.
- **Clothing:**
  - **Jacket:** a charcoal high-collar tactical jacket with **full sleeves**, lime collar lining and piping, and a yellow diagonal chest stripe.
  - **Trousers and boots:** heavy cargo trousers with knee pads, and chunky armoured boots with lime soles and toe caps.
- **Right arm:** a **bulky plated cybernetic arm** in gunmetal and brushed steel, with pistons and small lime status lights. It must read strong.
- **Left arm:** the organic jacket sleeve with a gloved hand and lime knuckle plates.
- **Palette:** base `#141417` `#23252b` `#34373f`; metal `#4a4f58` `#8a9099`; lime `#b6ff1a`; yellow `#ffd400`; Ghostblade edge `#c8ff3a`. No pink, magenta, cyan or blue.
- **Style:** hand-painted, painterly, crisp silhouettes. **Key light from the upper left.** No ground shadow.

## 3. Global format rules

| Rule | Value |
|---|---|
| Scale | **400 px per metre**; the character is **720 px** tall standing |
| Files | PNG, 8-bit RGBA, sRGB, transparent background, no shadow, no text |
| Canvas | Each part is its own PNG at the **exact** size below, filling it (≤ 4 px empty border) |
| Orientation | Body parts upright or hanging straight down. Weapons and sheaths horizontal, pommel or mouth at the left. **Side-view parts face right.** |
| Joints | Limb ends are rounded and extend **~30 px past the joint**, so rotation never gaps |
| NEAR / FAR | FAR = the same shape ≈25% darker (RGB × 0.75) |
| Joint data | Include `manifest.json` with each part's joint centres, as in earlier deliveries |

## 4. Body parts: side view

| File | Canvas W×H | Content | Pivot |
|---|---|---|---|
| `head.png` | 120 × 130 | Face in profile facing right, **hair cap only**, short neck stub | Neck base, bottom centre |
| `head_attack.png`, `head_hurt.png` | 120 × 130 | Gritted and focused / wincing | Bottom centre |
| `hair_upper.png` | 80 × 120 | Upper swept-back lock, hanging down, rounded root | Top centre |
| `hair_mid.png` | 70 × 110 | Middle lock | Top centre |
| `hair_tips.png` | 60 × 100 | Tapering tips | Top centre |
| `torso.png` | 150 × 250 | Jacket torso in profile (collar, stripe, piping, belt hangers for both sheaths) | Waist, bottom centre |
| `pelvis.png` | 140 × 100 | Hips, belt, cargo top | Centre |
| `thigh_near.png` / `thigh_far.png` | 95 × 215 | Thick cargo thigh, hanging down | Hip, top centre |
| `shin_near.png` / `shin_far.png` | 80 × 215 | Shin, knee pad, boot shaft | Knee, top centre |
| `foot_near.png` / `foot_far.png` | 130 × 70 | Chunky boot, toe right, sole flat along the bottom | Ankle (35, 25) |

## 5. Turn views (hybrid)

Same scale and lighting. These are swapped in for the torso, pelvis, head and hair on turn beats.

| File | Canvas W×H | Content | Pivot |
|---|---|---|---|
| `head_front34.png` | 120 × 130 | Head turned **3/4 toward the camera** (both eyes visible), hair cap | Bottom centre |
| `head_back34.png` | 120 × 130 | Head turned **3/4 away** (back of the head, ear, jaw line), hair cap | Bottom centre |
| `torso_front34.png` | 170 × 250 | Jacket from the front 3/4: both lapels and the full chest stripe | Bottom centre |
| `torso_back34.png` | 165 × 250 | Jacket from the back 3/4: shoulder blades, back seam | Bottom centre |
| `pelvis_front34.png` / `pelvis_back34.png` | 150 × 100 | Hips from the front 3/4 / back 3/4 | Centre |
| `hair_upper_back34.png` / `hair_mid_back34.png` / `hair_tips_back34.png` | as the side locks | Hair locks seen from behind (fuller spread) | Top centre |

## 6. Arms and hands (near and far versions of each)

| File | Canvas W×H | Content | Pivot |
|---|---|---|---|
| `arm_cyber_upper_near.png` / `_far.png` | 80 × 175 | Bulky plated cybernetic upper arm, hanging down | Shoulder, top centre |
| `arm_cyber_lower_near.png` / `_far.png` | 72 × 165 | Cybernetic forearm with pistons and lights | Elbow, top centre |
| `arm_org_upper_near.png` / `_far.png` | 70 × 175 | Jacket-sleeve upper arm | Top centre |
| `arm_org_lower_near.png` / `_far.png` | 64 × 165 | Sleeve and cuff forearm | Top centre |

**Hands use a three-layer grip stack:** `…_grip_back` (palm and thumb) → **handle** → `…_grip_front` (fingers curled over the handle). The handle runs **horizontally through the fist, 36 px from the top**; leave that channel empty in both layers.

| File | Canvas | Content | Pivot |
|---|---|---|---|
| `hand_cyber_grip_back_{near,far}.png` / `hand_cyber_grip_front_{near,far}.png` | 72 × 72 | Metal hand gripping (back / front layers) | Wrist, top centre |
| `hand_org_grip_back_{near,far}.png` / `hand_org_grip_front_{near,far}.png` | 64 × 64 | Gloved hand gripping (back / front layers) | Wrist, top centre |
| `hand_cyber_open_{near,far}.png`, `hand_cyber_fist_{near,far}.png` | 72 × 72 | Metal open hand / fist | Top centre |
| `hand_org_open_{near,far}.png`, `hand_org_fist_{near,far}.png` | 64 × 64 | Gloved open hand / fist | Top centre |

## 7. Weapons (locked by `WEAPON_LOCK.png`)

Both blades are **rigid and straight**: never bent, bowed, wavy or curved like a saber. Both are held **one-handed**: the Ghostblade in the **left (organic)** hand, the steel sword in the **right (cybernetic)** hand.

| File | Canvas W×H | Overall length | Content | Pivot (grip point) |
|---|---|---|---|---|
| `ghostblade.png` | 600 × 56 | **572 px** (1.43 m) | Long, narrow, **dark-steel** blade, straight spine, needle taper in the last ~12%, blade ≈ 13 px thick. Black/lime grip ~76 px, angular guard ~40 px tall at ~91 px from the pommel end. A **razor-thin lime line on the lower cutting edge only**. | (64, 28) |
| `ghostblade_emit.png` | 600 × 56 | — | Glow mask: only the lime edge line (bright core, soft 2–3 px falloff) | — |
| `steelblade.png` | 480 × 52 | **450 px** (1.13 m, ~79%) | Substantial straight **polished-steel** blade ≈ 12 px thick, black/yellow grip ~76 px, square guard ~36 px tall at ~90 px from the pommel. **No glow.** | (64, 26) |
| `sheath_ghost.png` | 520 × 40 | 490 px | Empty sheath for the Ghostblade, dark lacquer, thin lime band, belt hanger near the mouth (left) | Hanger (60, 20) |
| `sheath_steel.png` | 420 × 40 | 390 px | Empty sheath for the steel sword, dark lacquer, yellow band, hanger near the mouth | Hanger (55, 20) |

The weapon canvases have 14 px of margin at each end. The **Ghostblade sheath** hangs on the **right (near) hip** and the **steel sheath** on the **left (far) hip**, both angled back and down, and each blade is cross-drawn. There's no back scabbard.

## 8. Trail and effect textures (runtime)

Trails are **separate from the blades**. The game draws them as ribbons that follow each blade's path during the active frames (see the moveset spec, §6). You supply the textures:

| File | Canvas | Content |
|---|---|---|
| `trail_ghost.png` | 512 × 64 | Horizontal translucent lime band: a bright thin core line along the centre with a soft edge falloff. **Left = old (transparent), right = newest (bright).** Faint scan-line breakup. |
| `trail_steel.png` | 512 × 32 | Thin white-silver streak, same left→right fade, with a crisp core |
| `fx_data_fragments.png` | 128 × 32 | 4 frames (32 × 32 each) of **square lime "data" fragments** (1–3 small squares per frame) for the Ghostblade trail to shed as it dissipates |
| `fx_hit_spark_steel.png` / `fx_hit_spark_ghost.png` | 256 × 64 | 4 frames (64 × 64) of an impact spark: white-steel / lime with pixel shards |

## 9. Draw order (back → front, side view facing right)

`hair locks` → `FAR arm chain (upper, lower, grip_back, WEAPON, grip_front)` → `FAR leg` → `sheath_steel` → `pelvis` → `torso` → `head` → `NEAR leg` → `sheath_ghost` → `NEAR arm chain (upper, lower, grip_back, WEAPON, grip_front)`

On back-side turn beats the game swaps which arm chain is near or far. Artists don't need to do anything for that beyond supplying both shadings.

## 10. Delivery checklist

- [ ] Side view: `head`, `head_attack`, `head_hurt`, 3 hair locks, torso, pelvis, legs (near and far).
- [ ] Turn views: head, torso and pelvis in front-3/4 and back-3/4, plus 3 back-view hair locks.
- [ ] Arms: 4 arm segments × near/far (8 files).
- [ ] Hands: grip back and front plus open and fist, cyber and organic × near/far (16 files).
- [ ] Weapons: `ghostblade.png` + `ghostblade_emit.png`, `steelblade.png`, both sheaths.
- [ ] Effects: `trail_ghost.png`, `trail_steel.png`, `fx_data_fragments.png`, two hit sparks.
- [ ] `manifest.json` (joint centres) and `reference_v4.png` (sheathed stance + drawn stance, 720 px tall).
- [ ] Deliver in one folder: `player_parts_v4/`.

No hitbox or collision data is expected with the art. Hitboxes are defined per move in the moveset spec.
