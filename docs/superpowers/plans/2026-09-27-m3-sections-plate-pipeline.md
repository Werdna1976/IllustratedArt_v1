# M3 Sections & Plate Pipeline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans (native execution). Steps use checkbox (`- [ ]`) syntax.
>
> **Plan format (token-efficiency ruling, as in M2):** tests are complete code; implementation is specified by interfaces, formulas and data, and written test-first during execution. Deviations go in the ledger as `Ruling:` lines.

**Goal:** Level 1 (*The Last Train*) playable end-to-end as a greybox — station section with a squad arena, then the train-roof run through a looping tunnel — where every placeholder layer is replaced automatically by the user's art once they drop PNGs into `art/levels/<section>/` and run one import command.

**Architecture:** A section is a folder: `section.json` (metres; gameplay data) plus layer PNGs (plate px). `tools/import_art.sh` slices plates into BC7 strips with a manifest, traces collision masks and imports. At runtime `SectionDef` reads the folder, `Section` builds plates (static `PlateLayer` or scrolling `LoopingLayer`, placeholders where art is missing), collision, lights, props, weather, enemies and `ArenaZone`s; `LevelRunner` chains sections with fades and handles death/respawn. `CameraRig` gains lockable bounds.

**Tech Stack:** Godot 4.7.2 GDScript, Python 3.14 (Pillow, numpy), existing test runner.

**Spec:** `docs/superpowers/specs/2026-09-27-illustrated-platformer-design.md` (§3.1 sections, §4.1 looping plates, §5.1–5.4, §7), `docs/superpowers/specs/2026-09-27-ghostline-game-design.md` (Level 1), `docs/art/level1-art-brief.md`.

## Global Constraints

- Everything from the M1/M2 Global Constraints still holds.
- Section folder: `art/levels/<id>/` with `section.json`, optional layer PNGs (`sky far mid near gameplay` static; `mid_loop near_loop fg_loop` looping; `fg_<name>.png` props) and companions (`_n`, `_emit`), optional `gameplay_collision.json` (plate px, from `compose_plate.py`) and `gameplay_solid.png` (white = solid). Generated: `_strips/` (git-ignored; rebuilt by `tools/import_art.sh`).
- Plate px ↔ world metres for a layer at depth z in a section of size S: `plate = WorldSpec.plate_rect(z, S)`, `x_m = plate.position.x + px / density(z)`, `y_m = plate.end.y - py / density(z)` (py measured from the image top).
- `section.json` schema (all metres; every key optional except `size_m`):
```json
{"size_m": [134.4, 16.2], "type": "horizontal|vertical|arena|vehicle",
 "env": {"background": "#07080c", "fog": "#1b1f2e", "fog_density": 0.008,
         "ambient": "#2a3040", "ambient_energy": 0.45, "sun": "#5060a0", "sun_energy": 0.25},
 "placeholder": {"sky": ["#0b0d14", "#161a26", 0.0], "gameplay": ["#3a3440", "#1c1a22", 0.8]},
 "spawn": [4.0, 2.5], "exit": [131.4, 1.0, 2.4, 6.0],
 "collision": [[0, 0, 134.4, 1.0]],
 "lights": [{"pos": [30, 5, 1.5], "color": "#ffb45e", "range": 7, "energy": 4, "flicker": 0.0}],
 "light_rows": [{"from": 8, "to": 130, "step": 12, "y": 12.8, "z": 1.5, "color": "#cfe8ff", "range": 8, "energy": 2.5, "flicker": 0.3}],
 "props": [{"image": "fg_pillar.png", "x": 15.0, "y": -3.0}],
 "enemies": [{"type": "officer", "x": 55.0}],
 "arenas": [{"rect": [103.2, 0, 28.8, 16.2], "enemies": [{"type": "officer", "x": 118.0}]}],
 "weather": {"rain": false, "lightning": false},
 "flicker_layers": ["gameplay"], "loop_speed": 30.0, "loop_ramp_s": 6.0}
```
- New collision layer use: arena barriers are world (layer 1) bodies; arena detection areas mask layer 2 (actors).
- Level 1 = `["res://art/levels/l1_station", "res://art/levels/l1_train"]`.

## Review Focus

1. **Art missing or partial** — a section with only some PNGs must still build: missing layers fall back to placeholders, never a crash or a hole. Pinned by Task 6 `test_missing_art_falls_back_to_placeholders`.
2. **Loop seams / gaps while scrolling** — looping layers must cover the view at every scroll offset. Pinned by Task 3 `test_copies_cover_the_plate_span_at_any_offset` and `test_placeholder_loops_are_seamless`.
3. **Dying inside an arena** — respawn must not leave the camera locked, walls up with no enemies, or the player stuck; the arena resets. Pinned by Task 8 `test_death_in_arena_resets_it`.
4. **Re-running the importer** — unchanged sections are skipped; changed sources are re-sliced; stale strips from a narrower plate are removed. Pinned by Task 4 `test_second_run_skips_unchanged_sections` and `test_reimport_removes_stale_strips`.
5. **Dead enemies still interactive** (M2 deferred minor, now load-bearing for arenas) — a dead enemy leaves the `enemies` group, stops being hittable and counts as cleared immediately. Pinned by Task 7 `test_dead_enemy_is_untargetable`.

---

## File Structure

| File | Responsibility |
|---|---|
| `scripts/plate_layer.gd` (modify) | Normal/glow maps per strip; `set_glow()` |
| `scripts/world_spec.gd` (modify) | `clamp_to_rect()` |
| `scripts/camera_rig.gd` (modify) | `lock_to()/unlock()/current_bounds()/locked_rect()/is_locked()` |
| `scripts/looping_layer.gd` | Wrapping, scrolling plate layer |
| `scripts/placeholder_plate.gd` (modify) | `period_px` for seamless placeholder loops |
| `tools/art/import_art.py`, `tools/import_art.sh` | Slice → strips + manifest + `.import`; trace solid masks; one-command import |
| `scripts/sections/section_def.gd` | Parse a section folder |
| `scripts/sections/section.gd` | Build a section at runtime |
| `scripts/sections/arena_zone.gd` | Arena lock, spawns, barriers, clear |
| `scripts/sections/level_runner.gd`, `scenes/level/level_1.tscn` | Section chain, fades, respawn, completion |
| `scripts/fx/weather.gd`, `scripts/fx/flicker.gd` | Rain, lightning, glow/light flicker |
| `scripts/fighter.gd`, `scripts/enemies/enemy.gd` (modify) | `died` signal; dead enemies untargetable |
| `art/levels/l1_station/section.json`, `art/levels/l1_train/section.json` | Level 1 greybox data |
| `scripts/ui/title_screen.gd` (modify) | START → Level 1; COMBAT SANDBOX; QUIT |

