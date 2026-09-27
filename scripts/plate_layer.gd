class_name PlateLayer
extends Node3D
## One depth layer of painted plates: a row of quad strips covering WorldSpec.plate_rect,
## so the layer fills the view from every camera position. Sits at world Z = -depth.

var depth := 0.0


## strips: textures laid left to right, sharing one height, together
## WorldSpec.plate_size_px(depth, level_size).x wide.
func build(p_depth: float, strips: Array[Texture2D], lit: bool,
		level_size: Vector2 = WorldSpec.LEVEL_SIZE, fog: bool = true) -> void:
	depth = p_depth
	position = Vector3(0.0, 0.0, -depth)
	var rect := WorldSpec.plate_rect(depth, level_size)
	var px_per_m := WorldSpec.density(depth)
	var x := rect.position.x
	for tex in strips:
		var size_m := Vector2(tex.get_width(), tex.get_height()) / px_per_m
		var quad := QuadMesh.new()
		quad.size = size_m
		var mi := MeshInstance3D.new()
		mi.mesh = quad
		mi.material_override = make_material(tex, lit, fog)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = Vector3(x + size_m.x * 0.5, rect.position.y + size_m.y * 0.5, 0.0)
		add_child(mi)
		x += size_m.x


static func strip_widths(total_px: int) -> PackedInt32Array:
	var widths := PackedInt32Array()
	var left := total_px
	while left > 0:
		widths.append(mini(left, WorldSpec.STRIP_MAX_PX))
		left -= WorldSpec.STRIP_MAX_PX
	return widths


static func make_material(tex: Texture2D, lit: bool, fog: bool) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.alpha_scissor_threshold = 0.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL if lit else BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.disable_fog = not fog
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return mat
