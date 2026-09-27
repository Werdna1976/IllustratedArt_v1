# M2 Character & Combat Core Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans (user chose native execution). Steps use checkbox (`- [ ]`) syntax.
>
> **Plan format (token-efficiency ruling, user-requested):** tests are given as complete code; implementation is specified by interface, formulas and data tables, and written during execution under TDD. Deviations still go in the ledger as `Ruling:` lines.

**Goal:** A playable combat sandbox: a placeholder cutout fighter (2D-authored rig mirrored to lit 3D quads) with the full moveset (light ×3, heavy, launcher, air light, parry, dodge, finisher) against a training dummy and a telegraphing security officer, plus the art tools the user needs to produce real art.

**Architecture:** Pure logic (move timing, combat state machine, hit resolution, vitals, officer brain) lives in `RefCounted` classes with unit tests. Thin nodes (`Fighter` → `Player`, `Enemy`) wire logic to physics, `Area3D` hit/hurtboxes, the cutout visual and effects. Art tools are small Python scripts (PIL + numpy) with `unittest` tests, run by the same `tools/run_tests.sh`.

**Tech Stack:** Godot 4.7.2 GDScript, Python 3.14 (Pillow 12, numpy 2.4), existing test runner.

**Spec:** `docs/superpowers/specs/2026-09-27-illustrated-platformer-design.md` (§5.6 characters, §5.7 combat), `docs/superpowers/specs/2026-09-27-ghostline-game-design.md` (§3 combat), `docs/art/art-guide.md`.

## Global Constraints

- Everything from M1's Global Constraints still holds (engine path, scale, z-offsets, 120 Hz, commit trailer, GDScript style).
- Character density `WorldSpec.CHAR_PX_PER_M = 400.0`; rig space is px, origin at the character's feet, +Y down; 3D = (x/400, −y/400).
- Part layering: `z = z_index * CutoutMirror.Z_STEP` with `Z_STEP = 0.002` m, relative to the visual root at `ACTOR_Z`.
- Collision layers: 1 world, 3 hitbox, 4 hurtbox. Hitboxes mask layer 4 only; hurtboxes are on layer 4 and mask nothing.
- Input actions (added to `GameInput`): `light_attack` (J, pad X), `heavy_attack` (K, pad Y), `launcher` (I, pad RB), `parry` (L, pad LB), `dodge` (Shift, pad B). Finisher = `heavy_attack` while a staggered enemy is within `FINISHER_RANGE = 2.0` m in front.
- Timings in seconds; all moves authored in `data/moves/*.tres` (generated once by `tools/make_moves.gd`, then hand-tunable in the inspector).
- Tools print one line per item plus a summary; nothing verbose by default.

## Review Focus

1. **Parry from behind** — a parry must only work when facing the attacker; a hit from behind lands. Pinned by Task 6 `test_parry_only_when_facing_attacker`.
2. **Holding attack buttons / mashing** — mashing must not skip combo steps or restart a move mid-swing; one input buffers at most one follow-up. Pinned by Task 5 `test_mashing_buffers_one_follow_up_only`.
3. **The same swing hitting an enemy twice** — each active window hits each target once. Pinned by Task 7 `test_one_hit_per_target_per_swing`.
4. **Hit-stop leaving the game slowed** — `Engine.time_scale` must always return to 1.0, even with overlapping hit-stops. Pinned by Task 7 `test_overlapping_hit_stops_restore_time_scale`.
5. **Regenerating maps over hand-painted glow masks** — `make_maps.py` must never overwrite an existing `_emit`/`_n` without `--force`. Pinned by Task 1 `test_existing_maps_not_overwritten`.

---

## File Structure

| File | Responsibility |
|---|---|
| `tools/art/make_maps.py` | Normal + emissive maps from a colour PNG |
| `tools/art/check_art.py` | Validate delivered art (sizes, alpha, companions) |
| `tools/art/make_placeholder_fighter.py` | Generate placeholder `parts.png` + `parts.json` |
| `tools/art/test_art_tools.py` | unittest for the three scripts |
| `tools/art_sizes.gd` | Print/write plate sizes for a section (uses `WorldSpec`) |
| `tools/make_placeholder_rig.gd` | Build + save the placeholder rig scene with animations |
| `tools/make_moves.gd` | Write default `MoveSet` resources |
| `tools/run_tests.sh` (modify) | Also run Python tests |
| `scripts/world_spec.gd` (modify) | `CHAR_PX_PER_M` |
| `scripts/art_sizes.gd` | `ArtSizes.for_section(level_size) -> Dictionary` |
| `scripts/cutout/cutout_mirror.gd` | 2D rig → lit 3D quads |
| `scripts/combat/move_data.gd`, `move_set.gd` | Move resources |
| `scripts/combat/combat_fighter.gd` | Pure move state machine |
| `scripts/combat/vitals.gd`, `hit_resolver.gd` | HP/stagger; hit outcome |
| `scripts/combat/hit_stop.gd` | Time-scale freeze with safe restore |
| `scripts/fighter.gd` | Shared body: physics, hit/hurtboxes, visual, effects |
| `scripts/player.gd` (rewrite) | Input-driven `Fighter` |
| `scripts/enemies/enemy.gd`, `officer_brain.gd`, `training_dummy.gd` | Enemies |
| `scripts/game_input.gd` (modify) | Combat actions |
| `scripts/combat_sandbox.gd`, `scenes/level/combat_sandbox.tscn` | Sandbox level |
| `art/characters/placeholder_fighter/parts*.png`, `parts.json` | Placeholder art (generated, committed) |
| `scenes/characters/placeholder_fighter_rig.tscn` | Generated rig (committed) |
| `data/moves/player.tres`, `data/moves/officer.tres` | Move sets (generated, committed) |

---

### Task 1: Art tools (Python) and section sizes

**Files:** Create `tools/art/make_maps.py`, `tools/art/check_art.py`, `tools/art/test_art_tools.py`, `tools/art_sizes.gd`, `scripts/art_sizes.gd`, `tests/art_sizes_test.gd`. Modify `tools/run_tests.sh`, `.gitignore` (add `art/_source/`).

**Interfaces:**
- `make_maps.py <png> [--strength 2.0] [--glow 0.8] [--force]` → writes `<stem>_n.png`, `<stem>_emit.png` next to it; skips a map that exists unless `--force`; prints `wrote|kept <path>`. Importable: `make_normal(img: PIL.Image) -> Image`, `make_emissive(img, threshold) -> Image`, `main(argv) -> int`.
- `check_art.py <dir>` → prints `OK <path>` / `FAIL <path>: <reason>` per colour PNG and `N ok, M failed`; exit 1 on any failure. Importable `check_file(path) -> list[str]` (empty = OK). Rules: characters `*/characters/*/parts.png` must be 2048² or 4096², RGBA with some alpha < 255, and have `_n` + `_emit` of equal size; level plates `*/levels/*/<layer>.png` must be RGBA with transparency except `sky`; `gameplay`/`near` need `_n`; any companion must match size; if `sizes.json` sits in the same folder, the plate size must equal `sizes.json[layer]`.
- `ArtSizes.for_section(level_size: Vector2) -> Dictionary` → `{"sky": Vector2i, "far": …, "mid": …, "near": …, "gameplay": …}` using depths 400/100/40/10/0 and `WorldSpec.plate_size_px`.
- `tools/art_sizes.gd` (SceneTree script): `-- <w_m> <h_m> [out.json]` prints `layer WxH` lines and optionally writes JSON `{"layer": [w, h]}`.