---

### Task 1: Plate companion maps and glow control

**Files:** Modify `scripts/plate_layer.gd`, `tests/plate_layer_test.gd`.

**Interfaces:** `build(p_depth, strips, lit, level_size := WorldSpec.LEVEL_SIZE, fog := true, normals: Array[Texture2D] = [], emissives: Array[Texture2D] = [])` (companion arrays match `strips` index-for-index or are empty); `static make_material(tex, lit, fog, normal: Texture2D = null, emissive: Texture2D = null)` — emission uses `EMISSION_OP_MULTIPLY` with white (lesson from M2); `func set_glow(energy: float)` sets `emission_energy_multiplier` on every strip material.

- [ ] **Step 1: Failing tests** — append to `tests/plate_layer_test.gd`:
```gdscript


func test_companion_maps_on_plate_materials() -> void:
	var tex := ImageTexture.create_from_image(Image.create_empty(4, 4, false, Image.FORMAT_RGBA8))
	var mat := PlateLayer.make_material(tex, true, true, tex, tex)
	assert_true(mat.normal_enabled and mat.normal_texture == tex, "normal map")
	assert_true(mat.emission_enabled and mat.emission_texture == tex, "glow map")
	assert_eq(mat.emission_operator, BaseMaterial3D.EMISSION_OP_MULTIPLY, "glow comes from the mask only")


func test_set_glow_scales_every_strip() -> void:
	var depth := 100.0
	var strips := _blank_strips(depth)
	var layer := PlateLayer.new()
	layer.build(depth, strips, false, WorldSpec.LEVEL_SIZE, true, [], strips)
	layer.set_glow(0.4)
	for mi: MeshInstance3D in layer.get_children():
		assert_near((mi.material_override as StandardMaterial3D).emission_energy_multiplier, 0.4, 1e-6, "glow energy")
	layer.free()
```
- [ ] **Steps 2–5:** run (fail) → implement → run (pass) → commit `feat: plate normal/glow maps and glow control`.

---

### Task 2: Lockable camera bounds

**Files:** Modify `scripts/world_spec.gd`, `scripts/camera_rig.gd`, `tests/camera_rig_test.gd`.

**Interfaces:**
- `WorldSpec.clamp_to_rect(center: Vector2, aspect: float, rect: Rect2) -> Vector2` — like `clamp_camera_center` but for any rect; on an axis where the view is larger than the rect, returns the rect's centre on that axis. `clamp_camera_center` delegates to it with `Rect2(Vector2.ZERO, level_size)`.
- `CameraRig`: `func lock_to(rect: Rect2, blend := 0.5)`, `func unlock(blend := 0.5)`, `func current_bounds() -> Rect2` (blends linearly from the bounds at call time to the target over `blend` s, exactly the target when done), `func locked_rect() -> Rect2` (target of the active lock or `Rect2()`), `func is_locked() -> bool`. All clamping (`snap_to_target`, `_physics_process`, `apply_projection`) uses `current_bounds()`.

- [ ] **Step 1: Failing tests** — append to `tests/camera_rig_test.gd`:
```gdscript


func test_clamp_to_rect_centres_when_rect_smaller_than_view() -> void:
	var c := WorldSpec.clamp_to_rect(Vector2(0, 0), 16.0 / 9.0, Rect2(100, 0, 10, 5))
	assert_near(c.x, 105.0, 1e-4, "centred x")
	assert_near(c.y, 2.5, 1e-4, "centred y")


func test_lock_blends_to_arena_and_unlock_restores() -> void:
	var rig := _rig(Vector3(60, 5, 0), 16.0 / 9.0)
	rig.snap_to_target()
	var arena := Rect2(100, 0, 28.8, 16.2)
	rig.lock_to(arena, 0.5)
	assert_true(rig.is_locked(), "locked")
	for i in 120:
		rig._physics_process(1.0 / 60.0)
	assert_eq(rig.current_bounds(), arena, "bounds reach the arena after the blend")
	assert_true(rig.position.x >= 100.0 + 9.6 - 0.05, "camera moved inside the arena")
	rig.unlock(0.5)
	for i in 60:
		rig._physics_process(1.0 / 60.0)
	assert_true(not rig.is_locked(), "unlocked")
	assert_eq(rig.current_bounds(), Rect2(Vector2.ZERO, rig.level_size), "back to the section bounds")
```
- [ ] **Steps 2–5:** run (fail) → implement → run (pass, including all M1/M2 camera tests) → commit `feat: lockable camera bounds with blend`.

---

### Task 3: LoopingLayer and seamless placeholder loops

**Files:** Create `scripts/looping_layer.gd`, `tests/looping_layer_test.gd`. Modify `scripts/placeholder_plate.gd`.

**Interfaces:**
- `class_name LoopingLayer extends Node3D`: `var depth`, `var tile_width: float` (m = sum of strip widths / density), `var offset := 0.0` (m, in `[0, tile_width)`), `var speed := 0.0` (m/s, world scroll; parallax comes from depth), `var copies: Array[Node3D]` (each holds one full tile of strip quads); `func setup(p_depth: float, strips: Array[Texture2D], lit: bool, fog: bool, section_size: Vector2, normals: Array[Texture2D] = [], emissives: Array[Texture2D] = [])` sets `position.z = -depth`, builds `ceil(span.x / tile_width) + 1` copies where `span = WorldSpec.plate_rect(depth, section_size)`, bottom-aligned to `span.position.y`, then `layout()`; `func layout()` places copy i at `x = span.position.x - offset + i * tile_width`; `func advance(dt: float)` → `offset = fposmod(offset + speed * dt, tile_width)` then `layout()`; `_process` calls `advance`. `func set_glow(energy)` like `PlateLayer`.
- `PlaceholderPlate.generate_strip(…, fill_from, period_px := 0)` — when `period_px > 0`, the silhouette wavelength becomes `period_px / max(1, round(period_px / (12 * px_per_m)))` so the pattern repeats exactly every `period_px`; grid lines are unaffected (they already repeat every metre; loop widths are multiples of 64 px, not of a metre, so vertical grid lines are omitted when `period_px > 0`).

