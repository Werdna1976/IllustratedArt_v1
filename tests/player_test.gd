extends TestCase
## Movement maths, input registration and the Player node on a floor.


func test_actions_registered_once() -> void:
	GameInput.ensure_actions()
	GameInput.ensure_actions()
	for action: StringName in [&"move_left", &"move_right", &"jump"]:
		assert_true(InputMap.has_action(action), "action %s exists" % action)
	assert_eq(InputMap.action_get_events(&"jump").size(), 4, "jump bindings not duplicated")
	assert_eq(InputMap.action_get_events(&"move_left").size(), 3, "move_left bindings")
	for action: StringName in [&"light_attack", &"heavy_attack", &"launcher", &"parry", &"dodge"]:
		assert_true(InputMap.has_action(action), "combat action %s exists" % action)


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
	var v := PlayerMotor.step(Vector3.ZERO, 0.0, false, false, 1.0)
	assert_near(v.y, -PlayerMotor.MAX_FALL_SPEED, 1e-4, "hitch frame capped")


func test_z_velocity_always_zero() -> void:
	var v := PlayerMotor.step(Vector3(1, 1, 5), 1.0, false, false, 0.016)
	assert_eq(v.z, 0.0, "z zeroed")


func test_visual_sits_in_front_of_gameplay_plate() -> void:
	var p := Player.create()
	add_node(p)
	assert_true(p.visual.position.z >= WorldSpec.ACTOR_Z - 1e-6, "cutout visual at ACTOR_Z")
	assert_eq(p.mirror.quads.size(), 17, "all 17 cutout parts mirrored")
	for q: MeshInstance3D in p.mirror.quads.values():
		assert_true(p.visual.position.z + q.position.z > 0.0, "every part in front of z = 0")
	assert_true(p.axis_lock_linear_z, "z locked")


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
