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
	for x: int in [5, 100, 250]:
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
	for y: int in [0, 60, 90, 127]:
		assert_color_near(right.get_pixel(3, y), whole.get_pixel(131, y), "column 131 row %d" % y)