- [ ] **Step 1: Failing tests** — `tests/looping_layer_test.gd`:
```gdscript
extends TestCase
## Looping layers wrap seamlessly and always cover the view.


func _strips(total: int, h: int) -> Array[Texture2D]:
	var s: Array[Texture2D] = []
	for w in PlateLayer.strip_widths(total):
		s.append(ImageTexture.create_from_image(Image.create_empty(w, h, false, Image.FORMAT_RGBA8)))
	return s


func test_tile_width_and_depth() -> void:
	var layer := LoopingLayer.new()
	layer.setup(40.0, _strips(4096, 1280), false, true, Vector2(57.6, 12.0))
	assert_near(layer.tile_width, 4096.0 / WorldSpec.density(40.0), 1e-4, "tile width in metres")
	assert_near(layer.position.z, -40.0, 1e-6, "depth")
	layer.free()


func test_copies_cover_the_plate_span_at_any_offset() -> void:
	var section := Vector2(57.6, 12.0)
	var layer := LoopingLayer.new()
	layer.setup(10.0, _strips(4096, 1280), false, true, section)
	var need := WorldSpec.plate_rect(10.0, section)
	for offset: float in [0.0, 13.7, layer.tile_width * 0.999]:
		layer.offset = offset
		layer.layout()
		var left := INF
		var right := -INF
		for copy: Node3D in layer.copies:
			left = minf(left, copy.position.x)
			right = maxf(right, copy.position.x + layer.tile_width)
		assert_true(left <= need.position.x + 1e-4 and right >= need.end.x - 1e-4, "covered at offset %s" % offset)
	layer.free()


func test_scrolls_and_wraps() -> void:
	var layer := LoopingLayer.new()
	layer.setup(10.0, _strips(4096, 1280), false, true, Vector2(57.6, 12.0))
	layer.speed = 20.0
	layer.advance(1.0)
	assert_near(layer.offset, 20.0, 1e-4, "moves at speed")
	layer.advance(layer.tile_width / 20.0)
	assert_near(layer.offset, 20.0, 1e-3, "wrapped by one tile width")
	layer.free()


func test_placeholder_loops_are_seamless() -> void:
	var size := Vector2i(4096, 256)
	var ppm := WorldSpec.density(10.0)
	assert_eq(PlaceholderPlate.silhouette_top(0, size.y, ppm, 0.5, size.x),
			PlaceholderPlate.silhouette_top(size.x, size.y, ppm, 0.5, size.x), "silhouette repeats at the loop width")
```
(`silhouette_top` gains the optional `period_px` parameter too.)
- [ ] **Steps 2–5:** run (fail) → implement → run (pass) → commit `feat: LoopingLayer and seamless placeholder loops`.

---

### Task 4: Art import tool (slice, manifest, `.import`, collision trace)

**Files:** Create `tools/art/import_art.py`, `tools/art/test_import_art.py`, `tools/import_art.sh`. Modify `.gitignore` (`art/levels/*/_strips/`).

**Interfaces:**
- `import_art.py <levels_dir> [--force]` → for each subfolder containing PNGs or `section.json`: if any source (PNGs, `gameplay_solid.png`) is newer than `_strips/stamp.json` (or `--force`), rebuild `_strips/`: delete old strips; slice every layer PNG (`sky far mid near gameplay mid_loop near_loop fg_loop`) and its `_n`/`_emit` into `<layer>[_n|_emit]_NN.png` (≤ 2048 px wide); copy `fg_*.png` props (+ companions) unchanged into `_strips/`; write a `.import` next to every output with `compress/mode=2`, `compress/high_quality=true`, `mipmaps/generate=true`, and `compress/normal_map=1` for `_n` files; write `_strips/manifest.json` `{layer: {"widths": [...], "height": h, "has_n": bool, "has_emit": bool}, "props": [names]}`; trace `gameplay_solid.png` (if present) into `_strips/collision_traced.json`; write the stamp. `main(argv) -> int` returns the number of sections imported.
- Trace: mask scaled to the gameplay plate size if different; 10 px cells, a cell is solid when > 50% of its pixels are bright (> 127); horizontal runs of solid cells per row → merge runs with identical x/width across consecutive rows → rects `[x, y, w, h]` in plate px, sorted by `(y, x)`.
- `tools/import_art.sh [levels_dir]` (default `art/levels`): runs `import_art.py`, then `make_maps.py` for gameplay/near/mid/loop plates lacking maps (never `--force`), then `check_art.py`, then `godot --headless --import`; prints one line per stage.

