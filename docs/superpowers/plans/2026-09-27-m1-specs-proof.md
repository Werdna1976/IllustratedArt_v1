# M1 Specs Proof Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A playable test level that proves the spec's numbers: placeholder plates at the exact spec sizes on five depth layers, fog + DoF + lights, a following camera, and a capsule player that runs and jumps.

**Architecture:** All size/camera math lives in one static class (`WorldSpec`) that every other unit consumes. Plates are generated in code (`PlaceholderPlate`) and laid out as quad strips by `PlateLayer`. Movement maths (`PlayerMotor`) and camera maths (`CameraRig` static helpers) are pure functions with thin node wrappers. The test level is assembled entirely in code from a data layout (`TestLevelLayout`). No addons; tests run on a ~60-line headless runner.

**Tech Stack:** Godot 4.7.2 (Forward+, D3D12, Jolt), GDScript, headless test runner (`tests/run_tests.gd`), Git Bash.

**Spec:** `docs/superpowers/specs/2026-09-27-illustrated-platformer-design.md`

## Global Constraints

- Engine: `C:/GoDot/Godot_v4.7.2-stable_win64.exe` (bash path `/c/GoDot/Godot_v4.7.2-stable_win64.exe`); override with `GODOT=...`.
- 1 world unit = 1 m = 100 px at the gameplay plane; camera distance 20 m; vertical FOV 30.22°; keep-height up to 21:9, keep 21:9 width beyond.
- Level 134.4 × 16.2 m; level origin at world (0, 0), X right, Y up; depth z maps to world Z = −z.
- Plate sizes (px): depth 0 → 14,784 × 1,792; 10 → 10,816 × 1,600; 40 → 6,784 × 1,408; 100 → 4,800 × 1,344; 400 → 3,392 × 1,280. Strips ≤ 2,048 px wide.
- Actor/platform visuals render at z = +0.5 m; collision at z = 0; player Z locked.
- Physics 120 Hz, physics interpolation on; MSAA 3D 4×; TAA off; VSync on; viewport 1920 × 1080; stretch `canvas_items` / `expand`.
- GDScript style: tabs, static typing, `##` doc comment at the top of each script, `class_name` on every reusable script.
- Every commit message ends with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Review Focus

1. **Unusual window aspect (4:3, 16:10, 21:9, 32:9, or a live resize)** — the player expects never to see a plate edge or empty background. Pinned by Task 2 `test_plates_cover_view_at_every_camera_extreme` and Task 5 `test_projection_follows_aspect_changes`.
2. **Frame hitch (a single huge delta, e.g. 0.5 s after a stall)** — camera must not overshoot its goal and the player must not exceed max fall speed. Pinned by Task 4 `test_fall_speed_capped_even_with_huge_delta` and Task 5 `test_smooth_never_overshoots`.
3. **Player drawn behind the gameplay plate** — the character (and platforms) must always be visible in front of the plate at z = 0. Pinned by Task 4 `test_visual_sits_in_front_of_gameplay_plate` and Task 6 `test_platform_visuals_in_front_of_gameplay_plate`.
4. **Running off either end of the level** — the player expects a wall, not a fall into the void. Pinned by Task 6 `test_walls_close_both_ends`.
5. **Camera starting at the world origin and swooping to the player** — the first frame should already frame the player. Pinned by Task 5 `test_snap_frames_target_clamped` and Task 6 `test_level_builds_layers_player_and_camera`.

---

## File Structure

| File | Responsibility |
|---|---|
| `project.godot` (modify) | Display, rendering, physics settings; main scene |
| `tools/run_tests.sh` | Import project then run headless test suite |
| `tests/run_tests.gd` | Headless runner: discovers `tests/*_test.gd`, runs `test_*`, counts engine errors |
| `tests/test_case.gd` | `TestCase` base: asserts, node cleanup |
| `scripts/world_spec.gd` | `WorldSpec`: constants + all scale/camera/plate math |
| `scripts/placeholder_plate.gd` | `PlaceholderPlate`: generates gradient/grid silhouette strip images |
| `scripts/plate_layer.gd` | `PlateLayer`: lays strip textures out as quads at a depth |
| `scripts/game_input.gd` | `GameInput`: registers input actions at runtime |
| `scripts/player_motor.gd` | `PlayerMotor`: pure movement maths |
| `scripts/player.gd` | `Player`: CharacterBody3D wrapper + `create()` factory |
| `scripts/camera_rig.gd` | `CameraRig`: follow/look-ahead/dead-zone/clamp + projection |
| `scripts/test_level_layout.gd` | `TestLevelLayout`: platform/wall/spawn/prop data |
| `scripts/test_level.gd` | Builds the M1 test level from the above |
| `scenes/level/test_level.tscn` | Main scene: a Node3D with `test_level.gd` |
| `tests/*_test.gd` | One test file per unit |

---

### Task 1: Test harness and project settings

**Files:**
- Create: `tools/run_tests.sh`, `tests/run_tests.gd`, `tests/test_case.gd`, `tests/project_settings_test.gd`
- Modify: `project.godot`

**Interfaces:**
- Consumes: nothing.
- Produces: `TestCase` (extends `RefCounted`) with `var tree: SceneTree`, `var failures: PackedStringArray`, `add_node(node: Node) -> Node`, `free_nodes() -> void`, `assert_true(cond: bool, msg: String)`, `assert_eq(actual: Variant, expected: Variant, msg: String)`, `assert_near(actual: float, expected: float, tol: float, msg: String)`, `assert_color_near(actual: Color, expected: Color, msg: String, tol: float = 0.01)`. Test files are `tests/<name>_test.gd`, `extends TestCase`, methods named `test_*` (may `await`). Run everything with `bash tools/run_tests.sh`.

- [ ] **Step 1: Write the runner, base class and script**

`tests/test_case.gd`:
```gdscript
class_name TestCase
extends RefCounted
## Base class for tests run by tests/run_tests.gd. Record failures with the assert_* helpers;
## nodes added with add_node() are freed after the test.

var tree: SceneTree
var failures: PackedStringArray = []
var _nodes: Array[Node] = []


func add_node(node: Node) -> Node:
	tree.root.add_child(node)
	_nodes.append(node)
	return node


func free_nodes() -> void:
	for node in _nodes:
		if is_instance_valid(node):
			node.queue_free()
	_nodes.clear()


func assert_true(cond: bool, msg: String) -> void:
	if not cond:
		failures.append(msg)


func assert_eq(actual: Variant, expected: Variant, msg: String) -> void:
	if actual != expected:
		failures.append("%s: expected <%s>, got <%s>" % [msg, expected, actual])


func assert_near(actual: float, expected: float, tol: float, msg: String) -> void:
	if absf(actual - expected) > tol:
		failures.append("%s: expected %s ± %s, got %s" % [msg, expected, tol, actual])


func assert_color_near(actual: Color, expected: Color, msg: String, tol: float = 0.01) -> void:
	var diff := maxf(maxf(absf(actual.r - expected.r), absf(actual.g - expected.g)),
			maxf(absf(actual.b - expected.b), absf(actual.a - expected.a)))
	if diff > tol:
		failures.append("%s: expected %s, got %s" % [msg, expected, actual])
```

`tests/run_tests.gd`:
```gdscript
extends SceneTree
## Headless test runner (use tools/run_tests.sh). Runs every test_* method of every
## res://tests/*_test.gd on a fresh instance. A test fails if it records an assert failure
## or if the engine logs any error while it runs. Exit code 0 = all passed, 1 = any failure.


class ErrorCounter extends Logger:
	var count := 0

	func _log_error(_function: String, _file: String, _line: int, _code: String,
			_rationale: String, _editor_notify: bool, error_type: int,
			_script_backtrace: Array[ScriptBacktrace]) -> void:
		if error_type != ERROR_TYPE_WARNING:
			count += 1


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var errors := ErrorCounter.new()
	OS.add_logger(errors)
	var passed := 0
	var failed := 0
	var files := Array(DirAccess.get_files_at("res://tests")).filter(
			func(f: String) -> bool: return f.ends_with("_test.gd"))
	files.sort()
	for file: String in files:
		var script: GDScript = load("res://tests/" + file)
		if script == null or not script.can_instantiate():
			failed += 1
			printerr("FAIL %s: script failed to load" % file)
			continue
		for method in script.get_script_method_list():
			var test_name: String = method.name
			if not test_name.begins_with("test_"):
				continue
			var errors_before := errors.count
			var t: TestCase = script.new()
			t.tree = self
			await t.call(test_name)
			t.free_nodes()
			await process_frame
			if errors.count > errors_before:
				t.failures.append("engine logged %d error(s) during the test" % (errors.count - errors_before))
			if t.failures.is_empty():
				passed += 1
			else:
				failed += 1
				printerr("FAIL %s::%s" % [file, test_name])
				for f in t.failures:
					printerr("    " + f)
	print("%d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)
```

