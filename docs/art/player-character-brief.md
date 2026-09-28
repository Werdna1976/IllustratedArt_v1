# Cyberpunk: Ghostline — Player Character Art Brief

*Self-contained brief for generating the playable character's art. Every pixel requirement is here; you don't need the rest of the project.*

## 1. What this art is for

A 2.5D side-scrolling action platformer with hand-painted backgrounds. The main character is a **cutout puppet**: the body is painted **once**, as separate parts (head, torso, arm and leg segments, hands, katana), and the game animates it by rotating those parts at the joints, like a paper-doll or shadow puppet. There is **no frame-by-frame animation** and **no 3D model**.

That means:
- Every part must match the others exactly in style, lighting and colour, because they're shown together in every pose.
- Each part is drawn **once, straight, in a neutral orientation** (limbs hanging straight down). The game bends it.
- Joints need **rounded overlapping ends** so no gap shows when a limb rotates.

## 2. The character

**Who:** a disgraced former corporate enforcer turned street fighter, in a rain-soaked neon megacity (*Ghost in the Shell* atmosphere). Lean, athletic, mid-30s, alert and weary. Adult, gender-neutral presentation is fine; keep the silhouette readable.

**Fighting style:** a **two-handed katana** fighter. Most attacks use **both hands on the grip**: the near hand just behind the guard, the far hand near the pommel. Poses should feel grounded and disciplined (kendo and iaido influence), with occasional one-handed flourishes.

**Look:**
- **Base clothing, mostly dark:** a fitted short tactical jacket with a high collar, slim cargo trousers and armoured boots, in **charcoal, near-black and dark graphite**. These dark fabrics make up most of the silhouette.
- **Neon contrast accents:** **acid lime-green** and **warning yellow**, chosen to pop against the pink and blue neon of the first level. Use them sparingly and deliberately:
  - collar lining and a thin piping line down the jacket front and sleeves
  - one bold shoulder panel or a diagonal chest stripe
  - glove knuckle plates and finger tips
  - boot soles, toe caps and laces
  - the katana's grip wrap
  - small status lights on the bionics
- **Bionics, metallic:** the **right arm is a cybernetic prosthetic** in worn gunmetal and brushed steel with dark joint seams and a few **small lime-green status lights** at the shoulder and forearm. Natural metal tones, not painted neon. The left arm is a normal jacket sleeve with a gloved hand.
- **Head:** short cropped dark hair, a lean face and a thin scar on one cheek. An optional small lime-green earpiece light is fine.
- **The katana:** slim, gently curved blade in polished steel, a dark round guard (*tsuba*), and a long two-hand grip wrapped in **lime-green and black cord**. A **glowing neon lime-green energy edge** runs along the cutting edge. This glow is the character's signature.

**Palette (for reference; exact hues can vary slightly):**

| Role | Colour | Hex |
|---|---|---|
| Base fabric | Near-black / charcoal / graphite | `#141417`, `#23252b`, `#34373f` |
| Bionic metal | Gunmetal, brushed steel highlights | `#4a4f58`, `#8a9099` |
| Accent 1 | Acid lime-green (neon) | `#b6ff1a` |
| Accent 2 | Warning yellow | `#ffd400` |
| Blade glow | Neon lime-green | `#c8ff3a` |
| Skin | Natural, lit from the upper left | (any natural tone) |

Avoid pink, magenta, cyan and bright blue in the costume: those are the background's colours.

**Style:** hand-painted illustrated concept art, painterly brush texture, clean readable shapes, cinematic. **Key light from the upper left**, a soft cool bounce from below right, and no cast shadow on the ground.

**The character faces right.** Everything is drawn in **side view (profile) facing right**. The game mirrors it to face left.

## 3. Scale and format (strict)

| Rule | Value |
|---|---|
| Density | **400 pixels per metre** |
| Full character height | **720 px** (1.8 m), feet to top of hair |
| File format | PNG, 8-bit **RGBA**, sRGB |
| Background | **Transparent** (alpha 0) around every part: no floor, no shadow, no backdrop |
| Canvas | Each part is its **own PNG** at the exact canvas size in §4 |
| Margins | The part fills its canvas as described; no extra empty border beyond ~4 px |
| Text / logos | None anywhere |

## 4. Parts to deliver

