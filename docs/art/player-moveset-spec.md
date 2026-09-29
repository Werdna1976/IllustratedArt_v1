# Cyberpunk: Ghostline — Player Moveset Spec (v1)

*Every player move: IDs, inputs, which study poses each one uses, keyframe timing, flags, hitboxes and trails. The art these moves run on is `player-character-brief.md` (v4). Poses reference the v5 studies: **H01–H08** = `HORIZONTAL_COMBO.png`, **A01–A08** = `ACROBATIC_COMBO.png` (in `art/_source/player/opus_attack_handoff_v5/`).*

## 1. Principles (locked)

- **Rigid blades, edge-led horizontal cuts** at knee, waist and chest height. No jabs, thrusts or overhead chops.
- **Ghostblade (left hand):** long arcs, lime data-ghost trail. **Steel sword (right, cybernetic hand):** fast cuts, thin white trail.
- **Grounded strings** use the simpler H-sheet silhouettes. The **full airborne sequence (A01–A08) is reserved** for the launcher string and the finisher.
- **Body turns are visual.** Back-side and front-side beats swap in turn views (art spec §5). **Facing (left/right) changes only where §4 allows it.**
- **Movement is sheathed.** Combat draws both blades into the stance.

## 2. Inputs

| Action | Keyboard | Gamepad |
|---|---|---|
| Move / jump | A D / Space | Left stick / A |
| Light | J | X |
| Heavy | K | Y |
| Block (hold) / Parry (tap on time) | L | LB |
| Dodge roll | Shift | B |

## 3. Move list

