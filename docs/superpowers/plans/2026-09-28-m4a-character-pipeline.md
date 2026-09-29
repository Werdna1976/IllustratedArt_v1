# M4a Character Pipeline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans (native execution). Same format ruling as M2/M3: tests complete, implementation specified by interfaces, data and formulas; deviations are ledgered `Ruling:` lines.

**Goal:** The user's painted player (23 parts in `C:\ART\IMAGES\PLAYER\player_parts`) fights in the game as a two-handed katana cutout, with swappable hands and heads and diagonal slashes, built by a data-driven pipeline any future character drops into.

**Architecture:** `pack_parts.py` turns a folder of part PNGs (+ optional `manifest.json` joint data, `_emit` masks) into a character folder (`parts.png`, `parts_emit.png`, `parts_n.png`, `parts.json`, `pivots.json`). `make_rig.gd` builds a rig scene from that folder + one shared skeleton definition (`data/rigs/humanoid.json`) + per-character overrides (`rig_overrides.json`: limb lengths, sprite scales). Bones are `Node2D`s (animated); each carries a `Sprite` child (`PartSwap`, a `Sprite2D` that switches between variant regions) so limb stretching never propagates to children. `CutoutIK` pins the far hand to the katana's rear grip with a two-bone solve after the animation each frame. `make_animations.gd` writes one shared `AnimationLibrary` (`data/animations/humanoid.tres`) from pose tables for the player and the officer.

**Spec:** technical spec §5.6–5.7; `docs/art/player-character-brief.md`; user feedback 2026-09-28: *slashes must look good; diagonal front cuts (high→low, low→high); no overhead swings.*

## Global Constraints