**Algorithms:**
- Normal: luminance `L = .299r+.587g+.114b` (0–1) → 3×3 box blur → `dx, dy = np.gradient` (x right, y down) → `n = normalize(-dx*s, +dy*s, 1)` (OpenGL/+Y-up convention, as Godot expects) → `rgb = n*0.5+0.5`; fully transparent pixels get `(128,128,255)`; alpha copied.
- Emissive: `v = max(rgb)`, `sat = (max-min)/max` → `mask = smoothstep(threshold-0.1, threshold+0.1, v) * smoothstep(0.35, 0.6, sat)` → `rgb*mask`, alpha copied.

- [ ] **Step 1: Write the failing tests**

`tools/art/test_art_tools.py`:
```python
import json, os, sys, tempfile, unittest
import numpy as np
from PIL import Image
sys.path.insert(0, os.path.dirname(__file__))
import check_art, make_maps


def rgba(w, h, color=(0, 0, 0, 0)):
    return Image.new("RGBA", (w, h), color)


class MakeMapsTest(unittest.TestCase):
    def test_flat_image_gives_flat_normal(self):
        n = np.asarray(make_maps.make_normal(rgba(8, 8, (100, 100, 100, 255))))
        self.assertTrue((abs(n[..., 0].astype(int) - 128) <= 1).all())
        self.assertTrue((abs(n[..., 1].astype(int) - 128) <= 1).all())
        self.assertTrue((n[..., 2] >= 254).all())

    def test_brighter_to_the_right_tilts_normal_left(self):
        a = np.zeros((8, 16, 4), np.uint8); a[..., 3] = 255
        a[..., 0:3] = np.linspace(0, 255, 16, dtype=np.uint8)[None, :, None]
        n = np.asarray(make_maps.make_normal(Image.fromarray(a)))
        self.assertLess(int(n[4, 8, 0]), 120)

    def test_emissive_keeps_bright_saturated_drops_grey(self):
        a = np.zeros((1, 2, 4), np.uint8); a[..., 3] = 255
        a[0, 0, :3] = (0, 255, 255)   # bright cyan -> glows
        a[0, 1, :3] = (90, 90, 90)    # grey -> dark
        e = np.asarray(make_maps.make_emissive(Image.fromarray(a), 0.8))
        self.assertGreater(int(e[0, 0, 2]), 200)
        self.assertEqual(int(e[0, 1, :3].max()), 0)

    def test_existing_maps_not_overwritten(self):
        with tempfile.TemporaryDirectory() as d:
            src = os.path.join(d, "near.png"); rgba(4, 4, (255, 0, 0, 255)).save(src)
            emit = os.path.join(d, "near_emit.png"); rgba(4, 4, (1, 2, 3, 255)).save(emit)
            make_maps.main([src])
            self.assertEqual(Image.open(emit).getpixel((0, 0)), (1, 2, 3, 255))
            self.assertTrue(os.path.exists(os.path.join(d, "near_n.png")))
            make_maps.main([src, "--force"])
            self.assertNotEqual(Image.open(emit).getpixel((0, 0)), (1, 2, 3, 255))


class CheckArtTest(unittest.TestCase):
    def _char(self, d, size, alpha=True, companions=True):
        cdir = os.path.join(d, "characters", "hero"); os.makedirs(cdir)
        img = rgba(size, size, (0, 0, 0, 0 if alpha else 255)); img.putpixel((0, 0), (9, 9, 9, 255))
        p = os.path.join(cdir, "parts.png"); img.save(p)
        if companions:
            img.save(os.path.join(cdir, "parts_n.png")); img.save(os.path.join(cdir, "parts_emit.png"))
        return p

    def test_good_character_passes(self):
        with tempfile.TemporaryDirectory() as d:
            self.assertEqual(check_art.check_file(self._char(d, 2048)), [])

    def test_wrong_size_and_missing_companions_fail(self):
        with tempfile.TemporaryDirectory() as d:
            errs = check_art.check_file(self._char(d, 1000, companions=False))
            self.assertTrue(any("size" in e for e in errs))
            self.assertTrue(any("_n" in e for e in errs))

    def test_plate_size_checked_against_sizes_json(self):
        with tempfile.TemporaryDirectory() as d:
            ldir = os.path.join(d, "levels", "l1"); os.makedirs(ldir)
            json.dump({"far": [64, 32]}, open(os.path.join(ldir, "sizes.json"), "w"))
            p = os.path.join(ldir, "far.png"); rgba(64, 30).save(p)
            self.assertTrue(any("64x32" in e for e in check_art.check_file(p)))

    def test_opaque_non_sky_plate_fails_sky_passes(self):
        with tempfile.TemporaryDirectory() as d:
            ldir = os.path.join(d, "levels", "l1"); os.makedirs(ldir)
            mid = os.path.join(ldir, "mid.png"); rgba(8, 8, (5, 5, 5, 255)).save(mid)
            sky = os.path.join(ldir, "sky.png"); rgba(8, 8, (5, 5, 5, 255)).save(sky)
            self.assertTrue(any("transparen" in e for e in check_art.check_file(mid)))
            self.assertEqual(check_art.check_file(sky), [])


if __name__ == "__main__":
    unittest.main()
```

`tests/art_sizes_test.gd`:
```gdscript
extends TestCase
## ArtSizes reports WorldSpec plate sizes per layer for any section.


func test_default_section_matches_spec_table() -> void:
	var sizes := ArtSizes.for_section(WorldSpec.LEVEL_SIZE)
	assert_eq(sizes.gameplay, Vector2i(14784, 1792), "gameplay")
	assert_eq(sizes.near, Vector2i(10816, 1600), "near")
	assert_eq(sizes.mid, Vector2i(6784, 1408), "mid")
	assert_eq(sizes.far, Vector2i(4800, 1344), "far")
	assert_eq(sizes.sky, Vector2i(3392, 1280), "sky")


func test_vertical_section_gets_tall_plates() -> void:
	var sizes := ArtSizes.for_section(Vector2(28.8, 64.8))
	assert_true(sizes.gameplay.y > sizes.gameplay.x, "a climb section is taller than wide")
```

- [ ] **Step 2: Wire Python tests into `tools/run_tests.sh`** — before the Godot run: `python -m unittest discover -s tools/art -p "test_*.py" -q >.godot/py_test.log 2>&1`; on failure print the log's last 30 lines; always print `python: <Ran N tests … OK|FAILED>` (one line). Exit non-zero if either suite fails.
- [ ] **Step 3: Run `bash tools/run_tests.sh`** — Expected: Python import errors (modules missing) and `FAIL art_sizes_test.gd: script failed to load`.
- [ ] **Step 4: Implement** `make_maps.py`, `check_art.py`, `scripts/art_sizes.gd`, `tools/art_sizes.gd`; add `art/_source/` to `.gitignore`.
- [ ] **Step 5: Run tests** — Expected: python OK, all Godot tests pass. Also run `"$G" --headless --path . --script res://tools/art_sizes.gd -- 134.4 16.2` and check it prints the five spec sizes.
- [ ] **Step 6: Commit** `feat: art tools (make_maps, check_art, art_sizes)`.