`tools/run_tests.sh`:
```bash
#!/usr/bin/env bash
# Runs the headless GDScript test suite. Override the engine path with GODOT=...
set -euo pipefail
GODOT="${GODOT:-/c/GoDot/Godot_v4.7.2-stable_win64.exe}"
cd "$(dirname "$0")/.."
# --import refreshes the class_name cache so new scripts are visible to the runner.
"$GODOT" --headless --path . --import >/dev/null 2>&1
"$GODOT" --headless --path . --script res://tests/run_tests.gd
```

- [ ] **Step 2: Write the failing settings test**

`tests/project_settings_test.gd`:
```gdscript
extends TestCase
## Project settings must match spec §6.


func test_display_and_rendering_settings_match_spec() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_width"), 1920, "viewport width")
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_height"), 1080, "viewport height")
	assert_eq(ProjectSettings.get_setting("display/window/stretch/mode"), "canvas_items", "stretch mode")
	assert_eq(ProjectSettings.get_setting("display/window/stretch/aspect"), "expand", "stretch aspect")
	assert_eq(ProjectSettings.get_setting("rendering/anti_aliasing/quality/msaa_3d"), Viewport.MSAA_4X, "msaa 4x")
	assert_eq(ProjectSettings.get_setting("rendering/anti_aliasing/quality/use_taa"), false, "taa off")
	assert_eq(ProjectSettings.get_setting("display/window/vsync/vsync_mode"), DisplayServer.VSYNC_ENABLED, "vsync on")


func test_physics_settings_match_spec() -> void:
	assert_eq(ProjectSettings.get_setting("physics/common/physics_ticks_per_second"), 120, "120 Hz tick")
	assert_eq(ProjectSettings.get_setting("physics/common/physics_interpolation"), true, "interpolation on")
	assert_eq(ProjectSettings.get_setting("physics/3d/physics_engine"), "Jolt Physics", "Jolt")
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `bash tools/run_tests.sh`
Expected: exit code 1; `FAIL project_settings_test.gd::test_display_and_rendering_settings_match_spec` (viewport width 1152, msaa 0) and `...test_physics_settings_match_spec` (60 Hz, interpolation false); last line `0 passed, 2 failed`.

- [ ] **Step 4: Update `project.godot`**

Replace the whole file with:
```ini
; Engine configuration file.
; It's best edited using the editor UI and not directly,
; since the parameters that go here are not all obvious.
;
; Format:
;   [section] ; section goes between []
;   param=value ; assign values to parameters

config_version=5

[application]

config/name="IllustratedArtGame v1"
config/features=PackedStringArray("4.7", "Forward Plus")
config/icon="res://icon.svg"

[display]

window/size/viewport_width=1920
window/size/viewport_height=1080
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"

[physics]

common/physics_ticks_per_second=120
common/physics_interpolation=true
3d/physics_engine="Jolt Physics"

[rendering]

rendering_device/driver.windows="d3d12"
anti_aliasing/quality/msaa_3d=2
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `bash tools/run_tests.sh`
Expected: exit 0, `2 passed, 0 failed`.

- [ ] **Step 6: Prove the runner catches failures and script errors**

Create a temporary `tests/zz_runner_selfcheck_test.gd`:
```gdscript
extends TestCase


func test_assert_failure_is_reported() -> void:
	assert_true(false, "deliberate")


func test_runtime_error_is_reported() -> void:
	var a: Array = []
	var _v = a[3]
```
Run: `bash tools/run_tests.sh`
Expected: exit 1; both selfcheck tests listed as FAIL (the second with "engine logged 1 error(s)"); `2 passed, 2 failed`.
Then delete `tests/zz_runner_selfcheck_test.gd` (and its `.uid` if created) and re-run: `2 passed, 0 failed`.

- [ ] **Step 7: Commit**

```bash
git add project.godot tools/run_tests.sh tests/
git commit -m "feat: headless test runner and spec project settings

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
(`.uid` files Godot generates next to scripts are part of the project — commit them.)

---

### Task 2: WorldSpec — scale, camera and plate-size math

**Files:**
- Create: `scripts/world_spec.gd`
- Test: `tests/world_spec_test.gd`

**Interfaces:**
- Consumes: `TestCase` (Task 1).
- Produces: `class_name WorldSpec` with constants `PX_PER_M := 100.0`, `CAMERA_DISTANCE := 20.0`, `SCREEN_H := 10.8`, `LEVEL_SIZE := Vector2(134.4, 16.2)`, `MAX_ASPECT := 21.0 / 9.0`, `PLATE_MARGIN := 1.10`, `PLATE_ROUND := 64`, `STRIP_MAX_PX := 2048`, `ACTOR_Z := 0.5`; static funcs `camera_distance(depth: float) -> float`, `scroll_factor(depth: float) -> float`, `density(depth: float) -> float` (px per metre), `vfov_deg() -> float`, `screen_size(aspect: float) -> Vector2` (metres at gameplay plane), `visible_size(depth: float, aspect: float) -> Vector2`, `visible_rect(depth: float, camera_center: Vector2, aspect: float) -> Rect2`, `plate_span(depth: float, level_size: Vector2 = LEVEL_SIZE) -> Vector2`, `plate_size_px(depth: float, level_size: Vector2 = LEVEL_SIZE) -> Vector2i`, `plate_rect(depth: float, level_size: Vector2 = LEVEL_SIZE) -> Rect2`, `clamp_camera_center(center: Vector2, aspect: float, level_size: Vector2 = LEVEL_SIZE) -> Vector2`, `projection_for_aspect(aspect: float) -> Dictionary` (keys `keep_aspect: int` = `Camera3D.KEEP_HEIGHT`/`KEEP_WIDTH`, `fov: float` degrees). All rects are in world metres, Y up, `position` = bottom-left.

- [ ] **Step 1: Write the failing tests**

`tests/world_spec_test.gd`:
```gdscript
extends TestCase
## WorldSpec must reproduce spec §2–§4 numbers.

const ASPECTS := [4.0 / 3.0, 16.0 / 10.0, 16.0 / 9.0, 21.0 / 9.0, 32.0 / 9.0]
const DEPTHS := [0.0, 10.0, 40.0, 100.0, 400.0]


func test_vertical_fov_matches_spec() -> void:
	assert_near(WorldSpec.vfov_deg(), 30.22, 0.01, "vertical fov")


func test_scroll_and_density() -> void:
	assert_near(WorldSpec.scroll_factor(0.0), 1.0, 1e-6, "gameplay scroll")
	assert_near(WorldSpec.scroll_factor(10.0), 2.0 / 3.0, 1e-6, "near scroll")
	assert_near(WorldSpec.scroll_factor(-8.0), 20.0 / 12.0, 1e-6, "foreground scroll")
	assert_near(WorldSpec.density(0.0), 100.0, 1e-6, "gameplay density")
	assert_near(WorldSpec.density(100.0), 2000.0 / 120.0, 1e-6, "far density")


func test_plate_sizes_match_spec_table() -> void:
	var expected := {
		0.0: Vector2i(14784, 1792),
		10.0: Vector2i(10816, 1600),
		40.0: Vector2i(6784, 1408),
		100.0: Vector2i(4800, 1344),
		400.0: Vector2i(3392, 1280),
	}
	for depth: float in expected:
		assert_eq(WorldSpec.plate_size_px(depth), expected[depth], "plate size at depth %s" % depth)


func test_clamp_keeps_view_inside_level() -> void:
	var lo := WorldSpec.clamp_camera_center(Vector2(-1000, -1000), 16.0 / 9.0)
	assert_near(lo.x, 9.6, 1e-4, "left clamp")
	assert_near(lo.y, 5.4, 1e-4, "bottom clamp")
	var hi := WorldSpec.clamp_camera_center(Vector2(1000, 1000), 16.0 / 9.0)
	assert_near(hi.x, 134.4 - 9.6, 1e-4, "right clamp")
	assert_near(hi.y, 16.2 - 5.4, 1e-4, "top clamp")


