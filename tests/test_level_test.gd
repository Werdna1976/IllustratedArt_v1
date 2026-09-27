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