---

### Task 2: CutoutMirror

**Files:** Create `scripts/cutout/cutout_mirror.gd`, `tests/cutout_mirror_test.gd`. Modify `scripts/world_spec.gd` (`const CHAR_PX_PER_M := 400.0`).

**Interfaces:**
- `class_name CutoutMirror extends Node3D`; `const Z_STEP := 0.002`.
- `func setup(rig: Node2D, albedo: Texture2D, normal: Texture2D, emissive: Texture2D) -> void` — creates one `MeshInstance3D` (QuadMesh, own `StandardMaterial3D`) per `Sprite2D` descendant of `rig` (tree order), stored in `var quads: Dictionary` (Sprite2D → MeshInstance3D), then calls `sync()`. `normal`/`emissive` may be null.
- `func sync() -> void` — updates every quad from its sprite; called from `_process`.
- Material: albedo = atlas, `uv1_scale = (rw/tw, rh/th, 1)`, `uv1_offset = (rx/tw, ry/th, 0)`, alpha scissor 0.5, `cull_mode = CULL_DISABLED`, per-pixel shading, normal/emission enabled when textures given (emission colour white), `albedo_color = sprite.modulate`.
- Transform: `rel = rig.get_global_transform().affine_inverse() * sprite.get_global_transform()`; local rect = region size `s`, top-left `o = sprite.offset - s/2` if `centered` else `sprite.offset`; `c = rel * (o + s/2)`; quad `position = (c.x/PPM, -c.y/PPM, sprite.z_index*Z_STEP)`; `basis = Basis(Vector3.BACK, -rel.get_rotation()).scaled(Vector3(sx, sy, 1))` with `sx, sy = rel.get_scale()`; `QuadMesh.size = s/PPM`; `quad.visible = sprite.is_visible_in_tree()` evaluated relative to the rig (the rig root itself is hidden, so use each sprite's own `visible` chain up to — not including — the rig).

- [ ] **Step 1: Failing tests** — `tests/cutout_mirror_test.gd`:
```gdscript
extends TestCase
## CutoutMirror copies 2D part transforms onto lit 3D quads at 400 px/m.

const PPM := 400.0


func _atlas() -> Texture2D:
	return ImageTexture.create_from_image(Image.create_empty(200, 100, false, Image.FORMAT_RGBA8))


func _rig() -> Array:
	var rig := Node2D.new()
	rig.visible = false
	var arm := Sprite2D.new()
	arm.region_enabled = true
	arm.region_rect = Rect2(50, 20, 100, 40)
	arm.centered = true
	arm.offset = Vector2(50, 0) # pivot at the arm's left end
	arm.position = Vector2(0, -400) # shoulder 1 m above the feet
	arm.z_index = 3
	rig.add_child(arm)
	return [rig, arm]


func test_one_quad_per_sprite_with_region_uvs() -> void:
	var r := _rig()
	var mirror := CutoutMirror.new()
	add_node(r[0])
	add_node(mirror)
	mirror.setup(r[0], _atlas(), null, null)
	assert_eq(mirror.quads.size(), 1, "one quad")
	var q: MeshInstance3D = mirror.quads[r[1]]
	assert_near((q.mesh as QuadMesh).size.x, 100.0 / PPM, 1e-6, "quad width in metres")
	var mat := q.material_override as StandardMaterial3D
	assert_near(mat.uv1_scale.x, 0.5, 1e-6, "uv scale x")
	assert_near(mat.uv1_offset.y, 0.2, 1e-6, "uv offset y")
	assert_eq(mat.cull_mode, BaseMaterial3D.CULL_DISABLED, "double-sided for facing flips")


func test_position_follows_pivot_and_flips_y() -> void:
	var r := _rig()
	var mirror := CutoutMirror.new()
	add_node(r[0])
	add_node(mirror)
	mirror.setup(r[0], _atlas(), null, null)
	var q: MeshInstance3D = mirror.quads[r[1]]
	# unrotated: quad centre is 50 px right of the shoulder, 400 px up
	assert_near(q.position.x, 50.0 / PPM, 1e-5, "x")
	assert_near(q.position.y, 400.0 / PPM, 1e-5, "y up")
	assert_near(q.position.z, 3 * CutoutMirror.Z_STEP, 1e-6, "z from z_index")


func test_rotation_swings_around_pivot() -> void:
	var r := _rig()
	var mirror := CutoutMirror.new()
	add_node(r[0])
	add_node(mirror)
	mirror.setup(r[0], _atlas(), null, null)
	(r[1] as Sprite2D).rotation = PI / 2 # 2D clockwise: arm now points down (+y)
	mirror.sync()
	var q: MeshInstance3D = mirror.quads[r[1]]
	assert_near(q.position.x, 0.0, 1e-5, "pivot stays put in x")
	assert_near(q.position.y, (400.0 - 50.0) / PPM, 1e-5, "centre hangs below the shoulder")


func test_hidden_part_hides_quad() -> void:
	var r := _rig()
	var mirror := CutoutMirror.new()
	add_node(r[0])
	add_node(mirror)
	mirror.setup(r[0], _atlas(), null, null)
	(r[1] as Sprite2D).visible = false
	mirror.sync()
	assert_true(not (mirror.quads[r[1]] as MeshInstance3D).visible, "quad hidden")
```
- [ ] **Step 2: Run** — Expected: `cutout_mirror_test.gd: script failed to load`.
- [ ] **Step 3: Implement** `CHAR_PX_PER_M` and `CutoutMirror` per Interfaces.
- [ ] **Step 4: Run** — all pass.
- [ ] **Step 5: Commit** `feat: CutoutMirror maps 2D cutout rigs onto lit 3D quads`.

---

### Task 3: Placeholder fighter art and rig

**Files:** Create `tools/art/make_placeholder_fighter.py` (+ tests appended to `tools/art/test_art_tools.py`), `tools/make_placeholder_rig.gd`, `tests/placeholder_rig_test.gd`; generated & committed: `art/characters/placeholder_fighter/parts.png`, `parts_n.png`, `parts_emit.png`, `parts.json`, `scenes/characters/placeholder_fighter_rig.tscn`.

**Parts** (px at 400 px/m; `far` copies are 25% darker): head 90×110, torso 110×230, pelvis 100×90, arm_upper 50×130, arm_lower 45×120, hand 45×45, thigh 60×170, shin 50×170, foot 90×40, blade 400×24 (bright cyan edge → glows), glint 40×40 (bright red star → glows). Near/far: arm_upper, arm_lower, hand, thigh, shin, foot. Each part: rounded rectangle, colour gradient lit from the upper left (gives the normal map shape), 32 px padding, shelf-packed into a 2048² transparent canvas. `parts.json`: `{"name": [x, y, w, h]}`. Generator is deterministic; after writing, it runs `make_maps` on `parts.png` with `--force`.

**Rig** (built by `tools/make_placeholder_rig.gd` from `parts.json`; all parts `Sprite2D`, `centered = true`; positions/offsets in px; origin at feet, +Y down):

| Node path | Region | position | offset | z_index |
|---|---|---|---|---|
| `Pelvis` | pelvis | (0, −350) | (0, −20) | 0 |
| `Pelvis/Torso` | torso | (0, −40) | (0, −115) | 1 |
| `Pelvis/Torso/Head` | head | (5, −235) | (0, −50) | 2 |
| `Pelvis/Torso/Head/Glint` | glint | (25, −60) | (0, 0) | 6, `visible = false` |
| `Pelvis/Torso/ArmUpperFar` | arm_upper_far | (−5, −210) | (0, 55) | −2 |
| `…/ArmUpperFar/ArmLowerFar` | arm_lower_far | (0, 110) | (0, 55) | −2 |
| `…/ArmLowerFar/HandFar` | hand_far | (0, 110) | (0, 15) | −2 |
| `Pelvis/ThighFar` | thigh_far | (0, 10) | (0, 80) | −1 |
| `Pelvis/ThighFar/ShinFar` | shin_far | (0, 160) | (0, 80) | −1 |
| `…/ShinFar/FootFar` | foot_far | (0, 165) | (20, 0) | −1 |
| `Pelvis/ThighNear` (+ `ShinNear`, `FootNear`) | near versions | as far | as far | 2 |
| `Pelvis/Torso/ArmUpperNear` (+ `ArmLowerNear`, `HandNear`) | near versions | as far, x = 5 | as far | 3 |
| `…/HandNear/Blade` | blade | (0, 10) | (190, 0) | 4 |

Plus an `AnimationPlayer` named `AnimationPlayer` under the rig root with library `""`. Animations are rotation keyframes (radians) on the listed parts; unlisted parts stay at 0. Length = the move's total time (Task 4 table) so gameplay and animation stay in sync; `idle`, `run`, `staggered` loop.

| Animation | Length | Keys `part: [(t, angle)…]` |
|---|---|---|
| idle | 1.2 loop | Torso: (0,0) (0.6,0.04) (1.2,0); ArmUpperNear: (0,0.3) (0.6,0.35) (1.2,0.3) |
| run | 0.5 loop | ThighNear: (0,−0.6) (0.25,0.6) (0.5,−0.6); ThighFar: opposite; ShinNear/ShinFar: 0.5 at mid-swing; ArmUpperNear: (0,0.6) (0.25,−0.6) (0.5,0.6); ArmUpperFar opposite |
| jump | 0.2 | ThighNear/ThighFar: −0.5; ShinNear/ShinFar: 0.8 |
| fall | 0.2 | ArmUpperNear/ArmUpperFar: −0.8 |
| light1 | 0.34 | ArmUpperNear: (0,−2.2) (0.08,−2.0) (0.16,0.6) (0.34,0.3) |
| light2 | 0.36 | ArmUpperNear: (0,0.6) (0.08,0.7) (0.16,−1.5) (0.36,−0.2) |
| light3 | 0.52 | ArmUpperNear: (0,−2.8) (0.12,−2.9) (0.22,0.9) (0.52,0.3); Torso: (0.12,−0.1) (0.22,0.15) |
| heavy | 0.82 | ArmUpperNear: (0,−2.6) (0.30,−2.7) (0.42,1.0) (0.82,0.3); Torso: (0.30,−0.2) (0.42,0.25) |
| launcher | 0.63 | ArmUpperNear: (0,1.0) (0.18,1.1) (0.28,−2.6) (0.63,−0.5) |
| air_light | 0.31 | ArmUpperNear: (0,−1.8) (0.06,−1.8) (0.16,0.8) (0.31,0.3) |
| finisher | 0.80 | ArmUpperNear: (0,−3.0) (0.10,−3.1) (0.30,1.2) (0.80,0.3); Torso: (0.10,−0.3) (0.30,0.35) |
| parry | 0.42 | ArmUpperNear: (0,−1.2) (0.42,−1.2); ArmLowerNear: (0,−0.6) (0.42,−0.6) |
| dodge | 0.37 | Torso: (0,0) (0.1,−0.45) (0.37,0); ThighNear: (0.1,−0.7) |
| hurt | 0.30 | Torso: (0,0) (0.08,0.3) (0.30,0); Head: (0.08,0.25) |
| staggered | 1.0 loop | Torso: 0.5 constant; Head: 0.4; ArmUpperNear/ArmUpperFar: 0.5 |
| windup | 0.45 | ArmUpperNear: (0,0.3) (0.45,−2.4); `Pelvis/Torso/Head/Glint:visible` (0,true) (0.45,false) |
| officer_attack | 0.75 | ArmUpperNear: (0,−2.4) (0.15,0.8) (0.75,0.3) |

- [ ] **Step 1: Failing tests.** Append to `tools/art/test_art_tools.py`:
```python
import make_placeholder_fighter


class PlaceholderFighterTest(unittest.TestCase):
    def test_sheet_packs_all_parts_without_overlap(self):
        with tempfile.TemporaryDirectory() as d:
            make_placeholder_fighter.main([d])
            parts = json.load(open(os.path.join(d, "parts.json")))
            self.assertIn("blade", parts); self.assertIn("arm_upper_far", parts); self.assertIn("glint", parts)
            rects = list(parts.values())
            for i, a in enumerate(rects):
                for b in rects[i + 1:]:
                    overlap = a[0] < b[0] + b[2] and b[0] < a[0] + a[2] and a[1] < b[1] + b[3] and b[1] < a[1] + a[3]
                    self.assertFalse(overlap, (a, b))
            self.assertEqual(Image.open(os.path.join(d, "parts.png")).size, (2048, 2048))
            self.assertEqual(check_art.check_file(os.path.join(d, "parts.png")), [])
```
(`check_art` recognises characters by the `parts.png` filename, so a temp folder passes.)

`tests/placeholder_rig_test.gd`:
```gdscript
extends TestCase
## The generated placeholder rig has every part and every move's animation at the move's length.

const RIG := "res://scenes/characters/placeholder_fighter_rig.tscn"


func test_rig_has_parts_and_feet_near_origin() -> void:
	var rig: Node2D = add_node(load(RIG).instantiate())
	for path in ["Pelvis/Torso/Head", "Pelvis/Torso/ArmUpperNear/ArmLowerNear/HandNear/Blade", "Pelvis/ThighFar/ShinFar/FootFar"]:
		assert_true(rig.has_node(path), "has %s" % path)
	var foot: Sprite2D = rig.get_node("Pelvis/ThighNear/ShinNear/FootNear")
	assert_near(foot.global_position.y - rig.global_position.y, -15.0, 20.0, "feet within 20 px of the origin")


func test_animations_exist_with_looping() -> void:
	var rig: Node2D = add_node(load(RIG).instantiate())
	var ap: AnimationPlayer = rig.get_node("AnimationPlayer")
	for anim_name in ["idle", "run", "jump", "fall", "light1", "light2", "light3", "heavy", "launcher",
			"air_light", "finisher", "parry", "dodge", "hurt", "staggered", "windup", "officer_attack"]:
		assert_true(ap.has_animation(anim_name), "animation %s" % anim_name)
	assert_eq(ap.get_animation("run").loop_mode, Animation.LOOP_LINEAR, "run loops")
	assert_eq(ap.get_animation("light1").loop_mode, Animation.LOOP_NONE, "attacks do not loop")
```
- [ ] **Step 2: Run** — Expected: Python import error; `placeholder_rig_test` fails to load the missing scene.
- [ ] **Step 3: Implement** the generator; run `python tools/art/make_placeholder_fighter.py art/characters/placeholder_fighter`; implement `tools/make_placeholder_rig.gd` (reads `parts.json`, loads `parts.png`, builds the table above, `PackedScene.pack` + `ResourceSaver.save`), run it: `"$G" --headless --path . --import` then `"$G" --headless --path . --script res://tools/make_placeholder_rig.gd`.
- [ ] **Step 4: Run tests** — all pass. Then `python tools/art/check_art.py art` — Expected `1 ok, 0 failed`.
- [ ] **Step 5: Commit** `feat: placeholder fighter parts sheet and generated cutout rig`.

---

### Task 4: MoveData and MoveSet

**Files:** Create `scripts/combat/move_data.gd`, `scripts/combat/move_set.gd`, `tools/make_moves.gd`, `tests/move_data_test.gd`; generated `data/moves/player.tres`, `data/moves/officer.tres`.

**Interfaces:**
- `class_name MoveData extends Resource`; `enum Phase { STARTUP, ACTIVE, RECOVERY, DONE }`; `@export` fields: `id: StringName`, `anim: StringName`, `startup`, `active`, `recovery: float`, `damage: float`, `stagger: float`, `knockback: Vector2` (x forward m/s, y up m/s), `hit_stop: float`, `cancel_from: float` (−1 = startup+active), `next_combo: StringName`, `hitbox_offset: Vector2`, `hitbox_size: Vector2` (m, facing right, from the body centre), `dash_speed: float` (dodge), `is_parry: bool`, `is_dodge: bool`, `airborne_only: bool`, `requires_staggered_target: bool`. Funcs `total() -> float`, `phase_at(t: float) -> Phase`, `cancel_time() -> float`.
- `class_name MoveSet extends Resource`; `@export var moves: Array[MoveData]`; `func get_move(id: StringName) -> MoveData` (null if missing).

**Player moves** (`data/moves/player.tres`):

| id | startup | active | recovery | dmg | stagger | knockback | hit_stop | cancel_from | next | hitbox off / size | other |
|---|---|---|---|---|---|---|---|---|---|---|---|
| light1 | .08 | .08 | .18 | 10 | 10 | (2,0) | .05 | .14 | light2 | (0.9,1.0)/(1.2,0.8) | |
| light2 | .08 | .08 | .20 | 10 | 10 | (2,0) | .05 | .14 | light3 | same | |
| light3 | .12 | .10 | .30 | 16 | 18 | (5,0) | .08 | −1 | — | (1.0,1.0)/(1.4,1.0) | |
| heavy | .30 | .12 | .40 | 25 | 35 | (7,1) | .12 | −1 | — | (1.1,1.0)/(1.6,1.2) | |
| launcher | .18 | .10 | .35 | 12 | 15 | (0.5,11) | .08 | −1 | — | (0.8,1.2)/(1.2,1.6) | |
| air_light | .06 | .10 | .15 | 8 | 8 | (1,3) | .05 | .12 | air_light | (0.8,0.9)/(1.2,1.0) | airborne_only |
| finisher | .10 | .20 | .50 | 100 | 0 | (6,2) | .20 | −1 | — | (1.0,1.0)/(1.8,1.4) | requires_staggered_target |
| parry | .02 | .15 | .25 | 0 | 0 | — | 0 | −1 | — | — | is_parry |
| dodge | 0 | .25 | .12 | 0 | 0 | — | 0 | −1 | — | — | is_dodge, dash_speed 12 |

**Officer moves** (`data/moves/officer.tres`): `officer_attack` .15/.10/.50, dmg 12, stagger 0, knockback (4,0), hit_stop .06, hitbox (0.9,1.0)/(1.2,0.8), anim `officer_attack`.

(`anim` = `id` for every move.)

- [ ] **Step 1: Failing tests** — `tests/move_data_test.gd`:
```gdscript
extends TestCase
## Move timing phases and the generated move sets.


func _move() -> MoveData:
	var m := MoveData.new()
	m.startup = 0.1
	m.active = 0.2
	m.recovery = 0.3
	m.cancel_from = -1.0
	return m


func test_phases() -> void:
	var m := _move()
	assert_near(m.total(), 0.6, 1e-6, "total")
	assert_eq(m.phase_at(0.05), MoveData.Phase.STARTUP, "startup")
	assert_eq(m.phase_at(0.1), MoveData.Phase.ACTIVE, "active starts exactly at startup end")
	assert_eq(m.phase_at(0.35), MoveData.Phase.RECOVERY, "recovery")
	assert_eq(m.phase_at(0.6), MoveData.Phase.DONE, "done at total")


func test_cancel_time_defaults_to_end_of_active() -> void:
	var m := _move()
	assert_near(m.cancel_time(), 0.3, 1e-6, "default cancel")
	m.cancel_from = 0.15
	assert_near(m.cancel_time(), 0.15, 1e-6, "explicit cancel")


func test_player_move_set_matches_rig_animations() -> void:
	var set: MoveSet = load("res://data/moves/player.tres")
	var rig: Node2D = add_node(load("res://scenes/characters/placeholder_fighter_rig.tscn").instantiate())
	var ap: AnimationPlayer = rig.get_node("AnimationPlayer")
	for id in [&"light1", &"light2", &"light3", &"heavy", &"launcher", &"air_light", &"finisher", &"parry", &"dodge"]:
		var m := set.get_move(id)
		assert_true(m != null, "move %s" % id)
		assert_near(ap.get_animation(m.anim).length, m.total(), 1e-3, "%s animation length = move total" % id)
	assert_eq(set.get_move(&"light1").next_combo, &"light2", "combo chain")
	assert_true(set.get_move(&"nope") == null, "missing move is null")
```
- [ ] **Step 2: Run** — load failures. **Step 3: Implement** resources + `tools/make_moves.gd` (writes both `.tres` from the tables); run it. **Step 4: Run** — pass (fix Task 3 animation lengths if any mismatch, ledgered). **Step 5: Commit** `feat: MoveData/MoveSet resources and default move sets`.

---

### Task 5: CombatFighter state machine

**Files:** Create `scripts/combat/combat_fighter.gd`, `tests/combat_fighter_test.gd`.

**Interfaces:** `class_name CombatFighter extends RefCounted`
- `var moves: MoveSet`, `var current: MoveData` (null = free), `var t := 0.0`, `var hit_this_move: Dictionary` (target → true), `var buffered: StringName`.
- `func request(id: StringName, airborne: bool = false) -> bool` — if stunned → false. If free → start `id` (air `light` requests map to `air_light`; `airborne_only` moves need `airborne`), return true. If in a move: a request of the move's `next_combo` family (`light` → current's `next_combo`) during/after `cancel_time()` starts it immediately; before `cancel_time()` it is **buffered** (one slot; later requests overwrite nothing — the first buffered stays) and starts automatically at `cancel_time()`. `dodge` may cancel any move in RECOVERY. Otherwise false.
- Logical request ids: `&"light"`, `&"heavy"`, `&"launcher"`, `&"parry"`, `&"dodge"`, `&"finisher"`; `light` resolves to `light1` when free.
- `func advance(dt: float) -> Array[StringName]` — events in order from `[&"started:<id>", &"active_start", &"active_end", &"done"]`; returns to free after DONE.
- `func phase() -> MoveData.Phase` (DONE when free); `is_invulnerable()` (dodge ACTIVE); `is_parrying()` (parry ACTIVE); `stun(duration: float)` cancels the current move, blocks requests for `duration`; `is_stunned()`.