func test_plates_cover_view_at_every_camera_extreme() -> void:
	for aspect: float in ASPECTS:
		var lo := WorldSpec.clamp_camera_center(Vector2(-1000, -1000), aspect)
		var hi := WorldSpec.clamp_camera_center(Vector2(1000, 1000), aspect)
		for center: Vector2 in [lo, hi, Vector2(lo.x, hi.y), Vector2(hi.x, lo.y)]:
			for depth: float in DEPTHS:
				var plate := WorldSpec.plate_rect(depth)
				var view := WorldSpec.visible_rect(depth, center, aspect)
				assert_true(plate.encloses(view), "depth %s aspect %.3f centre %s: plate %s must enclose view %s"
						% [depth, aspect, center, plate, view])


func test_projection_keeps_height_up_to_21_9() -> void:
	for aspect: float in [4.0 / 3.0, 16.0 / 9.0, 21.0 / 9.0]:
		var p := WorldSpec.projection_for_aspect(aspect)
		assert_eq(p.keep_aspect, Camera3D.KEEP_HEIGHT, "keep height at %.3f" % aspect)
		assert_near(p.fov, WorldSpec.vfov_deg(), 1e-4, "vertical fov at %.3f" % aspect)


func test_projection_keeps_21_9_width_beyond() -> void:
	var p := WorldSpec.projection_for_aspect(32.0 / 9.0)
	assert_eq(p.keep_aspect, Camera3D.KEEP_WIDTH, "keep width at 32:9")
	var width_at_plane := tan(deg_to_rad(p.fov) * 0.5) * 2.0 * WorldSpec.CAMERA_DISTANCE
	assert_near(width_at_plane, 25.2, 1e-3, "32:9 shows exactly the 21:9 width")
	assert_near(WorldSpec.screen_size(32.0 / 9.0).y, 25.2 / (32.0 / 9.0), 1e-4, "32:9 crops height")
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bash tools/run_tests.sh`
Expected: exit 1; `FAIL world_spec_test.gd: script failed to load` (WorldSpec does not exist).

- [ ] **Step 3: Implement `scripts/world_spec.gd`**

```gdscript
class_name WorldSpec
extends RefCounted
## Single source of truth for world scale, camera and plate-size math (spec §2–§4).
## Coordinates: metres, X right, Y up, level origin at (0, 0). "Depth" is distance behind
## the gameplay plane; a layer at depth z sits at world Z = -z.

const PX_PER_M := 100.0 ## Texels per metre at the gameplay plane (1080p).
const CAMERA_DISTANCE := 20.0 ## Camera to gameplay plane, metres.
const SCREEN_H := 10.8 ## Metres visible vertically at the gameplay plane.
const LEVEL_SIZE := Vector2(134.4, 16.2)
const MAX_ASPECT := 21.0 / 9.0 ## Widest aspect that shows extra width; wider crops height.
const PLATE_MARGIN := 1.10 ## Slack for shake, dolly and look-ahead.
const PLATE_ROUND := 64
const STRIP_MAX_PX := 2048
const ACTOR_Z := 0.5 ## Actor/platform visuals sit this far in front of the gameplay plate.


static func camera_distance(depth: float) -> float:
	return CAMERA_DISTANCE + depth


## How fast a layer scrolls relative to the gameplay plane.
static func scroll_factor(depth: float) -> float:
	return CAMERA_DISTANCE / camera_distance(depth)


## Texels per metre needed at this depth for 1 texel per screen pixel at 1080p.
static func density(depth: float) -> float:
	return PX_PER_M * scroll_factor(depth)


static func vfov_deg() -> float:
	return rad_to_deg(2.0 * atan(SCREEN_H * 0.5 / CAMERA_DISTANCE))


## Metres visible at the gameplay plane for a viewport aspect.
static func screen_size(aspect: float) -> Vector2:
	if aspect > MAX_ASPECT:
		var w := SCREEN_H * MAX_ASPECT
		return Vector2(w, w / aspect)
	return Vector2(SCREEN_H * aspect, SCREEN_H)


static func visible_size(depth: float, aspect: float) -> Vector2:
	return screen_size(aspect) * camera_distance(depth) / CAMERA_DISTANCE


static func visible_rect(depth: float, camera_center: Vector2, aspect: float) -> Rect2:
	var size := visible_size(depth, aspect)
	return Rect2(camera_center - size * 0.5, size)


## World area (metres) a layer at this depth must cover while the camera roams the level.
static func plate_span(depth: float, level_size: Vector2 = LEVEL_SIZE) -> Vector2:
	var k := camera_distance(depth) / CAMERA_DISTANCE - 1.0
	return level_size + screen_size(MAX_ASPECT) * k


static func plate_size_px(depth: float, level_size: Vector2 = LEVEL_SIZE) -> Vector2i:
	var px := plate_span(depth, level_size) * density(depth) * PLATE_MARGIN
	return Vector2i(_round_up(px.x), _round_up(px.y))


## The plate's world rect: plate_size_px at this depth's density, centred on the level.
static func plate_rect(depth: float, level_size: Vector2 = LEVEL_SIZE) -> Rect2:
	var size := Vector2(plate_size_px(depth, level_size)) / density(depth)
	return Rect2(level_size * 0.5 - size * 0.5, size)


static func clamp_camera_center(center: Vector2, aspect: float, level_size: Vector2 = LEVEL_SIZE) -> Vector2:
	var half := screen_size(aspect) * 0.5
	return Vector2(clampf(center.x, half.x, level_size.x - half.x),
			clampf(center.y, half.y, level_size.y - half.y))


## Camera3D keep_aspect + fov (degrees) for a viewport aspect.
static func projection_for_aspect(aspect: float) -> Dictionary:
	if aspect > MAX_ASPECT:
		var half_w := SCREEN_H * MAX_ASPECT * 0.5
		return {"keep_aspect": Camera3D.KEEP_WIDTH, "fov": rad_to_deg(2.0 * atan(half_w / CAMERA_DISTANCE))}
	return {"keep_aspect": Camera3D.KEEP_HEIGHT, "fov": vfov_deg()}


# Round up to PLATE_ROUND; the tolerance stops float noise (14784.000000002) adding a step.
static func _round_up(v: float) -> int:
	return int(ceil(v / PLATE_ROUND - 1e-6)) * PLATE_ROUND
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bash tools/run_tests.sh`
Expected: exit 0, `9 passed, 0 failed`.

- [ ] **Step 5: Commit**

```bash
git add scripts/world_spec.gd* tests/world_spec_test.gd*
git commit -m "feat: WorldSpec scale, camera and plate-size math

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Placeholder plates and PlateLayer

**Files:**
- Create: `scripts/placeholder_plate.gd`, `scripts/plate_layer.gd`
- Test: `tests/placeholder_plate_test.gd`, `tests/plate_layer_test.gd`

**Interfaces:**
- Consumes: `WorldSpec.plate_rect`, `WorldSpec.density`, `WorldSpec.STRIP_MAX_PX` (Task 2).
- Produces:
  - `class_name PlaceholderPlate`: `static func generate_strip(plate_size: Vector2i, x0: int, width: int, px_per_m: float, top: Color, bottom: Color, fill_from: float) -> Image` (RGBA8, `width × plate_size.y`, transparent above the silhouette; `fill_from` 0 = fully opaque); `static func silhouette_top(abs_x: int, h: int, px_per_m: float, fill_from: float) -> int`; `static func grid_color(top: Color, bottom: Color) -> Color`.
  - `class_name PlateLayer extends Node3D`: `var depth: float`; `func build(p_depth: float, strips: Array[Texture2D], lit: bool, level_size: Vector2 = WorldSpec.LEVEL_SIZE, fog: bool = true) -> void` (adds one `MeshInstance3D` with `QuadMesh` per strip, left to right); `static func strip_widths(total_px: int) -> PackedInt32Array`; `static func make_material(tex: Texture2D, lit: bool, fog: bool) -> StandardMaterial3D`.

- [ ] **Step 1: Write the failing tests**

