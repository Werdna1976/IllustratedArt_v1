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
	var width_at_plane: float = tan(deg_to_rad(p.fov) * 0.5) * 2.0 * WorldSpec.CAMERA_DISTANCE
	assert_near(width_at_plane, 25.2, 1e-3, "32:9 shows exactly the 21:9 width")
	assert_near(WorldSpec.screen_size(32.0 / 9.0).y, 25.2 / (32.0 / 9.0), 1e-4, "32:9 crops height")