"Near" parts are on the side facing the camera. "Far" parts are behind the body: draw them the same way but **about 25% darker**, as they're in shadow. Because the katana is held two-handed, **the far arm is fully visible in most poses**, so give it the same care as the near arm. The **pivot** is the joint the part rotates around, measured from the part's own canvas.

| File | Canvas W × H (px) | How to draw it | Pivot (joint) |
|---|---|---|---|
| `head.png` | 90 × 110 | Head and neck in profile facing right, focused neutral expression | Base of the neck, **bottom centre** |
| `head_attack.png` | 90 × 110 | Same head, teeth gritted, eyes narrowed | Bottom centre |
| `head_hurt.png` | 90 × 110 | Same head, wincing | Bottom centre |
| `torso.png` | 110 × 230 | Chest and belly, jacket with neon collar lining and piping, standing upright | Waist, **bottom centre** (the neck joins at top centre) |
| `pelvis.png` | 100 × 90 | Hips and belt (optional small yellow buckle), trouser top | **Centre** |
| `arm_upper_near.png` | 50 × 130 | **Cybernetic** upper arm, hanging straight down | Shoulder, **top centre** (elbow at bottom centre) |
| `arm_lower_near.png` | 45 × 120 | **Cybernetic** forearm with lime status lights, hanging straight down | Elbow, **top centre** (wrist at bottom centre) |
| `arm_upper_far.png` | 50 × 130 | Upper arm in jacket sleeve with neon piping, hanging down, 25% darker | Top centre |
| `arm_lower_far.png` | 45 × 120 | Forearm, sleeve and cuff, hanging down, 25% darker | Top centre |
| `hand_open_near.png` / `hand_open_far.png` | 45 × 45 | Relaxed open hand, fingers down. Near = cybernetic hand, far = gloved hand with neon knuckle plates. | Wrist, **top centre** |
| `hand_fist_near.png` / `hand_fist_far.png` | 45 × 45 | Clenched fist (same near/far split) | Top centre |
| `hand_grip_near.png` / `hand_grip_far.png` | 45 × 45 | Hand closed around a katana grip, shown from the side. The grip itself is **not** drawn; leave a hollow channel running horizontally through the fist. | Top centre |
| `thigh_near.png` / `thigh_far.png` | 60 × 170 | Thigh in dark cargo trousers, hanging straight down | Hip, **top centre** (knee at bottom centre) |
| `shin_near.png` / `shin_far.png` | 50 × 170 | Shin and armoured boot upper, straight down | Knee, **top centre** (ankle at bottom centre) |
| `foot_near.png` / `foot_far.png` | 90 × 40 | Armoured boot with neon sole and toe cap, toe pointing **right**, sole flat along the bottom edge | Ankle, **25 px from the left edge, mid-height** |
| `katana.png` | 440 × 32 | The whole katana **horizontal, pommel at the left, tip at the right**, gentle upward curve toward the tip, cutting edge along the **bottom**. Layout left→right: pommel cap, **two-hand grip ~120 px long** (lime/black cord wrap), round guard at ~x 125, blade ~300 px to the tip. | **Near-hand grip point: 105 px from the left edge, mid-height** (just behind the guard). The far hand holds at **~35 px from the left**. |
| `saya.png` *(optional)* | 440 × 32 | Empty scabbard, same orientation, dark lacquer with a thin yellow band | 105 px from the left, mid-height |

**Joint overlap:** each limb segment's ends are **rounded** and extend **20–30 px past the joint** inside its canvas. For example, the upper arm's top 25 px is a rounded shoulder cap and its bottom 25 px a rounded elbow cap. Then when parts rotate they overlap instead of showing a gap. The canvas sizes above already include this overlap.

**Consistency checks before delivering:**
- Hold each near/far pair side by side. They should be the same shape, with the far one only darker (apart from the cybernetic near arm and hand, which differ by design).
- Line the parts up in a standing pose, as in the diagram below. The joints should meet and the total height should be about 720 px.
- The neon accents are visible, but the silhouette still reads as mostly dark.

```
            [head]            (neck on top of torso)
           [torso]            (arms hang from the top corners of the torso)
  [arm_upper] [pelvis]        (legs hang from the pelvis)
  [arm_lower] [thigh]
   [hand]     [shin]
              [foot] →        (toes point right)
  two-handed guard: both [hand_grip] parts on the katana grip, ~70 px apart
```

