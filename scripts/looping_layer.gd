class_name LoopingLayer
extends Node3D
## A horizontally seamless plate that scrolls and wraps (spec §4.1): the world moves past a
## stationary vehicle. All loop layers scroll at the same world speed; perspective supplies the
## parallax. Copies of the tile are laid side by side to cover WorldSpec.plate_rect at any offset.

var depth := 0.0
var tile_width := 0.0 ## Metres.
var offset := 0.0 ## Metres, in [0, tile_width).
var speed := 0.0 ## World scroll speed, m/s.
var copies: Array[Node3D] = []

var _span := Rect2()


func setup(p_depth: float, strips: Array[Texture2D], lit: bool, fog: bool, section_size: Vector2,
		normals: Array[Texture2D] = [], emissives: Array[Texture2D] = []) -> void:
	depth = p_depth
	position = Vector3(0.0, 0.0, -depth)
	_span = WorldSpec.plate_rect(depth, section_size)
	var px_per_m := WorldSpec.density(depth)
	tile_width = 0.0
	for tex in strips:
		tile_width += tex.get_width() / px_per_m
	var count := int(ceil(_span.size.x / tile_width)) + 1
	for c in count:
		var copy := Node3D.new()
		var x := 0.0
		for i in strips.size():
			var size_m := Vector2(strips[i].get_width(), strips[i].get_height()) / px_per_m
			var quad := QuadMesh.new()
			quad.size = size_m
			var mi := MeshInstance3D.new()
			mi.mesh = quad
			mi.material_override = PlateLayer.make_material(strips[i], lit, fog,
					normals[i] if i < normals.size() else null, emissives[i] if i < emissives.size() else null)
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mi.position = Vector3(x + size_m.x * 0.5, _span.position.y + size_m.y * 0.5, 0.0)
			copy.add_child(mi)
			x += size_m.x
		add_child(copy)
		copies.append(copy)
	layout()


func _process(delta: float) -> void:
	advance(delta)


func advance(dt: float) -> void:
	offset = fposmod(offset + speed * dt, tile_width)
	layout()


func layout() -> void:
	for i in copies.size():
		copies[i].position.x = _span.position.x - offset + i * tile_width


func set_glow(energy: float) -> void:
	for copy in copies:
		for mi: MeshInstance3D in copy.get_children():
			(mi.material_override as StandardMaterial3D).emission_energy_multiplier = energy
