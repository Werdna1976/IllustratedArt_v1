class_name LevelBuilder
extends RefCounted
## Shared code for code-built levels: environment (fog, DoF, glow), lights, placeholder plate
## layers sized for any section, and collision blocks with visuals in front of the gameplay plate.


static func default_styles() -> Array[Dictionary]:
	return [
		{"depth": 400.0, "top": Color("#5b7fbf"), "bottom": Color("#f3d3a8"), "fill_from": 0.0, "lit": false, "fog": false},
		{"depth": 100.0, "top": Color("#8d9cc4"), "bottom": Color("#6b7aa6"), "fill_from": 0.40, "lit": false, "fog": true},
		{"depth": 40.0, "top": Color("#6f8a9e"), "bottom": Color("#4e6878"), "fill_from": 0.50, "lit": false, "fog": true},
		{"depth": 10.0, "top": Color("#4f6b55"), "bottom": Color("#34493a"), "fill_from": 0.62, "lit": false, "fog": true},
		{"depth": 0.0, "top": Color("#7a5a3c"), "bottom": Color("#4a3423"), "fill_from": 0.80, "lit": true, "fog": true},
	]


## overrides: section.json "env" keys (background, fog, fog_density, ambient, ambient_energy).
static func environment(parent: Node, overrides: Dictionary = {}) -> Environment:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(overrides.get("background", "#5b7fbf"))
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(overrides.get("ambient", "#9fb0d0"))
	env.ambient_light_energy = overrides.get("ambient_energy", 0.6)
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	env.fog_light_color = Color(overrides.get("fog", "#b8c4dc"))
	env.fog_density = overrides.get("fog_density", 0.004)
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
	parent.add_child(world_env)
	return env


static func sun(parent: Node, color: Color = Color("#ffe2c0"), energy: float = 1.0) -> DirectionalLight3D:
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35.0, -25.0, 0.0)
	light.light_color = color
	light.light_energy = energy
	parent.add_child(light)
	return light


static func lights(parent: Node, lantern: Vector2) -> void:
	sun(parent)
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(lantern.x, lantern.y, 1.5)
	lamp.omni_range = 7.0
	lamp.light_energy = 4.0
	lamp.light_color = Color("#ffb45e")
	parent.add_child(lamp)


static func plate_layer(parent: Node, style: Dictionary, level_size: Vector2) -> PlateLayer:
	var depth: float = style.depth
	var size := WorldSpec.plate_size_px(depth, level_size)
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
	layer.build(depth, strips, style.lit, level_size, style.fog)
	parent.add_child(layer)
	return layer


static func block(parent: Node, rect: Rect2, material: Material) -> StaticBody3D:
	var body := StaticBody3D.new()
	var center := rect.get_center()
	body.position = Vector3(center.x, center.y, 0.0)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(rect.size.x, rect.size.y, 2.0)
	shape.shape = box
	body.add_child(shape)
	if material:
		var visual := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(rect.size.x, rect.size.y, 0.6)
		visual.mesh = mesh
		visual.material_override = material
		visual.position.z = WorldSpec.ACTOR_Z # 0.6 m deep box spans z 0.2–0.8, in front of the plate
		body.add_child(visual)
	parent.add_child(body)
	return body


static func walls(level_size: Vector2) -> Array[Rect2]:
	var h := level_size.y + 10.0
	return [Rect2(-1.0, -1.0, 1.0, h), Rect2(level_size.x, -1.0, 1.0, h)]
