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


func test_resize_to_narrower_aspect_reclamps_immediately() -> void:
	var rig := _rig(Vector3(60, 1.9, 0), 32.0 / 9.0)
	rig.snap_to_target()
	assert_true(rig.position.y < 5.4, "precondition: 32:9 lets the camera sit low (y=%s)" % rig.position.y)
	rig.aspect_override = 16.0 / 9.0
	rig.apply_projection()
	assert_near(rig.position.y, 5.4, 1e-4, "re-clamped to 16:9 bottom limit without easing")


func test_shake_is_bounded_and_decays() -> void:
	var rig := _rig(Vector3(60, 8, 0), 16.0 / 9.0)
	rig.snap_to_target()
	rig.add_trauma(1.0)
	var max_offset := 0.0
	for i in 12:
		rig._physics_process(1.0 / 60.0)
		max_offset = maxf(max_offset, Vector2(rig.camera.position.x, rig.camera.position.y).length())
	assert_true(max_offset > 0.01, "shakes (max %.3f m)" % max_offset)
	assert_true(max_offset <= CameraRig.MAX_SHAKE + 1e-6, "stays within the plate margin")
	for i in 120:
		rig._physics_process(1.0 / 60.0)
	assert_near(rig.camera.position.x, 0.0, 1e-6, "settles back (x)")
	assert_near(rig.camera.position.y, 0.0, 1e-6, "settles back (y)")