- [ ] **Step 1: Failing tests** — `tests/combat_fighter_test.gd`:
```gdscript
extends TestCase
## Pure combat state machine: combos, buffering, cancels, invulnerability, parry window, stun.


func _fighter() -> CombatFighter:
	var f := CombatFighter.new()
	f.moves = load("res://data/moves/player.tres")
	return f


func _run(f: CombatFighter, seconds: float) -> Array[StringName]:
	var events: Array[StringName] = []
	var steps := int(round(seconds * 120.0))
	for i in steps:
		events.append_array(f.advance(1.0 / 120.0))
	return events


func test_light_starts_combo_and_emits_phase_events() -> void:
	var f := _fighter()
	assert_true(f.request(&"light"), "starts")
	assert_eq(f.current.id, &"light1", "light resolves to light1")
	var events := _run(f, 0.34)
	assert_true(events.has(&"active_start") and events.has(&"active_end") and events.has(&"done"), "phase events: %s" % [events])
	assert_true(f.current == null, "free after the move")


func test_combo_chains_through_three_hits() -> void:
	var f := _fighter()
	f.request(&"light")
	_run(f, 0.15)
	assert_true(f.request(&"light"), "chain into light2 after cancel time")
	assert_eq(f.current.id, &"light2", "light2")
	_run(f, 0.15)
	f.request(&"light")
	assert_eq(f.current.id, &"light3", "light3")


func test_mashing_buffers_one_follow_up_only() -> void:
	var f := _fighter()
	f.request(&"light")
	for i in 5:
		f.request(&"light") # mashed during startup
	assert_eq(f.current.id, &"light1", "no restart mid-swing")
	_run(f, 0.15) # passes light1's cancel time (0.14)
	assert_eq(f.current.id, &"light2", "buffered follow-up fired once")
	_run(f, 0.12) # before light2's cancel time: nothing else was buffered
	assert_eq(f.current.id, &"light2", "mash did not queue light3")


func test_dodge_cancels_recovery_and_is_invulnerable() -> void:
	var f := _fighter()
	f.request(&"heavy")
	assert_true(not f.request(&"dodge"), "cannot dodge out of startup")
	_run(f, 0.45) # into heavy recovery
	assert_true(f.request(&"dodge"), "dodge cancels recovery")
	_run(f, 0.05)
	assert_true(f.is_invulnerable(), "invulnerable during dodge active")
	_run(f, 0.25)
	assert_true(not f.is_invulnerable(), "vulnerable after")


func test_parry_window() -> void:
	var f := _fighter()
	f.request(&"parry")
	assert_true(not f.is_parrying(), "not before startup ends")
	_run(f, 0.05)
	assert_true(f.is_parrying(), "parry window open")
	_run(f, 0.15)
	assert_true(not f.is_parrying(), "window closed")


func test_air_light_only_in_air() -> void:
	var f := _fighter()
	f.request(&"light", true)
	assert_eq(f.current.id, &"air_light", "light in the air becomes air_light")


func test_stun_cancels_and_blocks_input() -> void:
	var f := _fighter()
	f.request(&"heavy")
	f.stun(0.3)
	assert_true(f.current == null, "move cancelled")
	assert_true(not f.request(&"light"), "stunned")
	_run(f, 0.31)
	assert_true(f.request(&"light"), "free after stun")
```
- [ ] **Step 2: Run** (fails to load) → **Step 3: Implement** → **Step 4: Run** (pass) → **Step 5: Commit** `feat: CombatFighter move state machine`.

