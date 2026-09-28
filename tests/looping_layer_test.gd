extends TestCase
## Looping layers wrap seamlessly and always cover the view.


func _strips(total: int, h: int) -> Array[Texture2D]:
	var s: Array[Texture2D] = []
	for w in PlateLayer.strip_widths(total):
		s.append(ImageTexture.create_from_image(Image.create_empty(w, h, false, Image.FORMAT_RGBA8)))
	return s


func test_tile_width_and_depth() -> void:
	var layer := LoopingLayer.new()
	layer.setup(40.0, _strips(4096, 1280), false, true, Vector2(57.6, 12.0))
	assert_near(layer.tile_width, 4096.0 / WorldSpec.density(40.0), 1e-4, "tile width in metres")
	assert_near(layer.position.z, -40.0, 1e-6, "depth")
	layer.free()


func test_copies_cover_the_plate_span_at_any_offset() -> void:
	var section := Vector2(57.6, 12.0)
	var layer := LoopingLayer.new()
	layer.setup(10.0, _strips(4096, 1280), false, true, section)
	var need := WorldSpec.plate_rect(10.0, section)
	for offset: float in [0.0, 13.7, layer.tile_width * 0.999]:
		layer.offset = offset
		layer.layout()
		var left := INF
		var right := -INF
		for copy: Node3D in layer.copies:
			left = minf(left, copy.position.x)
			right = maxf(right, copy.position.x + layer.tile_width)
		assert_true(left <= need.position.x + 1e-4 and right >= need.end.x - 1e-4, "covered at offset %s" % offset)
	layer.free()


func test_scrolls_and_wraps() -> void:
	var layer := LoopingLayer.new()
	layer.setup(10.0, _strips(4096, 1280), false, true, Vector2(57.6, 12.0))
	layer.speed = 20.0
	layer.advance(1.0)
	assert_near(layer.offset, 20.0, 1e-4, "moves at speed")
	layer.advance(layer.tile_width / 20.0)
	assert_near(layer.offset, 20.0, 1e-3, "wrapped by one tile width")
	layer.free()


func test_placeholder_loops_are_seamless() -> void:
	var size := Vector2i(4096, 256)
	var ppm := WorldSpec.density(10.0)
	assert_eq(PlaceholderPlate.silhouette_top(0, size.y, ppm, 0.5, size.x),
			PlaceholderPlate.silhouette_top(size.x, size.y, ppm, 0.5, size.x), "silhouette repeats at the loop width")
