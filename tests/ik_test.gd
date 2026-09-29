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