---

### Task 6: Vitals and HitResolver

**Files:** Create `scripts/combat/vitals.gd`, `scripts/combat/hit_resolver.gd`, `tests/hit_resolver_test.gd`.

**Interfaces:**
- `class_name Vitals extends RefCounted`: `max_hp`, `hp`, `max_stagger`, `stagger`, `const STAGGER_DECAY_DELAY := 1.5`, `const STAGGER_DECAY := 20.0` (per s), `const STAGGERED_TIME := 2.5`; `func take(damage: float, stagger_dmg: float) -> void`; `func advance(dt: float)`; `is_dead()`, `is_staggered()`; `static func make(hp: float, stagger: float) -> Vitals`. Filling stagger to max sets staggered for `STAGGERED_TIME`, then stagger resets to 0.
- `class_name HitResolver extends RefCounted`; `enum Outcome { HIT, PARRIED, EVADED }`; `static func resolve(move: MoveData, attacker_x: float, attacker_facing: float, defender_x: float, defender_facing: float, defender_parrying: bool, defender_invulnerable: bool) -> Dictionary` → `{outcome, damage, stagger, knockback: Vector2}` where knockback.x is signed by `attacker_facing`. EVADED when invulnerable; PARRIED when parrying **and** the defender faces the attacker (`sign(attacker_x - defender_x) == defender_facing`); otherwise HIT with the move's numbers. `const PARRY_STUN := 0.8` (applied to the attacker by the caller).