`tests/placeholder_plate_test.gd`:
```gdscript
extends TestCase
## Placeholder plates: exact size, opaque silhouette below fill_from, transparent above, 1 m grid.

const SIZE := Vector2i(256, 128)
const PPM := 20.0
const TOP := Color(0.2, 0.4, 0.8)
const BOTTOM := Color(0.9, 0.8, 0.6)


func test_strip_has_requested_size() -> void:
	var img := PlaceholderPlate.generate_strip(SIZE, 64, 100, PPM, TOP, BOTTOM, 0.5)
	assert_eq(img.get_size(), Vector2i(100, 128), "strip size")
	assert_eq(img.get_format(), Image.FORMAT_RGBA8, "format")


func test_fully_opaque_when_fill_from_zero() -> void:
	var img := PlaceholderPlate.generate_strip(SIZE, 0, SIZE.x, PPM, TOP, BOTTOM, 0.0)
	assert_near(img.get_pixel(5, 0).a, 1.0, 0.01, "top-left opaque")
	assert_near(img.get_pixel(250, 127).a, 1.0, 0.01, "bottom-right opaque")


func test_transparent_above_silhouette_opaque_below() -> void:
	var img := PlaceholderPlate.generate_strip(SIZE, 0, SIZE.x, PPM, TOP, BOTTOM, 0.5)
	for x in [5, 100, 250]:
		var y_top := PlaceholderPlate.silhouette_top(x, SIZE.y, PPM, 0.5)
		assert_near(img.get_pixel(x, 0).a, 0.0, 0.01, "above silhouette at x=%d" % x)
		assert_near(img.get_pixel(x, y_top).a, 1.0, 0.01, "silhouette top at x=%d" % x)
		assert_near(img.get_pixel(x, SIZE.y - 1).a, 1.0, 0.01, "bottom at x=%d" % x)


func test_vertical_grid_line_every_metre() -> void:
	var img := PlaceholderPlate.generate_strip(SIZE, 0, SIZE.x, PPM, TOP, BOTTOM, 0.0)
	var grid := PlaceholderPlate.grid_color(TOP, BOTTOM)
	assert_color_near(img.get_pixel(20, SIZE.y - 5), grid, "line at 1 m")
	assert_color_near(img.get_pixel(40, SIZE.y - 5), grid, "line at 2 m")
	assert_true(not img.get_pixel(30, SIZE.y - 5).is_equal_approx(grid), "no line at 1.5 m")


func test_strips_join_seamlessly() -> void:
	# The same absolute column must look identical whichever strip generates it.
	var whole := PlaceholderPlate.generate_strip(SIZE, 0, SIZE.x, PPM, TOP, BOTTOM, 0.5)
	var right := PlaceholderPlate.generate_strip(SIZE, 128, 128, PPM, TOP, BOTTOM, 0.5)
	for y in [0, 60, 90, 127]:
		assert_color_near(right.get_pixel(3, y), whole.get_pixel(131, y), "column 131 row %d" % y)
```

`tests/plate_layer_test.gd`:
```gdscript
extends TestCase
## PlateLayer lays strips edge to edge over WorldSpec.plate_rect at the right depth.


func _blank_strips(depth: float) -> Array[Texture2D]:
	var size := WorldSpec.plate_size_px(depth)
	var strips: Array[Texture2D] = []
	for w in PlateLayer.strip_widths(size.x):
		strips.append(ImageTexture.create_from_image(Image.create_empty(w, size.y, false, Image.FORMAT_RGBA8)))
	return strips


func test_strip_widths_split_at_max() -> void:
	assert_eq(PlateLayer.strip_widths(2048), PackedInt32Array([2048]), "exact")
	assert_eq(PlateLayer.strip_widths(3392), PackedInt32Array([2048, 1344]), "sky")
	var w := PlateLayer.strip_widths(14784)
	assert_eq(w.size(), 8, "gameplay strip count")
	assert_eq(w[7], 448, "gameplay last strip")


func test_build_places_strips_edge_to_edge_over_plate_rect() -> void:
	var depth := 40.0
	var strips := _blank_strips(depth)
	var layer := PlateLayer.new()
	layer.build(depth, strips, false)
	var rect := WorldSpec.plate_rect(depth)
	assert_eq(layer.get_child_count(), strips.size(), "one quad per strip")
	assert_near(layer.position.z, -depth, 1e-6, "layer z")
	var prev_right := rect.position.x
	for mi: MeshInstance3D in layer.get_children():
		var half: Vector2 = (mi.mesh as QuadMesh).size * 0.5
		assert_near(mi.position.x - half.x, prev_right, 1e-3, "strip starts where previous ended")
		assert_near(mi.position.y - half.y, rect.position.y, 1e-4, "strip bottom")
		assert_near(mi.position.y + half.y, rect.end.y, 1e-4, "strip top")
		prev_right = mi.position.x + half.x
	assert_near(prev_right, rect.end.x, 1e-3, "last strip ends at plate right edge")
	layer.free()


func test_material_flags() -> void:
	var tex := ImageTexture.create_from_image(Image.create_empty(4, 4, false, Image.FORMAT_RGBA8))
	var unlit := PlateLayer.make_material(tex, false, true)
	assert_eq(unlit.shading_mode, BaseMaterial3D.SHADING_MODE_UNSHADED, "unshaded by default")
	assert_eq(unlit.transparency, BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR, "alpha scissor")
	assert_eq(unlit.disable_fog, false, "fogged")
	var lit_nofog := PlateLayer.make_material(tex, true, false)
	assert_eq(lit_nofog.shading_mode, BaseMaterial3D.SHADING_MODE_PER_PIXEL, "lit")
	assert_eq(lit_nofog.disable_fog, true, "fog disabled (sky)")
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bash tools/run_tests.sh`
Expected: exit 1; both new files `script failed to load`.

- [ ] **Step 3: Implement `scripts/placeholder_plate.gd`**

```gdscript
class_name PlaceholderPlate
extends RefCounted
## Script-generated stand-in plates (spec §9, M1): a gradient silhouette with a 1 m grid,
## so scroll speed and texel density are visible before real art exists.

const COLUMN_PX := 16 ## Silhouette height is constant across each column of this width.
const LINE_PX := 2
const MAJOR_EVERY_M := 5 ## Every 5th vertical line is drawn twice as thick.


## Columns [x0, x0 + width) of a plate plate_size px big. fill_from: fraction of the plate
## height (from the top) where the opaque silhouette begins; 0 = fully opaque.
static func generate_strip(plate_size: Vector2i, x0: int, width: int, px_per_m: float,
		top: Color, bottom: Color, fill_from: float) -> Image:
	var h := plate_size.y
	var img := Image.create_empty(width, h, false, Image.FORMAT_RGBA8)
	var column := _column(h, px_per_m, top, bottom)
	var x := 0
	while x < width:
		var w := mini(COLUMN_PX - (x0 + x) % COLUMN_PX, width - x)
		var y_top := silhouette_top(x0 + x, h, px_per_m, fill_from)
		img.blit_rect(column, Rect2i(0, y_top, w, h - y_top), Vector2i(x, y_top))
		x += w
	var grid := grid_color(top, bottom)
	var m := int(ceil(x0 / px_per_m))
	while true:
		var gx := int(round(m * px_per_m)) - x0
		if gx >= width:
			break
		var line_w := LINE_PX * (2 if m % MAJOR_EVERY_M == 0 else 1)
		var y_top := silhouette_top(x0 + gx, h, px_per_m, fill_from)
		img.fill_rect(Rect2i(gx, y_top, mini(line_w, width - gx), h - y_top), grid)
		m += 1
	return img


## Top row of the opaque silhouette at an absolute plate column.
static func silhouette_top(abs_x: int, h: int, px_per_m: float, fill_from: float) -> int:
	if fill_from <= 0.0:
		return 0
	var x := float(abs_x - abs_x % COLUMN_PX)
	var phase := x / (12.0 * px_per_m) * TAU # 12 m wavelength in world space
	var wave := sin(phase) * 0.06 + sin(phase * 2.7) * 0.03
	return clampi(int((fill_from + wave) * h), 0, h - 1)


static func grid_color(top: Color, bottom: Color) -> Color:
	return top.lerp(bottom, 0.5).darkened(0.45)


# One COLUMN_PX-wide gradient column with horizontal grid lines every metre from the bottom.
static func _column(h: int, px_per_m: float, top: Color, bottom: Color) -> Image:
	var col := Image.create_empty(COLUMN_PX, h, false, Image.FORMAT_RGBA8)
	for y in h:
		col.fill_rect(Rect2i(0, y, COLUMN_PX, 1), top.lerp(bottom, float(y) / maxf(h - 1, 1)))
	var grid := grid_color(top, bottom)
	var m := 1
	while true:
		var gy := h - int(round(m * px_per_m))
		if gy < 0:
			break
		col.fill_rect(Rect2i(0, gy, COLUMN_PX, LINE_PX), grid)
		m += 1
	return col
```

