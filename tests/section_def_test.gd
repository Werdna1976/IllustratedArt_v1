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
	assert_eq(def.collision.size(), 2, "art collision (composed + traced) replaces the greybox rect")
	var r: Rect2 = def.collision[0]
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


func test_greybox_collision_kept_without_art_collision_or_when_asked() -> void:
	var plain := SectionDef.load_dir(_write_section("grey", {"size_m": [40.0, 12.0], "collision": [[0, 0, 40, 1]]}))
	assert_eq(plain.collision, [Rect2(0, 0, 40, 1)] as Array[Rect2], "greybox used when there is no art collision")
	var keep := SectionDef.load_dir(_write_section("keep", {"size_m": [40.0, 12.0], "collision": [[0, 0, 40, 1]],
			"keep_greybox_collision": true}, {"gameplay_collision.json": "[[0, 0, 100, 100]]"}))
	assert_eq(keep.collision.size(), 2, "opt-in keeps both")
