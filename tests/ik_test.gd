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
			var to_rig := rig.get_global_transform().affine_inverse()
			# the far fist sits on the grip the way the near fist sits on the katana pivot
			var fist_offset := (to_rig * ik.katana.get_global_transform()).origin - (to_rig * ik.near_hand.get_global_transform()).origin
			var far_fist := (to_rig * ik.hand.get_global_transform()).origin + fist_offset
			var grip_pos := (to_rig * ik.target.get_global_transform()).origin
			assert_true(far_fist.distance_to(grip_pos) < 6.0, "%s @%.1f: far fist %.1f px from the grip" % [anim_name, t, far_fist.distance_to(grip_pos)])
