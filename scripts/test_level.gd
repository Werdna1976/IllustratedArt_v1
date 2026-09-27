extends Node3D
## M1 test level (spec §9): placeholder plates at the exact spec sizes, depth fog, DoF,
## one directional + one omni light, collision layout, player and camera rig — built in code.
## User args (after `--`): --autorun makes the player run right; --spawn-x=<metres> moves the spawn.

var layers: Array[PlateLayer] = []
var player: Player
var rig: CameraRig
var blocks: Array[StaticBody3D] = []

var _styles: Array[Dictionary] = [
	{"depth": 400.0, "top": Color("#5b7fbf"), "bottom": Color("#f3d3a8"), "fill_from": 0.0, "lit": false, "fog": false},
	{"depth": 100.0, "top": Color("#8d9cc4"), "bottom": Color("#6b7aa6"), "fill_from": 0.40, "lit": false, "fog": true},
	{"depth": 40.0, "top": Color("#6f8a9e"), "bottom": Color("#4e6878"), "fill_from": 0.50, "lit": false, "fog": true},
	{"depth": 10.0, "top": Color("#4f6b55"), "bottom": Color("#34493a"), "fill_from": 0.62, "lit": false, "fog": true},
	{"depth": 0.0, "top": Color("#7a5a3c"), "bottom": Color("#4a3423"), "fill_from": 0.80, "lit": true, "fog": true},
]
var _block_material := StandardMaterial3D.new()


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_block_material.albedo_color = Color("#3b2a20")
	_build_environment()
	_build_lights()
	for style in _styles:
		_build_plate_layer(style)
	_build_foreground()
	for rect in TestLevelLayout.platforms():
		_add_block(rect, true)
	for rect in TestLevelLayout.walls():
		_add_block(rect, false)
	player = Player.create()
	player.autorun = args.has("--autorun")
	player.position = Vector3(_spawn_x(args), TestLevelLayout.SPAWN.y, 0.0)
	add_child(player)
	rig = CameraRig.new()
	rig.target = player
	rig.level_size = WorldSpec.LEVEL_SIZE
	add_child(rig)
	rig.snap_to_target()


func _spawn_x(args: PackedStringArray) -> float:
	for arg in args:
		if arg.begins_with("--spawn-x="):
			return clampf(arg.get_slice("=", 1).to_float(), 2.0, WorldSpec.LEVEL_SIZE.x - 2.0)
	return TestLevelLayout.SPAWN.x


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#5b7fbf")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#9fb0d0")
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	env.fog_light_color = Color("#b8c4dc")
	env.fog_density = 0.004
	var attrs := CameraAttributesPractical.new()
	attrs.dof_blur_far_enabled = true
	attrs.dof_blur_far_distance = 40.0 # camera distance; near BG (30 m) stays sharp
	attrs.dof_blur_far_transition = 60.0
	attrs.dof_blur_near_enabled = true
	attrs.dof_blur_near_distance = 15.0 # foreground props at 12 m blur; gameplay at 20 m sharp
	attrs.dof_blur_near_transition = 3.0
	attrs.dof_blur_amount = 0.08
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	world_env.camera_attributes = attrs
	add_child(world_env)


func _build_lights() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35.0, -25.0, 0.0)
	sun.light_color = Color("#ffe2c0")
	add_child(sun)
	var lantern := OmniLight3D.new()
	lantern.position = Vector3(TestLevelLayout.LANTERN.x, TestLevelLayout.LANTERN.y, 1.5)
	lantern.omni_range = 7.0
	lantern.light_energy = 4.0
	lantern.light_color = Color("#ffb45e")
	add_child(lantern)


func _build_plate_layer(style: Dictionary) -> void:
	var depth: float = style.depth
	var size := WorldSpec.plate_size_px(depth)
	var px_per_m := WorldSpec.density(depth)
	var strips: Array[Texture2D] = []
	var x0 := 0
	for w in PlateLayer.strip_widths(size.x):
		var img := PlaceholderPlate.generate_strip(size, x0, w, px_per_m, style.top, style.bottom, style.fill_from)
		img.generate_mipmaps()
		strips.append(ImageTexture.create_from_image(img))
		x0 += w
	var layer := PlateLayer.new()
	layer.name = "Plate_%d" % int(depth)
	layer.build(depth, strips, style.lit, WorldSpec.LEVEL_SIZE, style.fog)
	add_child(layer)
	layers.append(layer)


func _build_foreground() -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.08, 0.07, 0.09)
	var quad := QuadMesh.new()
	quad.size = TestLevelLayout.FOREGROUND_PROP_SIZE
	for x: float in TestLevelLayout.FOREGROUND_PROPS_X:
		var prop := MeshInstance3D.new()
		prop.mesh = quad
		prop.material_override = mat
		prop.position = Vector3(x, TestLevelLayout.FOREGROUND_PROP_SIZE.y * 0.5 - 3.0, -TestLevelLayout.FOREGROUND_DEPTH)
		add_child(prop)


func _add_block(rect: Rect2, with_visual: bool) -> void:
	var body := StaticBody3D.new()
	var center := rect.get_center()
	body.position = Vector3(center.x, center.y, 0.0)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(rect.size.x, rect.size.y, 2.0)
	shape.shape = box
	body.add_child(shape)
	if with_visual:
		var visual := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(rect.size.x, rect.size.y, 0.6)
		visual.mesh = mesh
		visual.material_override = _block_material
		visual.position.z = WorldSpec.ACTOR_Z
		body.add_child(visual)
	add_child(body)
	blocks.append(body)