Timing is in seconds: **S** startup / **A** active / **R** recovery. **Hit-stop** is the impact freeze. **Cancel** is the earliest time (from the move's start) the next move in the tree can begin.

### 3.1 Movement and state

| ID | Name | Input | Poses | Timing | Notes |
|---|---|---|---|---|---|
| S_IDLE | Sheathed idle | — | *new pose* | loop 1.6 | Relaxed, left hand resting on the Ghostblade hilt at the hip |
| S_RUN | Sheathed run | move | *new* | loop 0.5 | Arms free, sheaths bounce |
| S_JUMP / S_FALL / LAND | Jump, fall, land | jump | *new* | 0.2 / 0.2 / 0.15 | Hair lifts on jump and settles on landing |
| DRAW | Draw to stance | Light, Heavy or Block while sheathed; or an enemy within **8 m** | S_IDLE → **H01** | 0.22 | Cross-draw both blades. Light during DRAW buffers into **L1 from the draw** (a draw-cut: L1 can start at 0.12). |
| SHEATHE | Sheathe | automatic: **4 s** without attacking, being hit or an enemy within 8 m | H01 → S_IDLE | 0.45 | Any input cancels it back to the stance |
| D_STANCE | Drawn stance | — | **H01** | loop 1.2 | Low coiled guard, blades on different horizontal planes |
| D_RUN | Drawn run | move (drawn) | *new* | loop 0.5 | Low, both blades trailing behind |
| D_JUMP / D_FALL | Drawn air | jump (drawn) | A03-like | 0.2 / 0.2 | Blades held out wide |

### 3.2 Ground light string (Light, Light, Light, Light)

| ID | Name | Poses | S / A / R | Cancel | Blade and height | Damage / stagger | Hit-stop | Hitbox (m: centre x, y · w × h) |
|---|---|---|---|---|---|---|---|---|
| L1 | Ghost Cut | H01 → **H02** | 0.09 / 0.08 / 0.22 | 0.16 | Ghostblade, **waist**, back→front | 10 / 10 | 0.05 | 1.10, 1.00 · 1.80 × 0.50 |
| L2 | Steel Return | **H03** | 0.08 / 0.08 / 0.22 | 0.15 | Steel, **chest**, front→back | 10 / 12 | 0.05 | 0.95, 1.30 · 1.50 × 0.45 |
| L3 | Low Sweep | **H04** | 0.10 / 0.10 / 0.28 | 0.20 | Ghostblade, **knee**, deep duck | 12 / 15 (low hit) | 0.06 | 1.10, 0.45 · 1.90 × 0.45 |
| L4 | Scissor Ender | **H05 → H06 → H07 → H08** | 0.12 / hit 1 0.12–0.18, hit 2 0.28–0.36 / R 0.36–0.72 | — | H05 turn (no hit), H06 **back-side steel at shoulder**, H07 **dual scissor** (Ghostblade waist + steel chest), H08 held finish | 8 + 18 / 10 + 25; hit 2 knocks back 5 m/s | 0.04 / 0.10 | hit 1: 0.95, 1.45 · 1.50 × 0.45; hit 2: 1.05, 1.15 · 1.90 × 0.90 |

### 3.3 Heavy and branches

| ID | Name | Input | Poses | S / A / R | Effect | Hitbox |
|---|---|---|---|---|---|---|
| H1 | Ghost Spin | Heavy (from the stance) | A01 load → **A07** spin | 0.28 / 0.14 / 0.40 | 25 dmg / 35 stagger, **breaks guard**, hits **both sides** | centred: 0.00, 1.00 · 3.60 × 0.70 |
| LAUNCH | Rising Takeoff | Heavy after L1 or L2 | **A01 → A02 → A03** | 0.14 / 0.08 (A02) / player takes off at 0.30 | Low steel cut **launches** the enemy (vy 11); player jumps after it (vy 9) | 0.95, 0.60 · 1.50 × 0.50 |
| AIR1 | Tuck Sweep | Light (air, after LAUNCH) | **A04** | 0.06 / 0.10 / 0.14 | Flat Ghostblade sweep, body horizontal | 1.20, 0.90 · 2.00 × 0.60 |
| AIR2 | Aerial Steel | Light (after AIR1) | **A05** | 0.06 / 0.08 / 0.16 | Back-side steel cut | 0.95, 1.00 · 1.50 × 0.50 |
| AIR_LAND | Landing Sweep | Light or Heavy (after AIR2), or automatically on landing | **A06** | 0.05 / 0.08 / 0.30 | Fast-fall; low steel sweep on touchdown, knocks down | 1.00, 0.40 · 1.70 × 0.40 |
| FINISH | Ghostline Cascade | Heavy near a **staggered** enemy (≤ 2.5 m) | **A01 → A08** (full) | ≈1.65 total | Hits at A02, A04, A05, A06 and A07 (20 each; the last kills or sets up). Brief slow-motion (0.3×) on **A04**. Ends held on **A08** with trails dissolving. | per beat, as the matching moves above |

### 3.4 Defence

| ID | Name | Input | Poses | Timing | Effect |
|---|---|---|---|---|---|
| BLOCK | Crossed Guard | hold Block | *new pose*: blades crossed horizontally in a low X in front of the chest | enter 0.06 | Frontal hits deal 20% damage; guard meter drains (0–100, regenerates 25/s after 1 s); **guard break** at 0 = 0.8 s stun |
| PARRY | Deflect | press Block **≤ 0.15 s before** a hit lands | *new*: blades snap outward | 0.25 | No damage; the attacker is **staggered 0.8 s**; opens COUNTER |
| COUNTER | Counter Cut | Light within **0.6 s** after PARRY | H02 → H03 (fast) | startup 0.05 each | L1 + L2 at double stagger |
| ROLL | Dodge Roll | Dodge | *new*: low tucked roll (the A04 tuck shape on the ground) | 0.40 total, **invulnerable 0.05–0.30** | Travels 3.2 m; can **reverse facing** if a direction is held at start |
| ROLL_ATK | Roll Slash | Light during the roll's last 0.15 s | **A06** | 0.05 / 0.08 / 0.28 | Low steel sweep out of the roll |

### 3.5 Reactions

| ID | Poses | Timing | Notes |
|---|---|---|---|
| HURT | *new* | 0.30 | head_hurt, knocked back |
| STAGGER | *new* | loop, 2.5 s | Slumped, blades lowered |
| KO | *new* | 1.0 | Fall, then respawn per the level rules |

## 4. Flags per move

| Move | Grounded / airborne | Invulnerable | Facing may change |
|---|---|---|---|
| D_STANCE, runs, jumps | as moved | no | yes (input) |
| L1, H1, ROLL | grounded | ROLL 0.05–0.30 | **first 0.05 s only** |
| L2, L3, L4, COUNTER | grounded | no | no |
| LAUNCH | grounded → airborne at 0.30 | no | no |
| AIR1, AIR2 | airborne | no | no |
| AIR_LAND, ROLL_ATK | grounded | no | no |
| FINISH | A03–A05 airborne, rest grounded | **entire move** | no |
| BLOCK | grounded | frontal only (reduced) | no |
| PARRY | grounded | during the window | no |

Turn views (art spec §5) swap in on H05–H06 (back-side), A05 (back-side), A07 (front→back→front across the spin) and A04 (front-3/4 tuck). The arm chains swap near/far on the back-side beats.

## 5. Combo tree

```
STANCE ─Light→ L1 ─Light→ L2 ─Light→ L3 ─Light→ L4
   │            │Heavy      │Heavy
   │            └──→ LAUNCH ←┘ ─Light→ AIR1 ─Light→ AIR2 ─Light/Heavy/land→ AIR_LAND
   ├─Heavy→ H1
   ├─Heavy (staggered enemy near)→ FINISH
   ├─Block (hold)→ BLOCK ─(timed)→ PARRY ─Light→ COUNTER
   └─Dodge→ ROLL ─Light (late)→ ROLL_ATK
```

Inputs buffer **one** follow-up. Dodge may cancel the **recovery** of any grounded attack except FINISH.

## 6. Trails (hybrid: procedural ribbons with painted textures)

- **Ribbon:** each blade samples its edge from **30% of its length to the tip** every physics frame (120 Hz) **during active frames plus 1 frame either side**. It keeps the last **N samples**: Ghostblade **16 (≈0.13 s)**, steel **10 (≈0.08 s)**. These build a quad strip textured with `trail_ghost.png` / `trail_steel.png` (u runs along age, so the newest is brightest).
- **Separation from the blade:** the ribbon's newest edge sits **one sample behind** the blade, so there's always a gap and it never draws over the rigid steel.
- **Dissipation:**
  - **Ghostblade:** the ribbon fades out over **0.25 s** with noise erosion. It sheds **4–8 `fx_data_fragments`** along its length that drift up-back 0.3 m, flicker, and vanish within **0.4 s**.
  - **Steel:** the ribbon fades out over **0.15 s**, with no particles.
- **Hits:** spawn `fx_hit_spark_{steel,ghost}` at the contact point (4 frames, 0.12 s), plus the blade-flash light for the Ghostblade (lime `#c8ff3a`).
- **Width:** Ghostblade ribbon 0.10 m, steel 0.05 m, tapering to 0 at the oldest sample.

## 7. Art still needed (pose studies, not runtime art)

The v5 sheets cover L1–L4, H1, LAUNCH, AIR1–2, AIR_LAND and FINISH. For the remaining moves, an **8-pose study sheet in the same style** (side view, rigid blades, both weapons visible) is enough:

1. **Sheathed set:** S_IDLE, S_RUN (2 poses), S_JUMP, LAND.
2. **DRAW** (3 poses: reach, cross-draw, settle into H01) and SHEATHE (2 poses).
3. **Defence:** BLOCK (crossed low X), PARRY (deflect outward), ROLL (3 tuck poses), ROLL_ATK.
4. **Reactions:** HURT, STAGGER, KO (2).
5. **D_RUN** (2 poses).

## 8. Implementation notes (for the M4b plan)

- **Rig:** two weapon chains (each hand gets grip back, weapon, grip front), two hip-sheath slots, turn-view PartSwap groups (head, torso, pelvis, hair), near/far arm swapping (shading variant + z-order keys), and a 3-bone hair chain with spring secondary motion.
- **Animation data** is authored as pose tables per move (as now), keyed to the study frames above. The diagonal/overhead test becomes: **both blade tips travel mostly horizontally in front of the body during active frames, and no active frame has a tip above the head behind the body.**
- **Combat state** gains sheathed/drawn states, a guard meter, parry windows, a roll with invulnerability, facing-change windows, and FINISH slow-motion.
- **Hitboxes** come from §3 (metres, relative to the feet, facing right). H1 is centred on the body.
