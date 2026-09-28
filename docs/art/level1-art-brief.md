# Level 1 — *The Last Train* — Art Brief

Sizes come from the size tool (`tools/art_sizes.gd`), and `check_art.py` checks them against each folder's `sizes.json`. General rules, the prompt style block and tool tips are in `art-guide.md`. **Palette line for this level:** *dark cramped underground, saturated magenta and cyan neon, wet reflections, steam, low ceilings.*

Every file is an 8-bit RGBA PNG. "Transparent" means alpha 0: layers behind it show through there, so don't paint sky or background into those areas. Glow parts listed per layer go in the `_emit` map. `make_maps.py` makes a starter one that you can paint over.

The level has two sections:

| Section | Folder | Shape | What happens |
|---|---|---|---|
| **1. Abandoned Station** | `art/levels/l1_station/` | 134.4 × 16.2 m (7 screens wide, 1.5 tall) | Movement tutorial, flooded tracks, fight with a security squad on the platform, board the departing train at the right end. |
| **2. Tunnel Run** | `art/levels/l1_train/` | 57.6 × 12 m train + looping tunnel | Sprint along the roof of the accelerating train (3 cars) through the tunnel; the scenery scrolls past on loop. |

---

## Section 1 — Abandoned Station (`l1_station/`)

### Where the level sits on the gameplay plate
The gameplay plate is **14,784 × 1,792 px** (100 px = 1 m).
- **Playable area:** x **672 → 14,112 px**. The 672 px at each end is margin that only shows during camera shake, so continue the scene there without key features.
- **Main floor line** (top of the platform the player walks on): **y = 1,606 px from the top**. The level's bottom edge is y 1,706; its top is y 86.
- **Player size:** 180 px tall. Doors about 300 px, ceiling lights about 60 px.

### Layers

| Layer | File | Size (px) | Transparent? | Content | Glow (`_emit`) |
|---|---|---|---|---|---|
| Back wall (sky slot) | `sky.png` | **3,392 × 1,280** | No | The station's far back wall and vault: a dark curved tiled ceiling fading into blackness, faint grime, a few dead ceiling lamps. No bright features, since it barely moves. | Optional: 1–2 very dim distant lamps |
| Far | `far.png` | **4,800 × 1,344** | Top: yes | Distant tunnel mouths and a mezzanine behind the tracks: dark arches, a stalled old train silhouette, hazy steam. Low contrast. | Signal lights (red/green dots), one faint station sign |
| Mid | `mid.png` | **6,784 × 1,408** | Yes (above the structures) | The opposite platform across the tracks: pillars, broken ad panels, benches, a stairway up, hanging cables. Leave 2–3 dark tunnel openings (a passing train effect is added there later). | Broken ad screens (magenta/cyan), fluorescent tubes, a platform number sign |
| Near | `near.png` | **10,816 × 1,600** | Yes | The flooded track pit just behind the walkway: rails in dark water with neon reflections, drainage pipes, maintenance ladders, graffiti walls, ticket gates. Wet and reflective. | Neon reflections in the water, emergency lights, vending machine fronts |
| Gameplay | `gameplay.png` | **14,784 × 1,792** | Yes | The platform the player walks on, seen side-on: platform edge and front face below the floor line, tiled walls, **low ceiling** with fluorescent fixtures in the top ~250 px, ad frames, a locked security shutter at x ≈ 1,500, a broken turnstile section, steam vents. At the right end (x ≈ 12,800–14,112) the platform edge where the departing train waits (just its doors/side; the train itself is section 2). | Fluorescent tubes (they'll flicker), ad screens, exit signs, door status lights |

**Where to raise floors:** you may paint raised areas (benches, crates, a ticket booth roof, a collapsed ceiling slab) anywhere between x 672 and 14,112. I'll trace collision to match the art, so the art decides where the player can stand. Keep any step up at **≤ 250 px** (the jump reaches about 300 px). Mark walkable tops with a clear, readable edge.

### Foreground props (`fg_<name>.png`, transparent, 167 px per metre)
Dark, simple silhouettes in front of everything; they'll be blurred. Paint 4–6 of them:

| Prop | File | Size (px) |
|---|---|---|
| Station pillar | `fg_pillar.png` | 200 × 1,500 |
| Hanging cable bundle | `fg_cables.png` | 600 × 900 |
| Pipe run with valve | `fg_pipe.png` | 1,200 × 300 |
| Leaning sign post | `fg_sign.png` | 300 × 1,100 |
| Steam vent grate + plume | `fg_vent.png` | 400 × 1,000 |

---

## Section 2 — Tunnel Run (`l1_train/`)

The train stays still in the game world and the tunnel scrolls past it. The scenery layers are **looping strips**: the right edge must join seamlessly back onto the left edge, like wallpaper. Every loop is **4,096 px wide**, because each layer shows about 2,520 px at once on an ultrawide screen.

### The train (gameplay plate, does *not* loop)
**`gameplay.png` — 6,336 × 1,344 px, transparent around the train.**
- **Playable area:** x **288 → 6,048 px** (three cars of ~1,900 px each, with gaps and couplings between them).
- **Roof line** (where the player runs): **y = 872 px from the top**. Track/rail level is about y 1,242.
- **Content:** a sleek maglev-era commuter train side-on, with roof vents, antennas, cable conduits and hatches, plus a **low obstacle every ~800–1,200 px** that must be jumped (vent housing, cable reel, antenna mast, about 60–200 px tall). The front of car 1 is at the right end.
- **Glow:** window strips (interior light), headlight glow at the front, blinking roof markers.

### Looping scenery

| Layer | File | Size (px) | Transparent? | Content | Glow |
|---|---|---|---|---|---|
| Mid | `mid_loop.png` | **4,096 × 1,280** | Yes | Seen through openings in the tunnel wall: a parallel tunnel and cavern with distant track lights, a far train's lit windows, emergency beacons. Mostly dark. | Track lights, far-train windows |
| Near | `near_loop.png` | **4,096 × 1,280** | Yes: the arch openings | The tunnel wall right behind the train: ribbed concrete, cable trays, pipes, numbered segment markers, and **2 arch openings** per loop through which the mid layer shows. | Wall lamps every ~1,000 px, segment numbers, warning stripes |
| Foreground | `fg_loop.png` | **4,096 × 1,408** | Yes, mostly empty | 2–3 dark pillars or hanging cable bundles per loop, passing between the camera and the train; they'll be motion-blurred. | None |

(There's no sky or far layer here, because the tunnel is enclosed and the background is solid darkness.)

---

## Delivery checklist
1. Put the files in the folders above using exactly these filenames.
2. **Collision (optional):** either compose the gameplay plate with `compose_plate.py` and mark walkable pieces (it writes `gameplay_collision.json`), or paint a black/white **`gameplay_solid.png`** (same size as `gameplay.png`, white = solid ground/ledges). Until you do, the greybox collision in `section.json` is used.
3. Run **`bash tools/import_art.sh`**: it makes starter `_n`/`_emit` maps where missing, slices and compresses the plates, traces `gameplay_solid.png`, checks every file and imports into Godot (one line per step).
4. Press F5 → START: your art replaces the placeholders in Level 1.

Foreground props are placed by `props` entries in `section.json` (`image`, `x`, `y` = bottom edge in metres, optional `scale`, e.g. `1.6` to enlarge hanging cables).

Gameplay data (spawn, exit, enemies, arena, lights, loop speed) lives in each folder's `section.json` (metres, schema in the M3 plan's Global Constraints).