- [ ] **Step 1: Failing tests** — `tests/hit_resolver_test.gd`:
```gdscript
extends TestCase
## Hit outcomes and HP/stagger bookkeeping.


func _move() -> MoveData:
	var m := MoveData.new()
	m.damage = 10.0
	m.stagger = 20.0
	m.knockback = Vector2(3, 1)
	return m


func test_plain_hit_signs_knockback_by_facing() -> void:
	var r := HitResolver.resolve(_move(), 0.0, -1.0, -1.0, 1.0, false, false)
	assert_eq(r.outcome, HitResolver.Outcome.HIT, "hit")
	assert_near(r.damage, 10.0, 1e-6, "damage")
	assert_near(r.knockback.x, -3.0, 1e-6, "pushed the way the attacker faces")


func test_parry_only_when_facing_attacker() -> void:
	# attacker at x=2 facing left; defender at x=0
	var facing := HitResolver.resolve(_move(), 2.0, -1.0, 0.0, 1.0, true, false)
	assert_eq(facing.outcome, HitResolver.Outcome.PARRIED, "parried when facing the attacker")
	var back := HitResolver.resolve(_move(), 2.0, -1.0, 0.0, -1.0, true, false)
	assert_eq(back.outcome, HitResolver.Outcome.HIT, "hit from behind lands through a parry")


func test_invulnerable_evades() -> void:
	var r := HitResolver.resolve(_move(), 0.0, 1.0, 1.0, -1.0, false, true)
	assert_eq(r.outcome, HitResolver.Outcome.EVADED, "dodged")


func test_stagger_fills_then_recovers() -> void:
	var v := Vitals.make(100.0, 30.0)
	v.take(5.0, 20.0)
	assert_true(not v.is_staggered(), "not yet")
	v.take(5.0, 20.0)
	assert_true(v.is_staggered(), "full meter staggers")
	assert_near(v.hp, 90.0, 1e-6, "hp")
	v.advance(Vitals.STAGGERED_TIME + 0.01)
	assert_true(not v.is_staggered(), "stagger ends")
	assert_near(v.stagger, 0.0, 1e-6, "meter reset")


func test_stagger_decays_after_delay() -> void:
	var v := Vitals.make(100.0, 50.0)
	v.take(0.0, 20.0)
	v.advance(1.0)
	assert_near(v.stagger, 20.0, 1e-6, "no decay inside the delay")
	v.advance(1.0) # 0.5 s past the delay
	assert_near(v.stagger, 10.0, 1e-6, "decays at 20/s")


func test_death() -> void:
	var v := Vitals.make(10.0, 10.0)
	v.take(15.0, 0.0)
	assert_true(v.is_dead(), "dead")
	assert_near(v.hp, 0.0, 1e-6, "hp clamps at 0")
```
- [ ] **Steps 2–5:** run (fail) → implement → run (pass) → commit `feat: Vitals and HitResolver`.