## 5. Glow masks (recommended)

Anything that emits light gets a matching **glow mask**: the same filename with `_emit`, the same canvas size, **black everywhere except the glowing pixels** in their glow colour. Deliver:
- `katana_emit.png`: the lime-green energy edge (a bright core with a soft falloff).
- `arm_upper_near_emit.png` and `arm_lower_near_emit.png`: the lime status lights.
- *Optional:* `torso_emit.png`, `foot_near_emit.png`, `foot_far_emit.png` if the neon piping or soles should glow faintly. Keep this subtle; the accents should read mainly as bright *fabric*, not lights.

If you skip these, the game generates rough ones automatically from bright saturated pixels.

## 6. Recommended workflow

1. **Reference sheet first:** one full-body side view, facing right, standing in a relaxed **two-handed guard** (katana held diagonally forward, both hands on the grip) **and** a second neutral pose with arms slightly away from the body, **720 px tall on a transparent background**. Get this approved before cutting parts. It locks the design and colours.
2. **Cut or repaint each part** from the reference to the canvas sizes and orientations in §4. Limbs are straightened to hang down, with joints rounded and extended for overlap. The katana is painted separately, straight and horizontal.
3. **Make the variants** (near/far darkness, hands, heads) from the same base, so they match exactly.
4. **Deliver** all PNGs in one folder named `player_parts/`.

### Prompt for the reference sheet (adapt as needed)
> Character reference sheet for a 2D side-scrolling game cutout rig, two poses side by side, both side view (profile) facing right: (1) relaxed two-handed katana guard, blade angled forward, both hands on the long grip; (2) neutral standing pose, arms slightly away from the body, legs slightly apart, katana sheathed at the hip. A disgraced former corporate enforcer turned street fighter: lean, athletic, mid-30s; fitted short tactical jacket with high collar in near-black and charcoal, slim dark cargo trousers, armoured boots; sparing neon accents in acid lime-green and warning yellow (collar lining, piping, shoulder panel, glove knuckles, boot soles); right arm is a worn gunmetal and brushed-steel cybernetic prosthetic with small lime-green status lights; short cropped dark hair, thin cheek scar. Slim curved katana, polished steel, dark round guard, long grip wrapped in lime-green and black cord, glowing neon lime-green energy edge. No pink, magenta, cyan or blue in the costume. Hand-painted illustrated concept art, painterly brush texture, clean readable silhouette, cinematic, key light from upper left, cool bounce light from lower right. Transparent background, no ground shadow, no text, no logo.

### Prompt for a part (repeat per part)
> From the approved character reference, paint ONLY the [PART, e.g. "near-side cybernetic upper arm"] as a separate cutout-animation part: drawn straight [ORIENTATION, e.g. "hanging vertically, shoulder at the top, elbow at the bottom"], rounded overlapping ends at both joints, same painterly style, lighting (key light upper left), colours and neon accents as the reference. Exact canvas [W × H] px, the part filling the canvas, transparent background, no shadow, no text.

### Prompt for the katana
> From the approved character reference, paint ONLY the katana as a separate game part: perfectly horizontal side view, pommel at the left, tip at the right, gentle upward curve toward the tip, cutting edge along the bottom; long two-hand grip (about 120 of 440 px) wrapped in lime-green and black cord, dark round guard at about 125 px from the left, polished steel blade with a glowing neon lime-green energy edge. Exact canvas 440 × 32 px, transparent background, no hands, no shadow, no text.

## 7. Delivery checklist

- [ ] 1 reference sheet (`reference.png`: two-handed guard plus neutral pose, 720 px tall, facing right).
- [ ] 22 part PNGs with the exact names and canvas sizes in §4: 3 heads, torso, pelvis, 4 arm segments, 6 hands, 4 leg segments, 2 feet, katana. Plus optional `saya.png`.
- [ ] Glow masks: `katana_emit.png`, `arm_upper_near_emit.png`, `arm_lower_near_emit.png` (others optional).
- [ ] All RGBA with transparent backgrounds, facing right, lit from the upper left, far parts about 25% darker.
- [ ] Mostly dark costume with lime-green and yellow neon accents; no pink or cyan in the costume.
- [ ] Joints overlap (rounded ends); a standing assembly is about 720 px tall.