- [ ] **Step 1: Failing tests** — `tools/art/test_import_art.py`:
```python
import json, os, sys, tempfile, time, unittest
from PIL import Image
sys.path.insert(0, os.path.dirname(__file__))
import import_art


def section(d, name="l9_test"):
    s = os.path.join(d, name); os.makedirs(s); return s


class ImportArtTest(unittest.TestCase):
    def test_slices_layers_into_strips_with_manifest_and_import_files(self):
        with tempfile.TemporaryDirectory() as d:
            s = section(d)
            Image.new("RGBA", (5000, 100), (1, 2, 3, 255)).save(os.path.join(s, "gameplay.png"))
            Image.new("RGBA", (5000, 100), (128, 128, 255, 255)).save(os.path.join(s, "gameplay_n.png"))
            Image.new("RGBA", (4096, 50), (0, 0, 0, 0)).save(os.path.join(s, "near_loop.png"))
            Image.new("RGBA", (40, 90), (9, 9, 9, 255)).save(os.path.join(s, "fg_pillar.png"))
            self.assertEqual(import_art.main([d]), 1)
            strips = os.path.join(s, "_strips")
            m = json.load(open(os.path.join(strips, "manifest.json")))
            self.assertEqual(m["gameplay"]["widths"], [2048, 2048, 904])
            self.assertTrue(m["gameplay"]["has_n"])
            self.assertFalse(m["gameplay"]["has_emit"])
            self.assertEqual(m["near_loop"]["widths"], [2048, 2048])
            self.assertEqual(m["props"], ["fg_pillar.png"])
            self.assertEqual(Image.open(os.path.join(strips, "gameplay_02.png")).size, (904, 100))
            imp = open(os.path.join(strips, "gameplay_n_02.png.import")).read()
            for line in ("compress/mode=2", "compress/normal_map=1", "mipmaps/generate=true"):
                self.assertIn(line, imp)
            self.assertNotIn("normal_map=1", open(os.path.join(strips, "gameplay_00.png.import")).read())

    def test_second_run_skips_unchanged_sections(self):
        with tempfile.TemporaryDirectory() as d:
            s = section(d)
            Image.new("RGBA", (100, 50), (1, 2, 3, 255)).save(os.path.join(s, "far.png"))
            self.assertEqual(import_art.main([d]), 1)
            self.assertEqual(import_art.main([d]), 0)
            time.sleep(0.05)
            Image.new("RGBA", (100, 50), (4, 5, 6, 255)).save(os.path.join(s, "far.png"))
            self.assertEqual(import_art.main([d]), 1)

    def test_reimport_removes_stale_strips(self):
        with tempfile.TemporaryDirectory() as d:
            s = section(d)
            Image.new("RGBA", (5000, 20), (1, 1, 1, 255)).save(os.path.join(s, "near.png"))
            import_art.main([d])
            Image.new("RGBA", (1000, 20), (1, 1, 1, 255)).save(os.path.join(s, "near.png"))
            import_art.main([d, "--force"])
            self.assertFalse(os.path.exists(os.path.join(s, "_strips", "near_02.png")))
            self.assertFalse(os.path.exists(os.path.join(s, "_strips", "near_02.png.import")))

    def test_traces_solid_mask_to_collision_rects(self):
        with tempfile.TemporaryDirectory() as d:
            s = section(d)
            Image.new("RGBA", (200, 100), (0, 0, 0, 0)).save(os.path.join(s, "gameplay.png"))
            mask = Image.new("L", (200, 100), 0)
            mask.paste(255, (0, 80, 200, 100))   # floor
            mask.paste(255, (50, 60, 70, 80))    # crate
            mask.save(os.path.join(s, "gameplay_solid.png"))
            import_art.main([d])
            rects = json.load(open(os.path.join(s, "_strips", "collision_traced.json")))
            self.assertEqual(rects, [[50, 60, 20, 20], [0, 80, 200, 20]])


if __name__ == "__main__":
    unittest.main()
```
- [ ] **Step 2: Run** — `import_art` missing. **Step 3: Implement** the script, the shell wrapper and the `.gitignore` line. **Step 4: Run** — pass; then run `bash tools/import_art.sh` on the real `art/levels` (sections exist from Task 10's data only later; here it must simply report `0 sections imported` without error). **Step 5: Commit** `feat: import_art slices plates into BC7 strips, traces collision masks`.

---

### Task 5: SectionDef

**Files:** Create `scripts/sections/section_def.gd`, `tests/section_def_test.gd`.

**Interfaces:** `class_name SectionDef extends RefCounted`; `static func load_dir(dir: String) -> SectionDef` (reads `section.json` via `FileAccess`; missing file → defaults with `size_m = WorldSpec.LEVEL_SIZE`); fields `dir`, `id` (folder name), `size: Vector2`, `type: String`, `env: Dictionary`, `placeholder: Dictionary`, `spawn: Vector2`, `has_exit: bool`, `exit: Rect2`, `collision: Array[Rect2]` (metres: `section.json` + converted `gameplay_collision.json` + converted `_strips/collision_traced.json`), `lights: Array[Dictionary]` (with `light_rows` expanded; each has `pos: Vector3`, `color: Color`, `range`, `energy`, `flicker`), `props: Array[Dictionary]`, `enemies: Array[Dictionary]`, `arenas: Array[Dictionary]` (`rect: Rect2`, `enemies: Array`), `rain`, `lightning: bool`, `flicker_layers: PackedStringArray`, `loop_speed`, `loop_ramp_s: float`, `manifest: Dictionary` (from `_strips/manifest.json`, `{}` if absent); `func is_vehicle() -> bool`; `static func px_to_world(px: Array, plate: Rect2, px_per_m: float) -> Rect2`.

- [ ] **Step 1: Failing tests** — `tests/section_def_test.gd`:
```gdscript
extends TestCase
## Section folders parse into metres, with pixel collision converted from plate space.

const ROOT := "user://test_sections/"


func _write_section(name: String, data: Dictionary, extra := {}) -> String:
	var dir := ROOT + name + "/"
	DirAccess.make_dir_recursive_absolute(dir + "_strips")
	FileAccess.open(dir + "section.json", FileAccess.WRITE).store_string(JSON.stringify(data))
	for path: String in extra:
		FileAccess.open(dir + path, FileAccess.WRITE).store_string(extra[path])
	return dir


func test_parses_core_fields() -> void:
	var def := SectionDef.load_dir(_write_section("core", {
		"size_m": [40.0, 12.0], "type": "vehicle", "spawn": [2.0, 5.0], "exit": [38.0, 4.0, 1.5, 5.0],
		"loop_speed": 30.0, "loop_ramp_s": 6.0,
		"arenas": [{"rect": [10, 0, 28.8, 12], "enemies": [{"type": "officer", "x": 20.0}]}]}))
	assert_eq(def.size, Vector2(40, 12), "size")
	assert_true(def.is_vehicle(), "vehicle")
	assert_eq(def.spawn, Vector2(2, 5), "spawn")
	assert_true(def.has_exit and def.exit == Rect2(38, 4, 1.5, 5), "exit")
	assert_eq(def.arenas.size(), 1, "arena")
	assert_eq(def.arenas[0].rect, Rect2(10, 0, 28.8, 12), "arena rect")
	assert_near(def.loop_speed, 30.0, 1e-6, "loop speed")


func test_light_rows_expand() -> void:
	var def := SectionDef.load_dir(_write_section("rows", {"size_m": [40.0, 12.0],
		"light_rows": [{"from": 5, "to": 29, "step": 12, "y": 10, "z": 1.5, "color": "#ffffff", "range": 6, "energy": 2, "flicker": 0.3}]}))
	assert_eq(def.lights.size(), 3, "lights at 5, 17, 29")
	assert_eq(def.lights[2].pos, Vector3(29, 10, 1.5), "third light position")
	assert_near(def.lights[0].flicker, 0.3, 1e-6, "flicker amount kept")


func test_pixel_collision_converts_to_world_metres() -> void:
	var def := SectionDef.load_dir(_write_section("px", {"size_m": [40.0, 12.0], "collision": [[0, 0, 40, 1]]},
			{"gameplay_collision.json": "[[100, 200, 300, 50]]", "_strips/collision_traced.json": "[[0, 0, 100, 100]]"}))
	var plate := WorldSpec.plate_rect(0.0, Vector2(40, 12))
	assert_eq(def.collision.size(), 3, "section + composed + traced")
	assert_eq(def.collision[0], Rect2(0, 0, 40, 1), "section.json rect unchanged (metres)")
	var r: Rect2 = def.collision[1]
	assert_near(r.position.x, plate.position.x + 1.0, 1e-4, "x")
	assert_near(r.size.x, 3.0, 1e-4, "w")
	assert_near(r.end.y, plate.end.y - 2.0, 1e-4, "top edge 200 px below the plate top")
	assert_near(r.size.y, 0.5, 1e-4, "h")


func test_missing_section_json_gives_defaults() -> void:
	DirAccess.make_dir_recursive_absolute(ROOT + "empty")
	var def := SectionDef.load_dir(ROOT + "empty/")
	assert_eq(def.size, WorldSpec.LEVEL_SIZE, "default size")
	assert_true(not def.has_exit, "no exit")
	assert_eq(def.manifest, {}, "no strips yet")
```
- [ ] **Steps 2–5:** run (fail) → implement → run (pass) → commit `feat: SectionDef parses section folders`.

---

### Task 6: Section builder

**Files:** Create `scripts/sections/section.gd`, `tests/section_test.gd`. Modify `scripts/level_builder.gd` (environment from a `SectionDef.env`; placeholder styles from `SectionDef.placeholder`).

**Interfaces:** `class_name Section extends Node3D`; `signal exited`; vars `def: SectionDef`, `layers: Array[PlateLayer]`, `loops: Array[LoopingLayer]`, `blocks: Array[StaticBody3D]`, `props: Array[MeshInstance3D]`, `arenas: Array[ArenaZone]` (Task 7 — until then build none), `exit_zone: Area3D` (null without exit), `enemies: Array[Enemy]`, `sun: DirectionalLight3D`, `environment: Environment`, `weather: Weather` (Task 9 — null until then); `func setup(p_def: SectionDef) -> void`:
  - environment + sun from `def.env` (defaults = M1 values); lights (omni per `def.lights`).
  - Layers: horizontal/other types → static layers `sky far mid near gameplay`; vehicle → static `gameplay` + loops `mid_loop near_loop fg_loop` (depths 40, 10, −8). Each uses the manifest's strips (`<dir>_strips/<layer>_NN.png`, with `_n`/`_emit` when flagged) or, when the layer is absent from the manifest, a placeholder generated at the `WorldSpec` size for the section (loops: 4096 × formula height, `period_px = 4096`; sky/far are skipped for vehicle sections). Placeholder colours from `def.placeholder[layer]` or `LevelBuilder.default_styles()`.
  - Props: `fg_*.png` quads at depth −8 (world z +8), sized by density(−8), positioned by `def.props` (`x`, `y` = bottom, metres).
  - Collision: `LevelBuilder.block` per `def.collision` rect (dark greybox visual only when the section has no gameplay art) + `LevelBuilder.walls(def.size)`.
  - Exit: `Area3D` (mask layer 2) over `def.exit`; emits `exited` when a `Player` enters.
  - Free enemies from `def.enemies` via `static func spawn_enemy(spec: Dictionary) -> Enemy` (`officer` → `Enemy.create_officer()`, `dummy` → `TrainingDummy.create_dummy()`), at `(x, spec.get("y", 2.5), 0)`.
  - Vehicle: loops' `speed = def.loop_speed * lerp(0.3, 1.0, clamp(t / def.loop_ramp_s, 0, 1))` each frame.

- [ ] **Step 1: Failing tests** — `tests/section_test.gd`:
```gdscript
extends TestCase
## Sections build from data, with placeholders for missing art.

const ROOT := "user://test_sections/"


func _def(name: String, data: Dictionary) -> SectionDef:
	var dir := ROOT + name + "/"
	DirAccess.make_dir_recursive_absolute(dir)
	FileAccess.open(dir + "section.json", FileAccess.WRITE).store_string(JSON.stringify(data))
	return SectionDef.load_dir(dir)


func test_missing_art_falls_back_to_placeholders() -> void:
	var s := Section.new()
	s.setup(_def("h", {"size_m": [40.0, 12.0], "collision": [[0, 0, 40, 1]], "exit": [38, 1, 1.5, 5]}))
	add_node(s)
	assert_eq(s.layers.size(), 5, "five static layers from placeholders")
	for layer in s.layers:
		var total := 0
		for mi: MeshInstance3D in layer.get_children():
			total += (mi.material_override as StandardMaterial3D).albedo_texture.get_width()
		assert_eq(total, WorldSpec.plate_size_px(layer.depth, Vector2(40, 12)).x, "placeholder sized for the section at depth %s" % layer.depth)
	assert_eq(s.blocks.size(), 1 + 2, "collision + two walls")
	assert_true(s.exit_zone != null, "exit zone")


func test_vehicle_section_builds_loops() -> void:
	var s := Section.new()
	s.setup(_def("v", {"size_m": [57.6, 12.0], "type": "vehicle", "loop_speed": 30.0, "loop_ramp_s": 6.0}))
	add_node(s)
	assert_eq(s.loops.size(), 3, "mid, near and foreground loops")
	assert_eq(s.layers.size(), 1, "only the train (gameplay) is static")
	s._process(0.0)
	assert_near(s.loops[0].speed, 9.0, 1e-4, "starts at 30% speed")
	s._process(6.0)
	assert_near(s.loops[0].speed, 30.0, 1e-4, "full speed after the ramp")


func test_exit_emits_when_player_enters() -> void:
	var s := Section.new()
	s.setup(_def("e", {"size_m": [40.0, 12.0], "collision": [[0, 0, 40, 1]], "exit": [30, 1, 4, 5]}))
	add_node(s)
	var fired := [false]
	s.exited.connect(func() -> void: fired[0] = true)
	var p := Player.create()
	p.position = Vector3(32, 1.9, 0)
	s.add_child(p)
	for i in 6:
		await tree.physics_frame
	assert_true(fired[0], "exited fired")
```
- [ ] **Steps 2–5:** run (fail) → implement (extend `LevelBuilder.environment(parent, env := {})` so M1/M2 callers are unchanged) → run (pass; M1 test level and sandbox tests still green) → commit `feat: Section builds sections from data with placeholder fallback`.

---

### Task 7: Arena zones and dead-enemy cleanup

**Files:** Create `scripts/sections/arena_zone.gd`, `tests/arena_zone_test.gd`. Modify `scripts/fighter.gd` (`signal died`, emitted once when HP first reaches 0), `scripts/enemies/enemy.gd` (on death: leave `enemies`, `hurtbox.set_deferred("monitorable", false)`, then free after `DEATH_DELAY`), `tests/enemy_test.gd`, `scripts/sections/section.gd` (build arenas).

**Interfaces:** `class_name ArenaZone extends Area3D`; `signal started`, `signal cleared`; vars `rect: Rect2`, `specs: Array`, `active := false`, `is_cleared := false`, `enemies: Array[Enemy]`, `barriers: Array[StaticBody3D]`; `func setup(p_rect: Rect2, enemy_specs: Array) -> void` (collision box over `rect`, mask layer 2); on first `Player` entry: `active = true`, `call_group(&"camera_rig", &"lock_to", rect, 0.5)`, spawn `Section.spawn_enemy(spec)` for each spec (as siblings under the arena's parent), raise two world-layer barrier walls at `rect.position.x - 0.5` and `rect.end.x` (1 m thick, full height), emit `started`. Each enemy's `died` → when all have died: remove barriers, `call_group(&"camera_rig", &"unlock", 0.5)`, `is_cleared = true`, emit `cleared`. `func reset()` — frees surviving spawned enemies and barriers, unlocks the camera, `active = false` (used on player death, Task 8); a cleared arena stays cleared.

- [ ] **Step 1: Failing tests** — `tests/arena_zone_test.gd`:
```gdscript
extends TestCase
## Arenas lock the camera, spawn enemies behind barriers, and clear when the enemies die.


func _world() -> Array:
	var world := Node3D.new()
	add_node(world)
	LevelBuilder.block(world, Rect2(0, 0, 80, 1), null)
	var player := Player.create()
	player.position = Vector3(10, 1.9, 0)
	world.add_child(player)
	var rig := CameraRig.new()
	rig.target = player
	rig.level_size = Vector2(80, 16.2)
	world.add_child(rig)
	var arena := ArenaZone.new()
	arena.setup(Rect2(40, 0, 28.8, 16.2), [{"type": "officer", "x": 60.0}])
	world.add_child(arena)
	return [world, player, rig, arena]


func _kill(e: Enemy, by: Fighter) -> void:
	e.receive_hit({"outcome": HitResolver.Outcome.HIT, "damage": 1000.0, "stagger": 0.0, "knockback": Vector2.ZERO}, by)


func test_arena_locks_spawns_and_clears() -> void:
	var w := _world()
	var player: Player = w[1]
	var rig: CameraRig = w[2]
	var arena: ArenaZone = w[3]
	player.position.x = 45.0
	for i in 10:
		await tree.physics_frame
	assert_true(arena.active, "entered")
	assert_eq(rig.locked_rect(), Rect2(40, 0, 28.8, 16.2), "camera locked to the arena")
	assert_eq(arena.barriers.size(), 2, "walls up")
	assert_eq(arena.enemies.size(), 1, "officer spawned")
	_kill(arena.enemies[0], player)
	for i in 5:
		await tree.physics_frame
	assert_true(arena.is_cleared, "cleared as soon as the last enemy dies")
	assert_eq(arena.barriers.size(), 0, "walls down")
	assert_true(not rig.is_locked(), "camera unlocked")


func test_reset_after_player_death() -> void:
	var w := _world()
	var player: Player = w[1]
	var rig: CameraRig = w[2]
	var arena: ArenaZone = w[3]
	player.position.x = 45.0
	for i in 10:
		await tree.physics_frame
	arena.reset()
	await tree.process_frame
	assert_true(not arena.active and not arena.is_cleared, "ready to trigger again")
	assert_eq(arena.barriers.size(), 0, "walls removed")
	assert_true(not rig.is_locked(), "camera unlocked")
```
Append to `tests/enemy_test.gd`:
```gdscript


func test_dead_enemy_is_untargetable() -> void:
	var p := Player.create()
	var e := Enemy.create_officer()
	add_node(p)
	add_node(e)
	await tree.physics_frame
	var died := [false]
	e.died.connect(func() -> void: died[0] = true)
	e.receive_hit({"outcome": HitResolver.Outcome.HIT, "damage": 1000.0, "stagger": 0.0, "knockback": Vector2.ZERO}, p)
	await tree.physics_frame
	assert_true(died[0], "died signal")
	assert_true(not e.is_in_group(&"enemies"), "left the enemies group")
	assert_true(not e.hurtbox.monitorable, "no longer hittable")
```
- [ ] **Steps 2–5:** run (fail) → implement → run (pass) → commit `feat: arena zones; dead enemies leave play immediately`.

---

### Task 8: LevelRunner — section chain, fades, death and respawn

**Files:** Create `scripts/sections/level_runner.gd`, `scenes/level/level_1.tscn` (Node3D + script, `level_id = "l1"`), `tests/level_runner_test.gd`.

**Interfaces:** `class_name LevelRunner extends Node3D`; `const LEVELS := {"l1": ["res://art/levels/l1_station", "res://art/levels/l1_train"]}`; `@export var level_id := "l1"`; `var fade_time := 0.4`; `var return_to_title := true`; `var autostart := true` (tests set false and call `start(dirs)`); user arg `--section=N` starts at section N (captures); `signal level_completed`; vars `section_dirs: Array`, `index := -1`, `section: Section`, `player: Player`, `rig: CameraRig`; `func start(dirs: Array = []) -> void` (defaults to `LEVELS[level_id]`; `_ready` calls it when `autostart`); `func go_to(i: int)` — fade to black over `fade_time` (a `CanvasLayer` + `ColorRect`), free the old section, build `Section` from `SectionDef.load_dir`, spawn a fresh `Player` at `def.spawn`, `CameraRig` with `level_size = def.size`, `snap_to_target()`, fade in; `section.exited` → `go_to(index + 1)` or, after the last, emit `level_completed` and (if `return_to_title`) change scene to the title. Player `died` → after 1.0 s: reset every un-cleared arena in the section, move the player to `def.spawn`, restore HP, clear stun, `rig.unlock(0.0)` + `snap_to_target()`.

- [ ] **Step 1: Failing tests** — `tests/level_runner_test.gd`:
```gdscript
extends TestCase
## Level runner chains sections, respawns the player, and completes the level.

const ROOT := "user://test_levels/"


func _section(name: String, data: Dictionary) -> String:
	var dir := ROOT + name + "/"
	DirAccess.make_dir_recursive_absolute(dir)
	FileAccess.open(dir + "section.json", FileAccess.WRITE).store_string(JSON.stringify(data))
	return dir


func _runner() -> LevelRunner:
	var a := _section("a", {"size_m": [40.0, 12.0], "collision": [[0, 0, 40, 1]], "spawn": [4.0, 2.5], "exit": [36, 1, 3, 6],
		"arenas": [{"rect": [15, 0, 20, 12], "enemies": [{"type": "officer", "x": 30.0}]}]})
	var b := _section("b", {"size_m": [40.0, 12.0], "collision": [[0, 0, 40, 1]], "spawn": [3.0, 2.5], "exit": [36, 1, 3, 6]})
	var runner := LevelRunner.new()
	runner.autostart = false
	runner.fade_time = 0.0
	runner.return_to_title = false
	add_node(runner)
	runner.start([a, b])
	return runner


func _frames(n: int) -> void:
	for i in n:
		await tree.physics_frame


func test_starts_first_section_at_spawn() -> void:
	var r := _runner()
	await _frames(3)
	assert_eq(r.index, 0, "first section")
	assert_near(r.player.global_position.x, 4.0, 0.1, "at spawn")


func test_exit_moves_to_next_section_and_last_exit_completes() -> void:
	var r := _runner()
	var done := [false]
	r.level_completed.connect(func() -> void: done[0] = true)
	await _frames(3)
	r.player.global_position = Vector3(37, 1.9, 0)
	await _frames(10)
	assert_eq(r.index, 1, "second section")
	assert_near(r.player.global_position.x, 3.0, 0.1, "at the second spawn")
	r.player.global_position = Vector3(37, 1.9, 0)
	await _frames(10)
	assert_true(done[0], "level completed")


func test_death_in_arena_resets_it() -> void:
	var r := _runner()
	await _frames(3)
	r.player.global_position = Vector3(20, 1.9, 0)
	await _frames(10)
	var arena: ArenaZone = r.section.arenas[0]
	assert_true(arena.active, "arena started")
	r.player.receive_hit({"outcome": HitResolver.Outcome.HIT, "damage": 1000.0, "stagger": 0.0, "knockback": Vector2.ZERO}, null)
	await tree.create_timer(1.2).timeout
	assert_true(not arena.active, "arena reset")
	assert_true(not r.rig.is_locked(), "camera unlocked")
	assert_near(r.player.vitals.hp, r.player.vitals.max_hp, 1e-6, "full health")
	assert_near(r.player.global_position.x, 4.0, 0.2, "back at spawn")
```
(`Fighter.receive_hit` must accept a null attacker.)
- [ ] **Steps 2–5:** run (fail) → implement → run (pass) → commit `feat: LevelRunner chains sections with fades and respawn`.

---

### Task 9: Weather and flicker

**Files:** Create `scripts/fx/weather.gd`, `scripts/fx/flicker.gd`, `tests/fx_test.gd`. Modify `scripts/sections/section.gd` (weather from `def.rain/lightning`; flicker for `def.flicker_layers` and lights with `flicker > 0`), `scripts/combat_sandbox.gd` (`--rain` user arg turns on rain + lightning for a demo).

**Interfaces:**
- `class_name Weather extends Node3D`: `const FLASH_ENERGY := 6.0`, `const FLASH_TIME := 0.15`; `func setup(rain: bool, lightning: bool, sun: DirectionalLight3D) -> void`; `var rain_near: GPUParticles3D`, `var rain_far: GPUParticles3D` (null when no rain; near at z +3, far at z −15, thin stretched quads falling at 18 m/s, emitting over a box wider than the 21:9 view at their depth); follows the current camera's x/y each frame; `var next_flash_in: float` (random 6–14 s) counts down when `lightning`; `func flash()` sets `sun.light_energy = FLASH_ENERGY` then tweens back to its base over `FLASH_TIME` (tween ignores time scale).
- `class_name Flicker extends Node`: `func add_layer(layer: Object, amount: float)` (anything with `set_glow`), `func add_light(light: Light3D, amount: float)`; each frame sets glow/energy = base × `Flicker.level(time + phase_i, amount)`; `static func level(t: float, amount: float) -> float` — deterministic value noise mostly at 1.0 with brief dips, always within `[1 - amount, 1]`.

- [ ] **Step 1: Failing tests** — `tests/fx_test.gd`:
```gdscript
extends TestCase
## Rain appears only when asked for; lightning flashes and restores; flicker stays in range.


func test_rain_only_when_enabled() -> void:
	var sun := DirectionalLight3D.new()
	add_node(sun)
	var dry := Weather.new()
	dry.setup(false, false, sun)
	add_node(dry)
	assert_true(dry.rain_near == null and dry.rain_far == null, "no rain")
	var wet := Weather.new()
	wet.setup(true, false, sun)
	add_node(wet)
	assert_true(wet.rain_near != null and wet.rain_far != null, "two rain layers")
	assert_true(wet.rain_near.position.z > 0.0 and wet.rain_far.position.z < 0.0, "in front of and behind the gameplay plane")


func test_lightning_flash_restores_sun() -> void:
	var sun := DirectionalLight3D.new()
	sun.light_energy = 0.4
	add_node(sun)
	var w := Weather.new()
	w.setup(false, true, sun)
	add_node(w)
	w.flash()
	assert_near(sun.light_energy, Weather.FLASH_ENERGY, 1e-6, "flash")
	await tree.create_timer(Weather.FLASH_TIME + 0.1, true, false, true).timeout
	assert_near(sun.light_energy, 0.4, 1e-3, "restored")


func test_flicker_level_bounded_and_varies() -> void:
	var lo := 1.0
	var hi := 0.0
	for i in 600:
		var v := Flicker.level(i * 0.01, 0.4)
		lo = minf(lo, v)
		hi = maxf(hi, v)
		assert_true(v >= 0.6 - 1e-6 and v <= 1.0 + 1e-6, "in range at %d" % i)
	assert_true(hi - lo > 0.1, "actually flickers (range %.2f)" % (hi - lo))
```
- [ ] **Steps 2–5:** run (fail) → implement → run (pass) → commit `feat: rain, lightning and glow/light flicker`.

---

### Task 10: Level 1 greybox data, title flow, verification, docs

**Files:** Create `art/levels/l1_station/section.json`, `art/levels/l1_train/section.json`, `tests/level1_test.gd`. Modify `scripts/ui/title_screen.gd` + `tests/title_screen_test.gd` (START → `res://scenes/level/level_1.tscn`; second button `COMBAT SANDBOX`; QUIT), `docs/art/level1-art-brief.md` (section.json, `gameplay_solid.png`, `bash tools/import_art.sh`), `docs/art/art-guide.md` (§6 delivery uses `import_art.sh`), spec §9 tooling + §10 M3 status.

**Level 1 data** (metres; plate-px positions from the brief converted with the Global Constraints formula):
- `l1_station`: size 134.4 × 16.2, type horizontal; env background `#07080c`, fog `#1b1f2e` 0.008, ambient `#2a3040` 0.45, sun `#5060a0` 0.25; dark neon placeholder colours (sky `#0b0d14→#161a26` opaque; far `#1a1f33→#10131f` 0.45; mid `#2a2440→#171428` 0.5; near `#12303a→#0b1a20` 0.62; gameplay `#3a3440→#1c1a22` 0.8); spawn (4, 2.5); collision: floor `[0, 0, 134.4, 1.0]`, low ceiling `[0, 13.7, 134.4, 2.5]`, crates `[22, 1, 1.5, 1.2]`, `[48, 1, 3, 1.0]`, bench stack `[70, 1, 2, 2.2]`, ticket-booth roof `[86, 1, 4, 2.4]`; `light_rows` fluorescents from 8 to 128 every 12 m at y 12.8, z 1.5, `#cfe8ff`, range 8, energy 2.5, flicker 0.35; free enemies: one officer at x 55 (first real fight after the tutorial stretch); arena `[103.2, 0, 28.8, 16.2]` with officers at 116, 122, 127; exit `[131.4, 1, 2.4, 6]`; `flicker_layers: ["gameplay", "mid"]`; no rain/lightning.
- `l1_train`: size 57.6 × 12, type vehicle; same env but fog `#141824`; roof-top collision per car `[0.5, 0, 18.5, 4.0]`, `[19.6, 0, 18.4, 4.0]`, `[38.6, 0, 18.5, 4.0]`; coupling steps `[19.0, 2.2, 0.6, 0.3]`, `[38.0, 2.2, 0.6, 0.3]`; roof obstacles `[9, 4, 0.8, 0.7]`, `[28, 4, 0.6, 1.2]`, `[47, 4, 1.0, 0.9]`; spawn (2, 5); officers at 30 and 50; exit `[55.5, 4, 1.5, 5]`; `loop_speed` 30, `loop_ramp_s` 6; `flicker_layers: ["near_loop"]`.

- [ ] **Step 1: Failing tests** — `tests/level1_test.gd`:
```gdscript
extends TestCase
## Level 1 greybox data loads and builds; the title starts it.


func test_station_data() -> void:
	var def := SectionDef.load_dir("res://art/levels/l1_station/")
	assert_eq(def.size, Vector2(134.4, 16.2), "7-screen station")
	assert_eq(def.arenas.size(), 1, "one squad arena")
	assert_eq(def.arenas[0].enemies.size(), 3, "three officers")
	assert_true(def.has_exit, "exit to the train")
	assert_true(def.lights.size() >= 10, "fluorescent rows expanded")


func test_train_data_is_a_vehicle_run() -> void:
	var def := SectionDef.load_dir("res://art/levels/l1_train/")
	assert_true(def.is_vehicle(), "vehicle")
	assert_eq(def.size, Vector2(57.6, 12.0), "three-car train section")
	assert_true(def.loop_speed > 0.0, "tunnel scrolls")


func test_level_scene_starts_in_the_station() -> void:
	var level = add_node(load("res://scenes/level/level_1.tscn").instantiate()) # untyped: script vars
	for i in 3:
		await tree.physics_frame
	assert_eq(level.index, 0, "station first")
	assert_true(level.section.def.id == "l1_station", "station section")
```
And in `tests/title_screen_test.gd` change the expected `start_scene` to `"res://scenes/level/level_1.tscn"`.
- [ ] **Step 2: Run** (fail) → **Step 3: Implement** data + title change + docs.
- [ ] **Step 4: Run** — all Godot + Python tests pass; `bash tools/import_art.sh` reports both Level 1 folders (no PNGs yet → nothing sliced, no errors).
- [ ] **Step 5: Visual check** — `bash tools/capture.sh l1_station 1920x1080 120 res://scenes/level/level_1.tscn` and a train capture (`bash tools/capture.sh l1_train 1920x1080 120 res://scenes/level/level_1.tscn --section=1`; add a `--section=N` user arg to `LevelRunner` for this). Use `probe_px.py` to confirm the station reads dark with lit fluorescent bands and the tunnel loops show motion between two captures a few frames apart (different pixel columns). View one downscaled capture per section.
- [ ] **Step 6: Commit** `feat: Level 1 greybox (station + train run), title starts Level 1; M3 complete`.

## Deferred (M4+)

Real Level 1 art (user), Moth comms, drones, the passing-train effect in the station's tunnel mouths, per-level colour-grading LUT, volumetric fog, player HUD, save/checkpoints beyond section start, streaming.