Note: the column-width expression `COLUMN_PX - (x0 + x) % COLUMN_PX` keeps blits aligned to absolute columns, so strips join seamlessly even when `x0` is not a multiple of 16 (the seam test uses `x0 = 128`, which is aligned; the expression also covers unaligned callers).

- [ ] **Step 4: Implement `scripts/plate_layer.gd`**

```gdscript
class_name PlateLayer
extends Node3D
## One depth layer of painted plates: a row of quad strips covering WorldSpec.plate_rect,
## so the layer fills the view from every camera position. Sits at world Z = -depth.

var depth := 0.0


## strips: textures laid left to right, sharing one height, together
## WorldSpec.plate_size_px(depth, level_size).x wide.
func build(p_depth: float, strips: Array[Texture2D], lit: bool,
		level_size: Vector2 = WorldSpec.LEVEL_SIZE, fog: bool = true) -> void:
	depth = p_depth
	position = Vector3(0.0, 0.0, -depth)
	var rect := WorldSpec.plate_rect(depth, level_size)
	var px_per_m := WorldSpec.density(depth)
	var x := rect.position.x
	for tex in strips:
		var size_m := Vector2(tex.get_width(), tex.get_height()) / px_per_m
		var quad := QuadMesh.new()
		quad.size = size_m
		var mi := MeshInstance3D.new()
		mi.mesh = quad
		mi.material_override = make_material(tex, lit, fog)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = Vector3(x + size_m.x * 0.5, rect.position.y + size_m.y * 0.5, 0.0)
		add_child(mi)
		x += size_m.x


static func strip_widths(total_px: int) -> PackedInt32Array:
	var widths := PackedInt32Array()
	var left := total_px
	while left > 0:
		widths.append(mini(left, WorldSpec.STRIP_MAX_PX))
		left -= WorldSpec.STRIP_MAX_PX
	return widths


static func make_material(tex: Texture2D, lit: bool, fog: bool) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.alpha_scissor_threshold = 0.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL if lit else BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.disable_fog = not fog
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return mat
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `bash tools/run_tests.sh`
Expected: exit 0, `17 passed, 0 failed`.

- [ ] **Step 6: Commit**

```bash
git add scripts/placeholder_plate.gd* scripts/plate_layer.gd* tests/placeholder_plate_test.gd* tests/plate_layer_test.gd*
git commit -m "feat: placeholder plate generator and PlateLayer strip layout

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Input, PlayerMotor and Player

**Files:**
- Create: `scripts/game_input.gd`, `scripts/player_motor.gd`, `scripts/player.gd`
- Test: `tests/player_test.gd`

**Interfaces:**
- Consumes: `WorldSpec.ACTOR_Z` (Task 2).
- Produces:
  - `class_name GameInput`: `static func ensure_actions() -> void` registering `&"move_left"`, `&"move_right"`, `&"jump"` once.
  - `class_name PlayerMotor`: constants `RUN_SPEED := 8.0`, `ACCEL := 60.0`, `AIR_ACCEL := 35.0`, `GRAVITY := 30.0`, `JUMP_VELOCITY := 13.5`, `MAX_FALL_SPEED := 25.0`; `static func step(v: Vector3, input_x: float, jump: bool, on_floor: bool, delta: float) -> Vector3`.
  - `class_name Player extends CharacterBody3D`: `const RADIUS := 0.4`, `const HEIGHT := 1.8`; `var facing := 1.0` (±1, last horizontal input direction); `var autorun := false` (forces input_x = 1); `static func create() -> Player` (collision capsule at z 0, visual capsule child named `"Visual"` at z = `WorldSpec.ACTOR_Z`, Z axis locked).

- [ ] **Step 1: Write the failing tests**

`tests/player_test.gd`:
```gdscript
extends TestCase
## Movement maths, input registration and the Player node on a floor.


func test_actions_registered_once() -> void:
	GameInput.ensure_actions()
	GameInput.ensure_actions()
	for action in [&"move_left", &"move_right", &"jump"]:
		assert_true(InputMap.has_action(action), "action %s exists" % action)
	assert_eq(InputMap.action_get_events(&"jump").size(), 4, "jump bindings not duplicated")
	assert_eq(InputMap.action_get_events(&"move_left").size(), 3, "move_left bindings")


func test_accelerates_to_run_speed_without_exceeding() -> void:
	var v := Vector3.ZERO
	for i in 120:
		v = PlayerMotor.step(v, 1.0, false, true, 1.0 / 120.0)
		assert_true(v.x <= PlayerMotor.RUN_SPEED + 1e-4, "never exceeds run speed")
	assert_near(v.x, PlayerMotor.RUN_SPEED, 1e-4, "reaches run speed within 1 s")


func test_jump_only_from_floor() -> void:
	var grounded := PlayerMotor.step(Vector3.ZERO, 0.0, true, true, 1.0 / 120.0)
	assert_near(grounded.y, PlayerMotor.JUMP_VELOCITY, 1e-4, "jumps from floor")
	var airborne := PlayerMotor.step(Vector3(0, 2, 0), 0.0, true, false, 0.1)
	assert_near(airborne.y, 2.0 - PlayerMotor.GRAVITY * 0.1, 1e-4, "no mid-air jump, gravity applies")


func test_fall_speed_capped_even_with_huge_delta() -> void:
	var v := PlayerMotor.step(Vector3.ZERO, 0.0, false, false, 0.5)
	assert_near(v.y, -PlayerMotor.MAX_FALL_SPEED, 1e-4, "hitch frame capped")


func test_z_velocity_always_zero() -> void:
	var v := PlayerMotor.step(Vector3(1, 1, 5), 1.0, false, false, 0.016)
	assert_eq(v.z, 0.0, "z zeroed")


func test_visual_sits_in_front_of_gameplay_plate() -> void:
	var p := Player.create()
	var visual := p.get_node("Visual") as MeshInstance3D
	assert_true(visual.position.z - Player.RADIUS > 0.0, "whole capsule visual is in front of z = 0")
	assert_true(p.axis_lock_linear_z, "z locked")
	p.free()


func test_player_falls_and_lands_on_floor() -> void:
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20, 1, 2)
	shape.shape = box
	floor_body.add_child(shape)
	add_node(floor_body)
	var p := Player.create()
	p.position = Vector3(0, 3, 0)
	add_node(p)
	for i in 240:
		await tree.physics_frame
		if p.is_on_floor():
			break
	assert_true(p.is_on_floor(), "lands within 2 s")
	assert_near(p.position.y, 0.5 + Player.HEIGHT * 0.5, 0.05, "capsule rests on floor top")
	assert_near(p.position.z, 0.0, 1e-4, "stays on the gameplay plane")
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bash tools/run_tests.sh`
Expected: exit 1; `FAIL player_test.gd: script failed to load`.

- [ ] **Step 3: Implement `scripts/game_input.gd`**

```gdscript
class_name GameInput
extends RefCounted
## Registers the game's input actions at runtime so project.godot stays hand-editable.

const KEYS := {
	&"move_left": [KEY_A, KEY_LEFT],
	&"move_right": [KEY_D, KEY_RIGHT],
	&"jump": [KEY_SPACE, KEY_W, KEY_UP],
}
const PAD_BUTTONS := {
	&"move_left": JOY_BUTTON_DPAD_LEFT,
	&"move_right": JOY_BUTTON_DPAD_RIGHT,
	&"jump": JOY_BUTTON_A,
}


static func ensure_actions() -> void:
	for action: StringName in KEYS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key: Key in KEYS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
		var pad := InputEventJoypadButton.new()
		pad.button_index = PAD_BUTTONS[action]
		InputMap.action_add_event(action, pad)
```

- [ ] **Step 4: Implement `scripts/player_motor.gd`**

```gdscript
class_name PlayerMotor
extends RefCounted
## Pure platformer movement maths (metres, seconds), unit-testable without physics.

const RUN_SPEED := 8.0
const ACCEL := 60.0
const AIR_ACCEL := 35.0
const GRAVITY := 30.0
const JUMP_VELOCITY := 13.5 ## Apex ≈ 3 m.
const MAX_FALL_SPEED := 25.0


static func step(v: Vector3, input_x: float, jump: bool, on_floor: bool, delta: float) -> Vector3:
	var accel := ACCEL if on_floor else AIR_ACCEL
	v.x = move_toward(v.x, clampf(input_x, -1.0, 1.0) * RUN_SPEED, accel * delta)
	if on_floor and jump:
		v.y = JUMP_VELOCITY
	elif not on_floor:
		v.y = maxf(v.y - GRAVITY * delta, -MAX_FALL_SPEED)
	v.z = 0.0
	return v
```