- M1–M3 constraints hold. Rig space: px, origin at the feet, +Y down, 400 px/m.
- Bone rotation 0 = the part hanging straight down (limbs) / upright (torso, head). Screen-clockwise is positive, so **negative arm rotation swings the arm forward (right)**.
- Swap groups: head `[head, head_attack, head_hurt]`; each hand `[hand_grip_*, hand_fist_*, hand_open_*]` (default grip).
- Katana: pivot = near-hand grip (105, 16); tip = 335 px along +x from the pivot; far-hand grip = −70 px along +x.
- Player limb joint-to-joint targets (from the user's approved assembly): thigh 158, shin 159, arm_upper 107, arm_lower 96 px; saya sprite scale (0.68, 1).
- Blade signature colour: lime `#c8ff3a` (was cyan).
- The officer shares the skeleton and animation library; its weapon slot holds a stun baton.

## Review Focus

1. **Overhead / non-diagonal slashes** — every attack animation's blade tip must travel diagonally in front of the body and never swing behind the head. Pinned by Task 6 `test_slashes_are_diagonal_and_never_overhead`.
2. **Far hand leaving the grip** — with IK on, the far hand must sit on the katana's rear grip in every sampled frame of two-handed moves. Pinned by Task 4 `test_far_hand_reaches_the_grip`.
3. **Stretched limb children** — stretching a limb sprite must not stretch the parts below it. Pinned by Task 5 `test_stretch_applies_to_sprite_not_children`.
4. **Missing parts or wrong sizes in a delivery** — the packer must report them and still produce a usable sheet. Pinned by Task 1 `test_missing_and_wrong_size_parts_are_reported`.
5. **Swap parts not updating in 3D** — changing a hand or head variant must change the mirrored quad's UVs the same frame. Pinned by Task 3 `test_variant_change_updates_mirrored_uvs`.

---

### Task 1: pack_parts.py
**Files:** `tools/art/pack_parts.py`, `tools/art/test_pack_parts.py`.
**Interface:** `pack_parts.py <parts_dir> <char_dir>` → `parts.png` (2048², shelf-packed, 16 px padding), `parts_emit.png` (provided `_emit` masks at the same rects, black elsewhere), `parts.json` `{name: [x,y,w,h]}`, `pivots.json` `{name: {"pivot": [x,y], "distal": [x,y]|null}}` (from `manifest.json` `recommended_joint_center` / `distal_joint_center` when present, else brief defaults: limbs `(w/2, 25)`→`(w/2, h-25)`, head `(w/2, h-4)`, torso `(w/2, h-12)`, pelvis centre, hands `(w/2, 8)`, feet `(25, h/2)`, katana `(105, h/2)`, saya `(120, h/2)`); then `make_maps.main([parts.png, "--if-stale"])`. Prints `OK <part>` / `WARN <part>: <reason>` (missing, size ≠ brief); `main()` returns the number of warnings. `BRIEF` = the brief's 23-part size table (+ optional `glint` 40×40).
- [ ] Tests (`tools/art/test_pack_parts.py`):
```python
import json, os, sys, tempfile, unittest
import numpy as np
from PIL import Image
sys.path.insert(0, os.path.dirname(__file__))
import pack_parts


def part(d, name, size, rgba=(200, 50, 50, 255)):
    Image.new("RGBA", size, rgba).save(os.path.join(d, name + ".png"))


class PackPartsTest(unittest.TestCase):
    def test_packs_parts_with_rects_pivots_and_emit(self):
        with tempfile.TemporaryDirectory() as d:
            src, out = os.path.join(d, "parts"), os.path.join(d, "char")
            os.makedirs(src)
            part(src, "thigh_near", (60, 170))
            part(src, "katana", (440, 32))
            part(src, "katana_emit", (440, 32), (0, 255, 0, 255))
            json.dump({"assets": {"thigh_near.png": {"recommended_joint_center": [30, 25], "distal_joint_center": [30, 145]}}},
                      open(os.path.join(src, "manifest.json"), "w"))
            pack_parts.main([src, out])
            rects = json.load(open(os.path.join(out, "parts.json")))
            self.assertEqual(rects["katana"][2:], [440, 32])
            pivots = json.load(open(os.path.join(out, "pivots.json")))
            self.assertEqual(pivots["thigh_near"], {"pivot": [30, 25], "distal": [30, 145]})
            self.assertEqual(pivots["katana"]["pivot"], [105, 16])  # brief default
            sheet = np.asarray(Image.open(os.path.join(out, "parts.png")))
            emit = np.asarray(Image.open(os.path.join(out, "parts_emit.png")))
            self.assertEqual(sheet.shape[:2], (2048, 2048))
            kx, ky, kw, kh = rects["katana"]
            self.assertEqual(tuple(emit[ky + 5, kx + 5, :3]), (0, 255, 0))
            tx, ty = rects["thigh_near"][:2]
            self.assertEqual(int(emit[ty + 5, tx + 5, :3].max()), 0)  # no mask -> no glow
            self.assertTrue(os.path.exists(os.path.join(out, "parts_n.png")))

    def test_missing_and_wrong_size_parts_are_reported(self):
        with tempfile.TemporaryDirectory() as d:
            src, out = os.path.join(d, "parts"), os.path.join(d, "char")
            os.makedirs(src)
            part(src, "torso", (100, 200))  # brief says 110 x 230
            warnings = pack_parts.main([src, out])
            self.assertGreaterEqual(warnings, 22)  # 22 missing + 1 wrong size
            self.assertIn("torso", json.load(open(os.path.join(out, "parts.json"))))


if __name__ == "__main__":
    unittest.main()
```
- [ ] Run (fail) → implement → run (pass) → run on the real delivery: `python tools/art/pack_parts.py C:/ART/IMAGES/PLAYER/player_parts art/characters/player` (expect 0 warnings) and copy `reference.png`, `manifest.json`, previews to `art/_source/player/` → commit.

### Task 2: Officer placeholder in the standard layout
**Files:** replace `tools/art/make_placeholder_fighter.py` with `tools/art/make_placeholder_character.py <parts_dir> [--palette officer|player]` writing the 23 standard part PNGs + `glint.png` (officer: navy uniform, red status lights, stun baton drawn in the katana canvas: 260 px dark rod, red tip glow via `katana_emit.png`). Update its test in `tools/art/test_art_tools.py` (all 24 files at brief sizes). Generate → `pack_parts.py` → `art/characters/officer/`. Remove `art/characters/placeholder_fighter/` once Task 7 switches enemies over.

### Task 3: PartSwap and live mirror regions
**Files:** `scripts/cutout/part_swap.gd`, modify `scripts/cutout/cutout_mirror.gd`, `tests/cutout_mirror_test.gd`.
**Interface:** `class_name PartSwap extends Sprite2D`; `@export var variants: Dictionary` (StringName → Rect2); `@export var variant: StringName` (setter sets `region_rect`); `@export var offsets: Dictionary` (StringName → Vector2, per-variant sprite offset from that variant's pivot). `CutoutMirror.sync()` recomputes a quad's UV scale/offset whenever its sprite's `region_rect` changed.
- [ ] Test (append):
```gdscript


func test_variant_change_updates_mirrored_uvs() -> void:
	var rig := Node2D.new()
	rig.visible = false
	var hand := PartSwap.new()
	hand.region_enabled = true
	hand.variants = {&"grip": Rect2(0, 0, 20, 20), &"fist": Rect2(100, 50, 20, 20)}
	hand.offsets = {&"grip": Vector2.ZERO, &"fist": Vector2.ZERO}
	hand.variant = &"grip"
	rig.add_child(hand)
	var mirror := CutoutMirror.new()
	add_node(rig)
	add_node(mirror)
	mirror.setup(rig, _atlas(), null, null)
	hand.variant = &"fist"
	mirror.sync()
	var mat := (mirror.quads[hand] as MeshInstance3D).material_override as StandardMaterial3D
	assert_near(mat.uv1_offset.x, 100.0 / 200.0, 1e-6, "uv follows the fist region")
	assert_near(mat.uv1_offset.y, 50.0 / 100.0, 1e-6, "uv y")
```

### Task 4: Two-bone IK
**Files:** `scripts/cutout/two_bone_ik.gd` (pure), `scripts/cutout/cutout_ik.gd` (node), `tests/ik_test.gd`.
**Interface:** `TwoBoneIK.solve(root: Vector2, target: Vector2, len_a: float, len_b: float, bend: float) -> PackedFloat32Array` → global segment angles `[a, b]` (radians, screen convention, 0 = +x); unreachable targets clamp to a straight reach. `class_name CutoutIK extends Node2D`: `upper`, `lower`, `hand`, `target` (`Node2D` refs, `target` = the katana's `FarGrip` marker), `weight := 1.0` (animatable), `bend := 1.0`; `apply()` (called in `_process`, `process_priority = 100`) blends each far-arm bone's animated rotation toward the IK rotation by `weight` and aligns the hand with the katana. Rest direction of limb bones is +y (π/2).
- [ ] Tests:
```gdscript
extends TestCase
## Two-bone IK: pure solve plus the far-arm node reaching the katana grip.


func test_solve_reaches_a_reachable_target() -> void:
	var angles := TwoBoneIK.solve(Vector2.ZERO, Vector2(120, 60), 100.0, 80.0, 1.0)
	var elbow := Vector2.from_angle(angles[0]) * 100.0
	var wrist := elbow + Vector2.from_angle(angles[1]) * 80.0
	assert_near(wrist.distance_to(Vector2(120, 60)), 0.0, 0.01, "wrist on target")


func test_solve_unreachable_points_straight_at_target() -> void:
	var angles := TwoBoneIK.solve(Vector2.ZERO, Vector2(500, 0), 100.0, 80.0, 1.0)
	assert_near(angles[0], 0.0, 1e-4, "upper straight")
	assert_near(angles[1], 0.0, 1e-4, "lower straight")


func test_bend_direction_flips_the_elbow() -> void:
	var up := TwoBoneIK.solve(Vector2.ZERO, Vector2(120, 0), 100.0, 80.0, 1.0)
	var down := TwoBoneIK.solve(Vector2.ZERO, Vector2(120, 0), 100.0, 80.0, -1.0)
	assert_true(signf(sin(up[0])) != signf(sin(down[0])), "elbow on opposite sides")


func test_far_hand_reaches_the_grip() -> void:
	var rig: Node2D = add_node(load("res://scenes/characters/player_rig.tscn").instantiate())
	var ap: AnimationPlayer = rig.get_node("AnimationPlayer")
	var ik: CutoutIK = rig.get_node("CutoutIK")
	for anim_name in ["idle", "light1", "light2", "heavy", "parry"]:
		ap.play(anim_name)
		for t in [0.0, 0.1, 0.2]:
			ap.seek(t, true)
			ik.apply()
			var hand_pos := (rig.get_global_transform().affine_inverse() * ik.hand.get_global_transform()).origin
			var grip_pos := (rig.get_global_transform().affine_inverse() * ik.target.get_global_transform()).origin
			assert_true(hand_pos.distance_to(grip_pos) < 6.0, "%s @%.1f: far hand %.1f px from the grip" % [anim_name, t, hand_pos.distance_to(grip_pos)])
```

### Task 5: Skeleton definition and make_rig
**Files:** `data/rigs/humanoid.json`, `tools/make_rig.gd`, `art/characters/player/rig_overrides.json`, `tests/rig_test.gd`; generated `scenes/characters/player_rig.tscn`, `scenes/characters/officer_rig.tscn`.
**humanoid.json** — nodes in build order: `{name, part, variants?, parent, attach, z}`; `attach` is a point in the **parent's canvas** px, or `"distal"` (the parent part's distal joint):

| name | part | parent | attach | z |
|---|---|---|---|---|
| Pelvis | pelvis | (root) | — | 0 |
| Saya | saya | Torso | [20, 40], rotation 112° | −3 |
| ThighFar / ThighNear | thigh_far / thigh_near | Pelvis | [45, 50] / [55, 50] | −1 / 2 |
| ShinFar / ShinNear | shin_* | Thigh* | distal | −1 / 2 |
| FootFar / FootNear | foot_* | Shin* | distal | −1 / 2 |
| Torso | torso | Pelvis | [50, 20] | 1 |
| Head | head (swap: head, head_attack, head_hurt) | Torso | [60, 12] | 2 |
| Glint | glint (optional; hidden) | Head | [70, 40] | 6 |
| ArmUpperFar / ArmUpperNear | arm_upper_* | Torso | [48, 40] / [58, 40] | −2 / 3 |
| ArmLowerFar / ArmLowerNear | arm_lower_* | ArmUpper* | distal | −2 / 3 |
| HandFar / HandNear | hand swap group (default grip) | ArmLower* | distal | −2 / 3 |
| Katana | katana | HandNear | [22.5, 26] (fist centre) | 4 |
| Markers | `Katana/Tip` at (335, 0); `Katana/FarGrip` at (−70, 0) | | | |

Each bone is a `Node2D` named as above with a `Sprite` (`PartSwap`) child: `offset = canvas/2 − pivot`; `scale.y = target_length / (distal.y − pivot.y)` when the override sets a length for that part family (children of the bone attach at the scaled distal: `position = (distal − pivot) * scale`); sprite scale overrides (e.g. saya) apply to the sprite only. After building, the Pelvis is lifted so the lowest foot pixel sits at y = 0. The rig also contains `CutoutIK` (far arm → `Katana/FarGrip`) and an `AnimationPlayer` with library `""` = `data/animations/humanoid.tres` (Task 6).
- [ ] Tests (`tests/rig_test.gd`):
```gdscript
extends TestCase
## Rigs built from part data: structure, proportions, attachments.

const PLAYER := "res://scenes/characters/player_rig.tscn"


func _rel(rig: Node2D, node: Node2D) -> Vector2:
	return (rig.get_global_transform().affine_inverse() * node.get_global_transform()).origin


func test_player_rig_structure() -> void:
	var rig: Node2D = add_node(load(PLAYER).instantiate())
	for path in ["Pelvis/Torso/Head", "Pelvis/Torso/ArmUpperNear/ArmLowerNear/HandNear/Katana/Tip",
			"Pelvis/Torso/ArmUpperFar/ArmLowerFar/HandFar", "Pelvis/Torso/Saya", "Pelvis/ThighNear/ShinNear/FootNear",
			"CutoutIK", "AnimationPlayer"]:
		assert_true(rig.has_node(path), "has %s" % path)
	assert_true(rig.get_node("Pelvis/Torso/Head/Sprite") is PartSwap, "head swaps")
	assert_eq((rig.get_node("Pelvis/Torso/Head/Sprite") as PartSwap).variants.size(), 3, "three heads")


func test_proportions_match_the_approved_assembly() -> void:
	var rig: Node2D = add_node(load(PLAYER).instantiate())
	var ap: AnimationPlayer = rig.get_node("AnimationPlayer")
	ap.play(&"RESET")
	ap.seek(0.0, true)
	var head_top := _rel(rig, rig.get_node("Pelvis/Torso/Head")).y - 106.0
	assert_near(head_top, -720.0, 40.0, "about 720 px tall")
	var foot := _rel(rig, rig.get_node("Pelvis/ThighNear/ShinNear/FootNear"))
	assert_near(foot.y, -20.0, 12.0, "ankle just above the ground line")


func test_stretch_applies_to_sprite_not_children() -> void:
	var rig: Node2D = add_node(load(PLAYER).instantiate())
	var thigh: Node2D = rig.get_node("Pelvis/ThighNear")
	assert_near(thigh.scale.y, 1.0, 1e-6, "bone itself unscaled")
	assert_true((thigh.get_node("Sprite") as Node2D).scale.y > 1.2, "thigh sprite stretched to the approved length")
	assert_near((thigh.get_node("ShinNear/Sprite") as Node2D).global_scale.y / (thigh.get_node("ShinNear/Sprite") as Node2D).scale.y, 1.0, 1e-4, "shin inherits no stretch")
```
(`RESET` = the library's rest pose, generated in Task 6; until then the test uses the default pose.)

### Task 6: Diagonal-slash animation library
**Files:** `tools/make_animations.gd`, `data/animations/humanoid.tres`, `tests/animation_test.gd`.
**Pose model:** each key sets `torso`, `arm` (near upper-arm rotation), `elbow`, `blade` (**global** katana direction, 0 = pointing right, −90 = up), optional `head` variant, `far_hand` variant, `ik` weight, legs (`thigh_near`, `shin_near`, `thigh_far`, `shin_far`). The generator converts `blade` to the katana's local rotation (`blade − torso − arm − elbow`). All angles in degrees in the table, radians in the resource. Lengths match `data/moves/player.tres` / `officer.tres`. Head variant: `head_attack` from 0 to the end of active for attacks, `head_hurt` for hurt/staggered, else `head`. Far hand `grip` when `ik` = 1, `open` otherwise.

| Anim | Key times → (torso, arm, elbow, blade) | Intent |
|---|---|---|
| RESET / idle (loop 1.2) | guard: (6, −35, −45, −40); idle breathes torso 6→8→6 | two-handed guard, blade up-forward |
| run (loop 0.5) | (10, −20, −20, 150), legs as M2; ik 0 | one-handed, blade trailing low behind |
| jump / fall (0.2) | guard, legs tucked / arms slightly up | |
| light1 (.34) | 0 (−4, −115, −20, −65) → .08 (−2, −110, −20, −55) → .16 (10, −15, −30, 35) → .34 guard | **high → low** diagonal |
| light2 (.36) | 0 (10, −15, −30, 35) → .08 (10, −18, −30, 40) → .16 (0, −130, −15, −70) → .36 guard | **low → high** diagonal |
| light3 (.52) | 0 (−6, 5, −40, 70) → .12 (−6, 0, −40, 65) → .22 (12, −140, −10, −80) → .52 guard | wide low → high finish |
| heavy (.82) | 0 (−10, −125, −30, −80) → .30 (−12, −130, −30, −88) → .42 (16, 0, −20, 50) → .82 guard | power **high → low** diagonal from shoulder height (no overhead) |
| launcher (.63) | 0 (−8, 15, −50, 80) → .18 (−8, 20, −50, 88) → .28 (10, −150, −5, −95) → .63 guard | **rising low → high** |
| air_light (.31) | 0 (0, −110, −20, −50) → .06 same → .16 (8, −20, −30, 40) → .31 guard | quick high → low |
| finisher (.80) | 0 (−10, 10, −40, 75) → .10 (−10, 12, −40, 80) → .30 (14, −150, −10, −95) → .55 (18, −10, −30, 40) → .80 guard | rising cut then a descending return cut |
| parry (.42) | 0..0.42 (0, −70, −40, −80) | katana upright in front, block |
| dodge (.37) | torso 0→−25→0, guard arms | |
| hurt (.30) | torso 0→−15→0, head_hurt | |
| staggered (loop 1.0) | (25, 10, −10, 80), head_hurt, ik 0 | slumped, blade down |
| windup (.45, officer) | guard → (−4, −115, −20, −60), glint visible | raised telegraph (in front) |
| officer_attack (.75) | (−4, −115, −20, −60) → .15 (10, −15, −30, 35) → .75 guard | high → low |

- [ ] Tests (`tests/animation_test.gd`):
```gdscript
extends TestCase
## The shared library: lengths match moves, and every slash is a diagonal front cut.

const PLAYER := "res://scenes/characters/player_rig.tscn"
const ATTACKS := [&"light1", &"light2", &"light3", &"heavy", &"launcher", &"air_light", &"finisher"]


func _tip(rig: Node2D) -> Vector2:
	return (rig.get_global_transform().affine_inverse() * rig.get_node("Pelvis/Torso/ArmUpperNear/ArmLowerNear/HandNear/Katana/Tip").get_global_transform()).origin


func test_lengths_match_move_data() -> void:
	var rig: Node2D = add_node(load(PLAYER).instantiate())
	var ap: AnimationPlayer = rig.get_node("AnimationPlayer")
	var moves: MoveSet = load("res://data/moves/player.tres")
	for m: MoveData in moves.moves:
		assert_near(ap.get_animation(m.anim).length, m.total(), 1e-3, "%s length" % m.id)


func test_slashes_are_diagonal_and_never_overhead() -> void:
	var rig: Node2D = add_node(load(PLAYER).instantiate())
	var ap: AnimationPlayer = rig.get_node("AnimationPlayer")
	var moves: MoveSet = load("res://data/moves/player.tres")
	for id in ATTACKS:
		var m := moves.get_move(id)
		ap.play(m.anim)
		ap.seek(m.startup, true)
		var a := _tip(rig)
		ap.seek(m.startup + m.active, true)
		var b := _tip(rig)
		var d := b - a
		assert_true(absf(d.y) > 150.0, "%s: tip travels vertically (%.0f px)" % [id, d.y])
		assert_true(absf(d.y) > 0.4 * absf(d.x), "%s: diagonal, not a flat sweep" % id)
		for i in 21:
			ap.seek(m.total() * i / 20.0, true)
			var tip := _tip(rig)
			assert_true(not (tip.x < -60.0 and tip.y < -620.0), "%s @%.2f: blade behind the head (overhead)" % [id, m.total() * i / 20.0])


func test_tracks_resolve_on_both_rigs() -> void:
	for path in [PLAYER, "res://scenes/characters/officer_rig.tscn"]:
		var rig: Node2D = add_node(load(path).instantiate())
		var ap: AnimationPlayer = rig.get_node("AnimationPlayer")
		for anim_name in ap.get_animation_list():
			var anim := ap.get_animation(anim_name)
			for t in anim.get_track_count():
				var np := anim.track_get_path(t)
				assert_true(rig.has_node(NodePath(np.get_concatenated_names())), "%s: %s resolves on %s" % [anim_name, np, path])
```

### Task 7: Integration, colour, cleanup, verification, docs
- `Player` uses `player_rig.tscn` + `art/characters/player/parts*.png`; `Enemy.create_officer()`/`TrainingDummy` use `officer_rig.tscn` + officer art (no runtime tint); `CutoutMirror.process_priority = 200` (after IK); `Fighter.BLADE_COLOR` → `#c8ff3a`; retune the move hitboxes to the katana's reach if the captures show a mismatch (ledger any change).
- Remove `placeholder_fighter` art, `make_placeholder_rig.gd`, `tests/placeholder_rig_test.gd`; update `tests/player_test.gd` (quad count from the new rig), `tests/move_data_test.gd` (rig path).
- Verification: captures of the sandbox (guard), mid-`light1`, mid-`light2`, `parry`, facing left; probe that the far hand overlaps the grip in screen space.
- Docs: spec §5.6 (bones + PartSwap + IK + pack/rig tools), §9 tooling rows; brief §4 note that future characters use **longer limb canvases** (thigh/shin 60/50 × 210, upper/lower arm 50/45 × 160/150) so no stretch is needed; game design blade colour → lime.

## Deferred
Real officer art, HUD, audio, the M2/M3 minor list, attack-specific slash VFX trails (strong candidate for M4b — "slashes look good").
