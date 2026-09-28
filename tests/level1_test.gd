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