- [ ] **Step 5: Implement `scripts/player.gd`**

```gdscript
class_name Player
extends CharacterBody3D
## Capsule player on the gameplay plane. Collision at z = 0; the visual is offset to
## WorldSpec.ACTOR_Z so it always draws in front of the gameplay plate.

const RADIUS := 0.4
const HEIGHT := 1.8

var facing := 1.0 ## +1 right, -1 left; read by CameraRig for look-ahead.
var autorun := false ## Forces running right (demo / capture runs).


static func create() -> Player:
	var player := Player.new()
	player.axis_lock_linear_z = true
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = RADIUS
	capsule.height = HEIGHT
	shape.shape = capsule
	player.add_child(shape)
	var visual := MeshInstance3D.new()
	visual.name = "Visual"
	var mesh := CapsuleMesh.new()
	mesh.radius = RADIUS
	mesh.height = HEIGHT
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.55, 0.2)
	mesh.material = mat
	visual.mesh = mesh
	visual.position.z = WorldSpec.ACTOR_Z
	player.add_child(visual)
	return player


func _ready() -> void:
	GameInput.ensure_actions()


func _physics_process(delta: float) -> void:
	var input_x := 1.0 if autorun else Input.get_axis(&"move_left", &"move_right")
	if input_x != 0.0:
		facing = signf(input_x)
	velocity = PlayerMotor.step(velocity, input_x, Input.is_action_just_pressed(&"jump"), is_on_floor(), delta)
	move_and_slide()
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `bash tools/run_tests.sh`
Expected: exit 0, `24 passed, 0 failed`.

- [ ] **Step 7: Commit**

```bash
git add scripts/game_input.gd* scripts/player_motor.gd* scripts/player.gd* tests/player_test.gd*
git commit -m "feat: input actions, PlayerMotor and capsule Player

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: CameraRig

**Files:**
- Create: `scripts/camera_rig.gd`
- Test: `tests/camera_rig_test.gd`

**Interfaces:**
- Consumes: `WorldSpec.CAMERA_DISTANCE`, `WorldSpec.clamp_camera_center`, `WorldSpec.projection_for_aspect`, `WorldSpec.LEVEL_SIZE` (Task 2); `Player.facing` (Task 4).
- Produces: `class_name CameraRig extends Node3D`: constants `LOOK_AHEAD := 2.5`, `LOOK_AHEAD_RATE := 2.0`, `FOLLOW_RATE := 6.0`, `DEAD_ZONE_HALF := 1.5`, `FOCUS_OFFSET_Y := 1.5`; vars `target: Node3D`, `level_size: Vector2`, `aspect_override: float` (> 0 forces an aspect), `camera: Camera3D` (created in `_ready`); funcs `aspect() -> float`, `apply_projection() -> void`, `snap_to_target() -> void`; statics `smooth(current: float, goal: float, rate: float, delta: float) -> float`, `dead_zone(focus: float, target_y: float, half: float) -> float`.

- [ ] **Step 1: Write the failing tests**

`tests/camera_rig_test.gd`:
```gdscript
extends TestCase
## CameraRig: smoothing, dead zone, clamped snap, follow with look-ahead, projection per aspect.


func _rig(target_pos: Vector3, aspect: float) -> CameraRig:
	var target := Node3D.new()
	target.position = target_pos
	add_node(target)
	var rig := CameraRig.new()
	rig.target = target
	rig.aspect_override = aspect
	add_node(rig)
	return rig


func test_smooth_never_overshoots() -> void:
	assert_near(CameraRig.smooth(0.0, 10.0, 6.0, 0.0), 0.0, 1e-6, "zero delta holds")
	var hitch := CameraRig.smooth(0.0, 10.0, 6.0, 5.0)
	assert_true(hitch <= 10.0 and hitch > 9.99, "huge delta lands on goal, not past it: %s" % hitch)


func test_dead_zone() -> void:
	assert_eq(CameraRig.dead_zone(5.0, 5.5, 1.5), 5.0, "small move ignored")
	assert_eq(CameraRig.dead_zone(5.0, 8.0, 1.5), 6.5, "large move pulls focus to zone edge")
	assert_eq(CameraRig.dead_zone(5.0, 2.0, 1.5), 3.5, "downward too")


func test_camera_child_at_spec_distance() -> void:
	var rig := _rig(Vector3(60, 5, 0), 16.0 / 9.0)
	assert_near(rig.camera.position.z, WorldSpec.CAMERA_DISTANCE, 1e-6, "20 m in front")
	assert_true(rig.camera.current, "camera is current")


func test_snap_frames_target_clamped() -> void:
	var rig := _rig(Vector3(4, 1.9, 0), 16.0 / 9.0)
	rig.snap_to_target()
	assert_near(rig.position.x, 9.6, 1e-4, "clamped to left edge")
	assert_near(rig.position.y, 5.4, 1e-4, "clamped to bottom edge")
	var mid := _rig(Vector3(60, 8, 0), 16.0 / 9.0)
	mid.snap_to_target()
	assert_near(mid.position.x, 60.0, 1e-4, "mid-level snap centres on target")
	assert_near(mid.position.y, 8.0 + CameraRig.FOCUS_OFFSET_Y, 1e-4, "focus offset above target")


func test_follow_adds_look_ahead() -> void:
	var rig := _rig(Vector3(60, 8, 0), 16.0 / 9.0)
	rig.snap_to_target()
	for i in 40:
		rig._physics_process(0.25)
	assert_near(rig.position.x, 60.0 + CameraRig.LOOK_AHEAD, 0.01, "settles look-ahead in front")


func test_projection_follows_aspect_changes() -> void:
	var rig := _rig(Vector3(60, 8, 0), 16.0 / 9.0)
	assert_eq(rig.camera.keep_aspect, Camera3D.KEEP_HEIGHT, "16:9 keeps height")
	assert_near(rig.camera.fov, WorldSpec.vfov_deg(), 1e-4, "16:9 fov")
	rig.aspect_override = 32.0 / 9.0
	rig.apply_projection()
	assert_eq(rig.camera.keep_aspect, Camera3D.KEEP_WIDTH, "32:9 keeps 21:9 width")
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bash tools/run_tests.sh`
Expected: exit 1; `FAIL camera_rig_test.gd: script failed to load`.

- [ ] **Step 3: Implement `scripts/camera_rig.gd`**

```gdscript
class_name CameraRig
extends Node3D
## Follows a target on the gameplay plane (spec §5.4). The rig moves in X/Y at z = 0 and its
## Camera3D child sits WorldSpec.CAMERA_DISTANCE in front, so parallax comes from perspective.
## Distance and FOV are never animated here (spec §2 invariant); only X/Y follow.

const LOOK_AHEAD := 2.5 ## Metres shown ahead of the facing direction.
const LOOK_AHEAD_RATE := 2.0 ## 1/s; how fast look-ahead swings on a turn.
const FOLLOW_RATE := 6.0 ## 1/s; exponential follow smoothing.
const DEAD_ZONE_HALF := 1.5 ## Metres of vertical free play before the camera follows.
const FOCUS_OFFSET_Y := 1.5 ## Camera centre sits this far above the target.

var target: Node3D
var level_size := WorldSpec.LEVEL_SIZE
var aspect_override := 0.0 ## > 0 forces an aspect (tests); 0 reads the viewport.
var camera: Camera3D

var _look := 0.0
var _focus_y := 0.0


func _ready() -> void:
	camera = Camera3D.new()
	camera.position = Vector3(0.0, 0.0, WorldSpec.CAMERA_DISTANCE)
	camera.far = 1000.0
	add_child(camera)
	camera.make_current()
	get_viewport().size_changed.connect(apply_projection)
	apply_projection()


func aspect() -> float:
	if aspect_override > 0.0:
		return aspect_override
	var size := get_viewport().get_visible_rect().size
	return size.x / maxf(size.y, 1.0)


func apply_projection() -> void:
	var proj := WorldSpec.projection_for_aspect(aspect())
	camera.keep_aspect = proj.keep_aspect
	camera.fov = proj.fov


## Jump straight to the target (level start / respawn) with no smoothing.
func snap_to_target() -> void:
	_look = 0.0
	_focus_y = target.global_position.y
	var c := WorldSpec.clamp_camera_center(_goal(), aspect(), level_size)
	position = Vector3(c.x, c.y, 0.0)
	reset_physics_interpolation()


func _physics_process(delta: float) -> void:
	if target == null:
		return
	var facing: float = (target as Player).facing if target is Player else 1.0
	_look = smooth(_look, facing * LOOK_AHEAD, LOOK_AHEAD_RATE, delta)
	_focus_y = dead_zone(_focus_y, target.global_position.y, DEAD_ZONE_HALF)
	var goal := WorldSpec.clamp_camera_center(_goal(), aspect(), level_size)
	position.x = smooth(position.x, goal.x, FOLLOW_RATE, delta)
	position.y = smooth(position.y, goal.y, FOLLOW_RATE, delta)


func _goal() -> Vector2:
	return Vector2(target.global_position.x + _look, _focus_y + FOCUS_OFFSET_Y)


## Frame-rate independent exponential approach; never overshoots, even for huge delta.
static func smooth(current: float, goal: float, rate: float, delta: float) -> float:
	return lerpf(current, goal, 1.0 - exp(-rate * delta))


static func dead_zone(focus: float, target_y: float, half: float) -> float:
	return clampf(focus, target_y - half, target_y + half)
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bash tools/run_tests.sh`
Expected: exit 0, `30 passed, 0 failed`.

