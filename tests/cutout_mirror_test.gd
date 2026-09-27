extends TestCase
## CutoutMirror copies 2D part transforms onto lit 3D quads at 400 px/m.

const PPM := 400.0


func _atlas() -> Texture2D:
	return ImageTexture.create_from_image(Image.create_empty(200, 100, false, Image.FORMAT_RGBA8))


func _rig() -> Array:
	var rig := Node2D.new()
	rig.visible = false
	var arm := Sprite2D.new()
	arm.region_enabled = true
	arm.region_rect = Rect2(50, 20, 100, 40)
	arm.centered = true
	arm.offset = Vector2(50, 0) # pivot at the arm's left end
	arm.position = Vector2(0, -400) # shoulder 1 m above the feet
	arm.z_index = 3
	rig.add_child(arm)
	return [rig, arm]


func test_one_quad_per_sprite_with_region_uvs() -> void:
	var r := _rig()
	var mirror := CutoutMirror.new()
	add_node(r[0])
	add_node(mirror)
	mirror.setup(r[0], _atlas(), null, null)
	assert_eq(mirror.quads.size(), 1, "one quad")
	var q: MeshInstance3D = mirror.quads[r[1]]
	assert_near((q.mesh as QuadMesh).size.x, 100.0 / PPM, 1e-6, "quad width in metres")
	var mat := q.material_override as StandardMaterial3D
	assert_near(mat.uv1_scale.x, 0.5, 1e-6, "uv scale x")
	assert_near(mat.uv1_offset.y, 0.2, 1e-6, "uv offset y")
	assert_eq(mat.cull_mode, BaseMaterial3D.CULL_DISABLED, "double-sided for facing flips")


func test_position_follows_pivot_and_flips_y() -> void:
	var r := _rig()
	var mirror := CutoutMirror.new()
	add_node(r[0])
	add_node(mirror)
	mirror.setup(r[0], _atlas(), null, null)
	var q: MeshInstance3D = mirror.quads[r[1]]
	# unrotated: quad centre is 50 px right of the shoulder, 400 px up
	assert_near(q.position.x, 50.0 / PPM, 1e-5, "x")
	assert_near(q.position.y, 400.0 / PPM, 1e-5, "y up")
	assert_near(q.position.z, 3 * CutoutMirror.Z_STEP, 1e-6, "z from z_index")


func test_rotation_swings_around_pivot() -> void:
	var r := _rig()
	var mirror := CutoutMirror.new()
	add_node(r[0])
	add_node(mirror)
	mirror.setup(r[0], _atlas(), null, null)
	(r[1] as Sprite2D).rotation = PI / 2 # 2D clockwise: arm now points down (+y)
	mirror.sync()
	var q: MeshInstance3D = mirror.quads[r[1]]
	assert_near(q.position.x, 0.0, 1e-5, "pivot stays put in x")
	assert_near(q.position.y, (400.0 - 50.0) / PPM, 1e-5, "centre hangs below the shoulder")


func test_hidden_part_hides_quad() -> void:
	var r := _rig()
	var mirror := CutoutMirror.new()
	add_node(r[0])
	add_node(mirror)
	mirror.setup(r[0], _atlas(), null, null)
	(r[1] as Sprite2D).visible = false
	mirror.sync()
	assert_true(not (mirror.quads[r[1]] as MeshInstance3D).visible, "quad hidden")