---

### Task 7: Fighter node, Player rewrite, hit-stop, blade light

**Files:** Create `scripts/fighter.gd`, `scripts/combat/hit_stop.gd`, `tests/fighter_test.gd`. Rewrite `scripts/player.gd`; modify `scripts/game_input.gd`, `tests/player_test.gd` (visual test now checks the cutout), `scripts/test_level.gd` only if `Player.create()` changes signature (it must not).

**Interfaces:**
- `class_name HitStop extends RefCounted`: `static func trigger(tree: SceneTree, duration: float) -> void` — sets `Engine.time_scale = 0.05`; tracks the latest end time in real seconds (`Time.get_ticks_msec`); a real-time timer (`tree.create_timer(duration, true, false, true)`) restores `1.0` only if no later hit-stop is pending. `static func active() -> bool`.
- `class_name Fighter extends CharacterBody3D`: `const RADIUS := 0.4`, `const HEIGHT := 1.8`, `var facing := 1.0`, `var vitals: Vitals`, `var combat: CombatFighter`, `var is_network := false`, `var visual: Node3D` (flip root, `scale.x = facing`), `var rig: Node2D`, `var anim: AnimationPlayer`, `var mirror: CutoutMirror`, `var hitbox: Area3D`, `var hurtbox: Area3D`, `var blade_light: OmniLight3D`; signals `hit_landed(target: Fighter, result: Dictionary)`, `got_hit(result: Dictionary)`.
  - `func build(rig_scene: PackedScene, albedo, normal, emissive, move_set: MoveSet, hp: float, stagger: float) -> void` — collision capsule; `visual` at `(0, -HEIGHT/2, ACTOR_Z)`; rig instanced hidden under the fighter; mirror under `visual`; hurtbox (layer 4, capsule); hitbox (layer 3, mask 4, `monitoring` on, shape disabled until active); `blade_light` (cyan `#39f3ff`, range 4, energy 0) at the blade tip area.
  - `_physics_process`: `vitals.advance`, `combat.advance` → on `started:<id>` play the animation; on `active_start` size/position the hitbox from the move (x × facing) and enable it; each physics frame while active, for every overlapping hurtbox owner not in `combat.hit_this_move` and not self → `HitResolver.resolve` → apply: HIT → `target.receive_hit(result, self)`, `HitStop.trigger(move.hit_stop)`, flash `blade_light` to energy 6 decaying to 0 over 0.25 s if `target.is_network`, emit `hit_landed`; PARRIED → `self.combat.stun(HitResolver.PARRY_STUN)`, play `hurt`. On `active_end`/`done` disable the hitbox. Dodge moves set horizontal velocity `dash_speed * facing` during ACTIVE. Gravity/walk via `PlayerMotor`; horizontal input ignored while a non-dodge move is in STARTUP/ACTIVE.
  - `func receive_hit(result: Dictionary, attacker: Fighter) -> void` — `vitals.take`, `velocity = Vector3(result.knockback.x, result.knockback.y, 0)` when knockback non-zero, `combat.stun(0.3)` + play `hurt` (or `staggered` when staggered), emit `got_hit`.
  - `func intent() -> Dictionary` — virtual: `{x: float, jump: bool, action: StringName}`.
- `Player extends Fighter`: `static func create() -> Player` builds with the placeholder rig/art and `player.tres` (hp 100, stagger 100) and keeps `autorun`; `intent()` reads input (`light_attack`→`light`, `heavy_attack`→`finisher` when a staggered enemy is within `FINISHER_RANGE` ahead else `heavy`, `launcher`, `parry`, `dodge`).

- [ ] **Step 1: Failing tests.** Replace `test_visual_sits_in_front_of_gameplay_plate` in `tests/player_test.gd` with:
```gdscript
func test_visual_sits_in_front_of_gameplay_plate() -> void:
	var p := Player.create()
	add_node(p)
	assert_true(p.visual.position.z >= WorldSpec.ACTOR_Z - 1e-6, "cutout visual at ACTOR_Z")
	assert_eq(p.mirror.quads.size(), 17, "all 17 cutout parts mirrored")
	for q: MeshInstance3D in p.mirror.quads.values():
		assert_true(p.visual.position.z + q.position.z > 0.0, "every part in front of z = 0")
	assert_true(p.axis_lock_linear_z, "z locked")
```
and extend `test_actions_registered_once` with `for action in [&"light_attack", &"heavy_attack", &"launcher", &"parry", &"dodge"]: assert_true(InputMap.has_action(action), …)`.