- [ ] **Step 5: Commit**

```bash
git add scripts/camera_rig.gd* tests/camera_rig_test.gd*
git commit -m "feat: CameraRig with follow, look-ahead, dead zone, clamp and aspect projection

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: Test level assembly and visual verification

**Files:**
- Create: `scripts/test_level_layout.gd`, `scripts/test_level.gd`, `scenes/level/test_level.tscn`
- Modify: `project.godot` (`[application]` main scene)
- Test: `tests/test_level_test.gd`

**Interfaces:**
- Consumes: everything above — `WorldSpec`, `PlaceholderPlate.generate_strip`, `PlateLayer.build/strip_widths`, `Player.create/autorun`, `CameraRig.target/level_size/snap_to_target/camera`.
- Produces:
  - `class_name TestLevelLayout`: `const SPAWN := Vector2(4.0, 2.5)`, `const LANTERN := Vector2(30.0, 5.5)`, `const FOREGROUND_DEPTH := -8.0`, `const FOREGROUND_PROP_SIZE := Vector2(1.2, 9.0)`, `const FOREGROUND_PROPS_X := [15.0, 37.0, 59.0, 81.0, 103.0, 125.0]`; `static func platforms() -> Array[Rect2]` (index 0 = floor), `static func walls() -> Array[Rect2]`. Rects: metres, Y up, position = bottom-left.
  - `test_level.gd` (root script, no class_name): `var layers: Array[PlateLayer]`, `var player: Player`, `var rig: CameraRig`, `var blocks: Array[StaticBody3D]`. User args after `--`: `--autorun`, `--spawn-x=<metres>`.

- [ ] **Step 1: Write the failing tests**

`tests/test_level_test.gd`:
```gdscript
extends TestCase
## Test level layout data and full assembly.


func test_floor_spans_level() -> void:
	var floor_rect: Rect2 = TestLevelLayout.platforms()[0]
	assert_near(floor_rect.position.x, 0.0, 1e-6, "floor starts at 0")
	assert_near(floor_rect.end.x, WorldSpec.LEVEL_SIZE.x, 1e-6, "floor reaches level end")


func test_platforms_inside_level_and_reachable_height() -> void:
	for r: Rect2 in TestLevelLayout.platforms():
		assert_true(Rect2(Vector2.ZERO, WorldSpec.LEVEL_SIZE).encloses(r), "platform %s inside level" % r)
		assert_true(r.end.y <= WorldSpec.LEVEL_SIZE.y - 3.0, "platform %s leaves head room" % r)


func test_walls_close_both_ends() -> void:
	var walls := TestLevelLayout.walls()
	var left := walls.any(func(r: Rect2) -> bool: return r.end.x <= 0.0 and r.end.x > -0.01 and r.end.y >= WorldSpec.LEVEL_SIZE.y)
	var right := walls.any(func(r: Rect2) -> bool: return r.position.x >= WorldSpec.LEVEL_SIZE.x - 0.01 and r.position.x <= WorldSpec.LEVEL_SIZE.x and r.end.y >= WorldSpec.LEVEL_SIZE.y)
	assert_true(left, "wall flush with left edge, full height")
	assert_true(right, "wall flush with right edge, full height")


func test_level_builds_layers_player_and_camera() -> void:
	var level = add_node(load("res://scenes/level/test_level.tscn").instantiate()) # untyped: reads test_level.gd vars
	await tree.process_frame
	var depths: Array[float] = []
	for layer: PlateLayer in level.layers:
		depths.append(layer.depth)
		var total := 0
		for mi: MeshInstance3D in layer.get_children():
			total += (mi.material_override as StandardMaterial3D).albedo_texture.get_width()
		assert_eq(total, WorldSpec.plate_size_px(layer.depth).x, "strip widths sum to plate at depth %s" % layer.depth)
	depths.sort()
	assert_eq(depths, [0.0, 10.0, 40.0, 100.0, 400.0] as Array[float], "five plate layers")
	assert_true(level.player is Player, "player spawned")
	assert_true(level.rig.camera.current, "rig camera current")
	var expected := WorldSpec.clamp_camera_center(
			Vector2(TestLevelLayout.SPAWN.x, TestLevelLayout.SPAWN.y + CameraRig.FOCUS_OFFSET_Y), level.rig.aspect())
	assert_near(level.rig.position.x, expected.x, 1e-3, "camera starts framed on spawn (x)")
	assert_near(level.rig.position.y, expected.y, 1e-3, "camera starts framed on spawn (y)")


func test_platform_visuals_in_front_of_gameplay_plate() -> void:
	var level = add_node(load("res://scenes/level/test_level.tscn").instantiate()) # untyped: reads test_level.gd vars
	await tree.process_frame
	var visuals := 0
	for body: StaticBody3D in level.blocks:
		for child in body.get_children():
			if child is MeshInstance3D:
				visuals += 1
				var depth_half: float = (child.mesh as BoxMesh).size.z * 0.5
				assert_true(child.position.z - depth_half > 0.0, "platform visual fully in front of z = 0")
	assert_eq(visuals, TestLevelLayout.platforms().size(), "one visual per platform, none for walls")
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bash tools/run_tests.sh`
Expected: exit 1; `FAIL test_level_test.gd: script failed to load`.

- [ ] **Step 3: Implement `scripts/test_level_layout.gd`**

```gdscript
class_name TestLevelLayout
extends RefCounted
## Data for the M1 test level (metres, Y up, rect position = bottom-left). Platform tops step
## up at most 2.5 m, inside the ~3 m jump apex.

const SPAWN := Vector2(4.0, 2.5)
const LANTERN := Vector2(30.0, 5.5)
const FOREGROUND_DEPTH := -8.0
const FOREGROUND_PROP_SIZE := Vector2(1.2, 9.0)
const FOREGROUND_PROPS_X := [15.0, 37.0, 59.0, 81.0, 103.0, 125.0]


static func platforms() -> Array[Rect2]:
	return [
		Rect2(0.0, 0.0, WorldSpec.LEVEL_SIZE.x, 1.0), # floor
		Rect2(12.0, 3.0, 6.0, 0.5),
		Rect2(22.0, 5.5, 5.0, 0.5),
		Rect2(30.0, 3.5, 8.0, 0.5),
		Rect2(42.0, 6.0, 4.0, 0.5),
		Rect2(48.0, 8.5, 6.0, 0.5),
		Rect2(58.0, 4.0, 10.0, 0.5),
		Rect2(72.0, 3.0, 4.0, 0.5),
		Rect2(78.0, 5.5, 4.0, 0.5),
		Rect2(84.0, 8.0, 4.0, 0.5),
		Rect2(90.0, 10.5, 8.0, 0.5),
		Rect2(104.0, 6.0, 6.0, 0.5),
		Rect2(115.0, 3.5, 8.0, 0.5),
	]


static func walls() -> Array[Rect2]:
	var h := WorldSpec.LEVEL_SIZE.y + 10.0
	return [
		Rect2(-1.0, -1.0, 1.0, h),
		Rect2(WorldSpec.LEVEL_SIZE.x, -1.0, 1.0, h),
	]
```

- [ ] **Step 4: Implement `scripts/test_level.gd`**

```gdscript
extends Node3D
## M1 test level (spec §9): placeholder plates at the exact spec sizes, depth fog, DoF,
## one directional + one omni light, collision layout, player and camera rig — built in code.
## User args (after `--`): --autorun makes the player run right; --spawn-x=<metres> moves the spawn.

