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
