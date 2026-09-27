class_name CutoutMirror
extends Node3D
## Mirrors a 2D cutout rig (Node2D hierarchy of Sprite2D parts, authored and animated in the
## 2D editor, never rendered) onto one lit quad per part in this node's plane (spec §5.6).
## Rig space: px, origin at the character's feet, +Y down; 3D: metres, +Y up.

const Z_STEP := 0.002 ## Metres of depth per z_index step, for part layering.

var quads := {} ## Sprite2D -> MeshInstance3D
var _rig: Node2D


func setup(rig: Node2D, albedo: Texture2D, normal: Texture2D, emissive: Texture2D) -> void:
	_rig = rig
	for sprite in _sprites(rig):
		var quad := MeshInstance3D.new()
		quad.mesh = QuadMesh.new()
		quad.material_override = _material(sprite, albedo, normal, emissive)
		quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(quad)
		quads[sprite] = quad
	sync()


func _process(_delta: float) -> void:
	if _rig:
		sync()


func sync() -> void:
	for sprite: Sprite2D in quads:
		var quad: MeshInstance3D = quads[sprite]
		var size := sprite.region_rect.size
		var top_left := sprite.offset - size * 0.5 if sprite.centered else sprite.offset
		var rel := _rig_transform(sprite)
		var c := rel * (top_left + size * 0.5)
		var s := rel.get_scale()
		(quad.mesh as QuadMesh).size = size / WorldSpec.CHAR_PX_PER_M
		quad.transform = Transform3D(
				Basis(Vector3.BACK, -rel.get_rotation()) * Basis.from_scale(Vector3(s.x, s.y, 1.0)),
				Vector3(c.x / WorldSpec.CHAR_PX_PER_M, -c.y / WorldSpec.CHAR_PX_PER_M, sprite.z_index * Z_STEP))
		quad.visible = _visible_in_rig(sprite)


# Sprite transform relative to the rig root, composed from local transforms (works outside the tree).
func _rig_transform(node: Node2D) -> Transform2D:
	var t := node.transform
	var parent := node.get_parent() as Node2D
	while parent and parent != _rig:
		t = parent.transform * t
		parent = parent.get_parent() as Node2D
	return t


# Visibility up to (not including) the rig root, which is always hidden.
func _visible_in_rig(node: CanvasItem) -> bool:
	while node and node != _rig:
		if not node.visible:
			return false
		node = node.get_parent() as CanvasItem
	return true


static func _sprites(node: Node) -> Array[Sprite2D]:
	var out: Array[Sprite2D] = []
	for child in node.get_children():
		if child is Sprite2D:
			out.append(child)
		out.append_array(_sprites(child))
	return out


static func _material(sprite: Sprite2D, albedo: Texture2D, normal: Texture2D, emissive: Texture2D) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	var tex_size := Vector2(albedo.get_size())
	var r := sprite.region_rect
	mat.albedo_texture = albedo
	mat.albedo_color = sprite.modulate
	mat.uv1_scale = Vector3(r.size.x / tex_size.x, r.size.y / tex_size.y, 1.0)
	mat.uv1_offset = Vector3(r.position.x / tex_size.x, r.position.y / tex_size.y, 0.0)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.alpha_scissor_threshold = 0.5
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	if normal:
		mat.normal_enabled = true
		mat.normal_texture = normal
	if emissive:
		mat.emission_enabled = true
		mat.emission = Color.WHITE
		mat.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY # glow = mask colour only
		mat.emission_texture = emissive
	return mat