var layers: Array[PlateLayer] = []
var player: Player
var rig: CameraRig
var blocks: Array[StaticBody3D] = []

var _styles: Array[Dictionary] = [
	{"depth": 400.0, "top": Color("#5b7fbf"), "bottom": Color("#f3d3a8"), "fill_from": 0.0, "lit": false, "fog": false},
	{"depth": 100.0, "top": Color("#8d9cc4"), "bottom": Color("#6b7aa6"), "fill_from": 0.40, "lit": false, "fog": true},
	{"depth": 40.0, "top": Color("#6f8a9e"), "bottom": Color("#4e6878"), "fill_from": 0.50, "lit": false, "fog": true},
	{"depth": 10.0, "top": Color("#4f6b55"), "bottom": Color("#34493a"), "fill_from": 0.62, "lit": false, "fog": true},
	{"depth": 0.0, "top": Color("#7a5a3c"), "bottom": Color("#4a3423"), "fill_from": 0.80, "lit": true, "fog": true},
]
var _block_material := StandardMaterial3D.new()


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_block_material.albedo_color = Color("#3b2a20")
	_build_environment()
	_build_lights()
	for style in _styles:
		_build_plate_layer(style)
	_build_foreground()
	for rect in TestLevelLayout.platforms():
		_add_block(rect, true)
	for rect in TestLevelLayout.walls():
		_add_block(rect, false)
	player = Player.create()
	player.autorun = args.has("--autorun")
	player.position = Vector3(_spawn_x(args), TestLevelLayout.SPAWN.y, 0.0)
	add_child(player)
	rig = CameraRig.new()
	rig.target = player
	rig.level_size = WorldSpec.LEVEL_SIZE
	add_child(rig)
	rig.snap_to_target()


func _spawn_x(args: PackedStringArray) -> float:
	for arg in args:
		if arg.begins_with("--spawn-x="):
			return clampf(arg.get_slice("=", 1).to_float(), 2.0, WorldSpec.LEVEL_SIZE.x - 2.0)
	return TestLevelLayout.SPAWN.x


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#5b7fbf")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#9fb0d0")
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	env.fog_light_color = Color("#b8c4dc")
	env.fog_density = 0.004
	var attrs := CameraAttributesPractical.new()
	attrs.dof_blur_far_enabled = true
	attrs.dof_blur_far_distance = 40.0 # camera distance; near BG (30 m) stays sharp
	attrs.dof_blur_far_transition = 60.0
	attrs.dof_blur_near_enabled = true
	attrs.dof_blur_near_distance = 15.0 # foreground props at 12 m blur; gameplay at 20 m sharp
	attrs.dof_blur_near_transition = 3.0
	attrs.dof_blur_amount = 0.08
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	world_env.camera_attributes = attrs
	add_child(world_env)


func _build_lights() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35.0, -25.0, 0.0)
	sun.light_color = Color("#ffe2c0")
	add_child(sun)
	var lantern := OmniLight3D.new()
	lantern.position = Vector3(TestLevelLayout.LANTERN.x, TestLevelLayout.LANTERN.y, 1.5)
	lantern.omni_range = 7.0
	lantern.light_energy = 4.0
	lantern.light_color = Color("#ffb45e")
	add_child(lantern)


func _build_plate_layer(style: Dictionary) -> void:
	var depth: float = style.depth
	var size := WorldSpec.plate_size_px(depth)
	var px_per_m := WorldSpec.density(depth)
	var strips: Array[Texture2D] = []
	var x0 := 0
	for w in PlateLayer.strip_widths(size.x):
		var img := PlaceholderPlate.generate_strip(size, x0, w, px_per_m, style.top, style.bottom, style.fill_from)
		img.generate_mipmaps()
		strips.append(ImageTexture.create_from_image(img))
		x0 += w
	var layer := PlateLayer.new()
	layer.name = "Plate_%d" % int(depth)
	layer.build(depth, strips, style.lit, WorldSpec.LEVEL_SIZE, style.fog)
	add_child(layer)
	layers.append(layer)


func _build_foreground() -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.08, 0.07, 0.09)
	var quad := QuadMesh.new()
	quad.size = TestLevelLayout.FOREGROUND_PROP_SIZE
	for x: float in TestLevelLayout.FOREGROUND_PROPS_X:
		var prop := MeshInstance3D.new()
		prop.mesh = quad
		prop.material_override = mat
		prop.position = Vector3(x, TestLevelLayout.FOREGROUND_PROP_SIZE.y * 0.5 - 3.0, -TestLevelLayout.FOREGROUND_DEPTH)
		add_child(prop)


func _add_block(rect: Rect2, with_visual: bool) -> void:
	var body := StaticBody3D.new()
	var center := rect.get_center()
	body.position = Vector3(center.x, center.y, 0.0)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(rect.size.x, rect.size.y, 2.0)
	shape.shape = box
	body.add_child(shape)
	if with_visual:
		var visual := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(rect.size.x, rect.size.y, 0.6)
		visual.mesh = mesh
		visual.material_override = _block_material
		visual.position.z = WorldSpec.ACTOR_Z
		body.add_child(visual)
	add_child(body)
	blocks.append(body)
```

Note: a 0.6 m-deep box centred at z = 0.5 spans z 0.2–0.8, fully in front of the gameplay plate.

- [ ] **Step 5: Create `scenes/level/test_level.tscn` and set it as main scene**

`scenes/level/test_level.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/test_level.gd" id="1_level"]

[node name="TestLevel" type="Node3D"]
script = ExtResource("1_level")
```

In `project.godot`, under `[application]` after `config/name=...`, add:
```ini
run/main_scene="res://scenes/level/test_level.tscn"
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `bash tools/run_tests.sh`
Expected: exit 0, `35 passed, 0 failed`. (The two assembly tests generate ~64 M px of placeholder art; a few seconds each is normal.)

- [ ] **Step 7: Visual verification with Movie Maker captures (spec §9 success criteria)**

Captures go to the scratchpad, never into the project. Each command renders 90 frames and quits:
```bash
G=/c/GoDot/Godot_v4.7.2-stable_win64.exe
OUT="${TMPDIR:-/tmp}/m1_captures"; mkdir -p "$OUT"
"$G" --path . --resolution 1920x1080 --write-movie "$OUT/start169_.png" --fixed-fps 60 --quit-after 90 -- --autorun
"$G" --path . --resolution 1920x1080 --write-movie "$OUT/mid169_.png" --fixed-fps 60 --quit-after 90 -- --spawn-x=67 --autorun
"$G" --path . --resolution 2520x1080 --write-movie "$OUT/end219_.png" --fixed-fps 60 --quit-after 90 -- --spawn-x=134
"$G" --path . --resolution 2520x1080 --write-movie "$OUT/start219_.png" --fixed-fps 60 --quit-after 90 -- --spawn-x=0
ls "$OUT" | grep 00000089
```
Open each `*00000089.png` and check:
- Five distinct layers visible: sky gradient, far/mid/near silhouettes, brown gameplay ground band; dark blurred foreground posts in some frames.
- **No plate edge or bare background colour** at any screen edge in any capture (start/end at 21:9 are the hardest cases).
- Grid lines on nearer layers are visibly more widely spaced than on farther layers (depth-scaled density).
- Orange capsule and dark platforms are drawn in front of the ground band.
- Far layers look hazier and blurrier than near ones (fog + DoF).
- Comparing `start169_00000000.png` with `start169_00000089.png`: nearer layers moved further than farther ones (parallax).

Delete the `*.png` frames you do not need afterwards (they are ~6 MB each).

- [ ] **Step 8: Frame-rate check**

```bash
"$G" --path . --print-fps --quit-after 1200 -- --autorun 2>&1 | grep -i fps | tail -5
```
Expected: reported FPS ≥ 60 throughout (VSync caps it at the monitor refresh rate).

- [ ] **Step 9: Commit**

```bash
git add project.godot scripts/test_level_layout.gd* scripts/test_level.gd* scenes/ tests/test_level_test.gd*
git commit -m "feat: M1 test level with placeholder plates, fog, DoF, lights, player and camera

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

## Deferred (per spec §9 later milestones — not in this plan)

Plate importer plugin, BC7 import pipeline, real AI art, character art/animation, normal-mapped lit plates, per-level LUT colour grading, volumetric fog, player-follow fill light, camera shake/dolly/cinematic triggers, light cull masks, chunk streaming.
