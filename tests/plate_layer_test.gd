extends TestCase
## PlateLayer lays strips edge to edge over WorldSpec.plate_rect at the right depth.


func _blank_strips(depth: float) -> Array[Texture2D]:
	var size := WorldSpec.plate_size_px(depth)
	var strips: Array[Texture2D] = []
	for w in PlateLayer.strip_widths(size.x):
		strips.append(ImageTexture.create_from_image(Image.create_empty(w, size.y, false, Image.FORMAT_RGBA8)))
	return strips


func test_strip_widths_split_at_max() -> void:
	assert_eq(PlateLayer.strip_widths(2048), PackedInt32Array([2048]), "exact")
	assert_eq(PlateLayer.strip_widths(3392), PackedInt32Array([2048, 1344]), "sky")
	var w := PlateLayer.strip_widths(14784)
	assert_eq(w.size(), 8, "gameplay strip count")
	assert_eq(w[7], 448, "gameplay last strip")


func test_build_places_strips_edge_to_edge_over_plate_rect() -> void:
	var depth := 40.0
	var strips := _blank_strips(depth)
	var layer := PlateLayer.new()
	layer.build(depth, strips, false)
	var rect := WorldSpec.plate_rect(depth)
	assert_eq(layer.get_child_count(), strips.size(), "one quad per strip")
	assert_near(layer.position.z, -depth, 1e-6, "layer z")
	var prev_right := rect.position.x
	for mi: MeshInstance3D in layer.get_children():
		var half: Vector2 = (mi.mesh as QuadMesh).size * 0.5
		assert_near(mi.position.x - half.x, prev_right, 1e-3, "strip starts where previous ended")
		assert_near(mi.position.y - half.y, rect.position.y, 1e-4, "strip bottom")
		assert_near(mi.position.y + half.y, rect.end.y, 1e-4, "strip top")
		prev_right = mi.position.x + half.x
	assert_near(prev_right, rect.end.x, 1e-3, "last strip ends at plate right edge")
	layer.free()


func test_material_flags() -> void:
	var tex := ImageTexture.create_from_image(Image.create_empty(4, 4, false, Image.FORMAT_RGBA8))
	var unlit := PlateLayer.make_material(tex, false, true)
	assert_eq(unlit.shading_mode, BaseMaterial3D.SHADING_MODE_UNSHADED, "unshaded by default")
	assert_eq(unlit.transparency, BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR, "alpha scissor")
	assert_eq(unlit.disable_fog, false, "fogged")
	var lit_nofog := PlateLayer.make_material(tex, true, false)
	assert_eq(lit_nofog.shading_mode, BaseMaterial3D.SHADING_MODE_PER_PIXEL, "lit")
	assert_eq(lit_nofog.disable_fog, true, "fog disabled (sky)")


func test_companion_maps_on_plate_materials() -> void:
	var tex := ImageTexture.create_from_image(Image.create_empty(4, 4, false, Image.FORMAT_RGBA8))
	var mat := PlateLayer.make_material(tex, true, true, tex, tex)
	assert_true(mat.normal_enabled and mat.normal_texture == tex, "normal map")
	assert_true(mat.emission_enabled and mat.emission_texture == tex, "glow map")
	assert_eq(mat.emission_operator, BaseMaterial3D.EMISSION_OP_MULTIPLY, "glow comes from the mask only")


func test_set_glow_scales_every_strip() -> void:
	var depth := 100.0
	var strips := _blank_strips(depth)
	var layer := PlateLayer.new()
	layer.build(depth, strips, false, WorldSpec.LEVEL_SIZE, true, [], strips)
	layer.set_glow(0.4)
	for mi: MeshInstance3D in layer.get_children():
		assert_near((mi.material_override as StandardMaterial3D).emission_energy_multiplier, 0.4, 1e-6, "glow energy")
	layer.free()