`tests/fighter_test.gd`:
```gdscript
extends TestCase
## Fighters hitting each other through Area3D hit/hurtboxes; hit-stop safety.


func _pair() -> Array:
	var a := Player.create()
	var b := Player.create()
	a.position = Vector3(0, 1.0, 0)
	b.position = Vector3(1.0, 1.0, 0)
	b.facing = -1.0
	add_node(a)
	add_node(b)
	return [a, b]


func _frames(n: int) -> void:
	for i in n:
		await tree.physics_frame


func test_light_attack_damages_target_once() -> void:
	var p := _pair()
	var a: Fighter = p[0]
	var b: Fighter = p[1]
	await _frames(2)
	a.combat.request(&"light")
	await _frames(60)
	assert_near(b.vitals.hp, 90.0, 1e-4, "exactly one light hit")


func test_one_hit_per_target_per_swing() -> void:
	var p := _pair()
	var a: Fighter = p[0]
	var b: Fighter = p[1]
	await _frames(2)
	a.combat.request(&"heavy") # 0.12 s active = ~14 physics frames overlapping
	await _frames(120)
	assert_near(b.vitals.hp, 75.0, 1e-4, "heavy lands once despite a long active window")


func test_parry_stuns_attacker_and_prevents_damage() -> void:
	var p := _pair()
	var a: Fighter = p[0]
	var b: Fighter = p[1]
	await _frames(2)
	b.combat.request(&"parry")
	a.combat.request(&"light")
	await _frames(30)
	assert_near(b.vitals.hp, 100.0, 1e-4, "no damage through a facing parry")
	assert_true(a.combat.is_stunned(), "attacker stunned")


func test_overlapping_hit_stops_restore_time_scale() -> void:
	HitStop.trigger(tree, 0.05)
	HitStop.trigger(tree, 0.10)
	await tree.create_timer(0.07, true, false, true).timeout
	assert_true(Engine.time_scale < 1.0, "still frozen by the longer stop")
	await tree.create_timer(0.08, true, false, true).timeout
	assert_near(Engine.time_scale, 1.0, 1e-6, "restored")
```
- [ ] **Step 2: Run** — failures (missing classes / old Player). **Step 3: Implement** in this order: `HitStop`, `GameInput` actions, `Fighter`, `Player` rewrite. **Step 4: Run** — all pass (including M1's level and camera tests). **Step 5: Commit** `feat: Fighter with cutout visual, hit/hurtboxes, hit-stop and blade light; Player on Fighter`.

---

### Task 8: Enemies — training dummy and security officer

**Files:** Create `scripts/enemies/enemy.gd`, `scripts/enemies/officer_brain.gd`, `scripts/enemies/training_dummy.gd`, `tests/enemy_test.gd`.

**Interfaces:**
- `class_name OfficerBrain extends RefCounted`; `enum State { IDLE, APPROACH, WINDUP, ATTACK, RECOVER }`; consts `SIGHT := 12.0`, `ATTACK_RANGE := 1.6`, `SPEED := 3.5`, `WINDUP := 0.45`, `RECOVER := 0.6`, `COOLDOWN := 1.2`; `func tick(dt: float, dx: float, stunned: bool) -> Dictionary` (`dx` = player x − officer x) → `{x: float (−1..1), face: float, windup: bool, attack: bool}`; stunned → IDLE and no output. Flow: IDLE→APPROACH when `|dx| < SIGHT`; APPROACH→WINDUP when `|dx| <= ATTACK_RANGE` and cooldown elapsed; WINDUP (emits `windup` true on entry) → after `WINDUP` emits `attack` → ATTACK until the move ends (caller reports via `attack_finished()`) → RECOVER for `RECOVER` → APPROACH.
- `class_name Enemy extends Fighter`: `var brain: OfficerBrain`, `is_network = true`; `static func create_officer() -> Enemy` (placeholder rig with `modulate = Color(1, 0.55, 0.55)` on the rig root, `officer.tres`, hp 60, stagger 40); `intent()` from the brain; on `windup` plays `windup` (shows the red glint).
- `class_name TrainingDummy extends Enemy`: brain none, never moves or attacks, hp 1e9, stagger 60; on `got_hit` spawns a `Label3D` damage number that floats up 0.6 m and frees after 0.8 s; `var last_numbers: Array[float]`.

- [ ] **Step 1: Failing tests** — `tests/enemy_test.gd`:
```gdscript
extends TestCase
## Officer brain flow, dummy feedback, finisher on a staggered enemy.


func _tick(b: OfficerBrain, seconds: float, dx: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in int(round(seconds * 120.0)):
		out.append(b.tick(1.0 / 120.0, dx, false))
	return out


func test_officer_ignores_far_player() -> void:
	var b := OfficerBrain.new()
	var outs := _tick(b, 0.5, 20.0)
	assert_eq(b.state, OfficerBrain.State.IDLE, "idle")
	assert_near(outs[-1].x, 0.0, 1e-6, "no movement")


func test_officer_approaches_then_telegraphs_then_attacks() -> void:
	var b := OfficerBrain.new()
	var outs := _tick(b, 0.1, 5.0)
	assert_eq(b.state, OfficerBrain.State.APPROACH, "approaching")
	assert_near(outs[-1].x, 1.0, 1e-6, "walks toward the player")
	outs = _tick(b, 0.05, 1.0)
	assert_eq(b.state, OfficerBrain.State.WINDUP, "winds up in range")
	assert_true(outs.any(func(o: Dictionary) -> bool: return o.windup), "telegraph emitted")
	outs = _tick(b, OfficerBrain.WINDUP, 1.0)
	assert_true(outs.any(func(o: Dictionary) -> bool: return o.attack), "attack after the wind-up")


func test_stunned_officer_does_nothing() -> void:
	var b := OfficerBrain.new()
	_tick(b, 0.1, 1.0)
	var out := b.tick(1.0 / 120.0, 1.0, true)
	assert_true(not out.attack and out.x == 0.0, "stunned: no action")


func test_dummy_shows_damage_numbers() -> void:
	var p := Player.create()
	var d := TrainingDummy.create_dummy()
	p.position = Vector3(0, 1.0, 0)
	d.position = Vector3(1.0, 1.0, 0)
	add_node(p)
	add_node(d)
	for i in 2:
		await tree.physics_frame
	p.combat.request(&"light")
	for i in 60:
		await tree.physics_frame
	assert_eq(d.last_numbers, [10.0] as Array[float], "one number for one hit")


func test_finisher_only_on_staggered_enemy() -> void:
	var p := Player.create()
	var e := Enemy.create_officer()
	p.position = Vector3(0, 1.0, 0)
	e.position = Vector3(1.2, 1.0, 0)
	add_node(p)
	add_node(e)
	e.brain = null # hold still
	await tree.physics_frame
	assert_eq(p.resolve_heavy_action(), &"heavy", "heavy when the enemy is not staggered")
	e.vitals.take(0.0, 1000.0)
	assert_eq(p.resolve_heavy_action(), &"finisher", "finisher on a staggered enemy in range")
```
(`TrainingDummy.create_dummy()` and `Player.resolve_heavy_action() -> StringName` are part of this task's interface.)
- [ ] **Steps 2–5:** run (fail) → implement → run (pass) → commit `feat: security officer with telegraphed attacks and a training dummy`.

---

### Task 9: Combat sandbox, visual check, docs

**Files:** Create `scripts/combat_sandbox.gd`, `scenes/level/combat_sandbox.tscn`, `tests/combat_sandbox_test.gd`. Modify `tools/capture.sh` (optional `--scene=<res path>` passed as `--` arg handled by `DebugCapture`? No — pass the scene path as Godot's first positional argument: `"$GODOT" --path . <scene> …`), spec §9/§10 (M2 status), art guide if anything changed.

**Sandbox:** arena section 38.4 × 12 m (2 screens wide) using the M1 plate/lighting code path with `ArtSizes`/`WorldSpec` for that size (reuse `test_level.gd` helpers by extracting them into `scripts/level_builder.gd` if needed — ledger it), a floor, player at x 6, dummy at x 14, officer at x 26, camera rig. User args: `--autorun` not used; `--demo` makes the player auto-attack every 0.6 s (for captures).

- [ ] **Step 1: Failing test** — `tests/combat_sandbox_test.gd`:
```gdscript
extends TestCase
## Sandbox builds with a player, a dummy and an officer inside the arena.


func test_sandbox_contents() -> void:
	var s = add_node(load("res://scenes/level/combat_sandbox.tscn").instantiate()) # untyped: script vars
	await tree.process_frame
	assert_true(s.player is Player, "player")
	assert_true(s.dummy is TrainingDummy, "dummy")
	assert_true(s.officer is Enemy, "officer")
	assert_true(s.officer.is_network, "officer is network-controlled (blade light)")
	assert_true(s.rig.camera.current, "camera")
```
- [ ] **Step 2: Run** (fail) → **Step 3: Implement** → **Step 4: Run** (pass).
- [ ] **Step 5: Visual check** — `bash tools/capture.sh sandbox 1920x1080 150 res://scenes/level/combat_sandbox.tscn --demo` and view the PNG: cutout fighter readable, parts correctly layered, lit by the scene lights, no gaps at joints; officer tinted red. Record results in the ledger.
- [ ] **Step 6: Docs** — spec §10: mark M2 complete with test count; note any rulings that changed the spec; art guide: add the placeholder fighter as the worked example of a parts sheet.
- [ ] **Step 7: Commit** `feat: combat sandbox; M2 complete`.

## Deferred (M3+)

Enemy variety beyond the officer, aerial juggle tuning, damage feedback UI (HP bars), audio, real character art, section chains, arena camera locks, importer plugin.
