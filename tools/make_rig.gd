extends SceneTree
## Builds a cutout rig scene from part data (M4a plan Task 5).
## usage: godot --headless --path . --script res://tools/make_rig.gd -- <char_dir> <out.tscn>
##   char_dir: res:// folder with parts.png, parts.json, pivots.json (pack_parts.py) and an
##             optional rig_overrides.json ({"lengths": {...}, "width": {family: x}, "sprite_scale": {part: [x, y]}}).
## Skeleton: res://data/rigs/humanoid.json. Each bone is a Node2D (animated) holding a "Sprite"
## PartSwap; limb stretch is applied to the sprite only, so children are never stretched.

const SKELETON := "res://data/rigs/humanoid.json"
const LIBRARY := "res://data/animations/humanoid.tres"
const IK_PATHS := {
	"upper_path": "../Pelvis/Torso/ArmUpperFar",
	"lower_path": "../Pelvis/Torso/ArmUpperFar/ArmLowerFar",
	"hand_path": "../Pelvis/Torso/ArmUpperFar/ArmLowerFar/HandFar",
	"near_hand_path": "../Pelvis/Torso/ArmUpperNear/ArmLowerNear/HandNear",
	"katana_path": "../Pelvis/Torso/ArmUpperNear/ArmLowerNear/HandNear/Katana",
	"target_path": "../Pelvis/Torso/ArmUpperNear/ArmLowerNear/HandNear/Katana/FarGrip",
}


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var err := build_and_save(args[0], args[1])
	quit(0 if err == OK else 1)


func build_and_save(char_dir: String, out: String) -> Error:
	var dir := char_dir if char_dir.ends_with("/") else char_dir + "/"
	var missing := RigSpec.missing_parts(_json(SKELETON), _json(dir + "parts.json"))
	if not missing.is_empty():
		printerr("cannot build %s: missing parts %s (re-run pack_parts.py with the full delivery)" % [out, ", ".join(missing)])
		return ERR_FILE_NOT_FOUND
	var rig := build(dir)
	var packed := PackedScene.new()
	packed.pack(rig)
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	var err := ResourceSaver.save(packed, out)
	print("saved %s (%s)" % [out, error_string(err)])
	rig.free()
	return err


func build(dir: String) -> Node2D:
	var skeleton: Dictionary = _json(SKELETON)
	var rects: Dictionary = _json(dir + "parts.json")
	var pivots: Dictionary = _json(dir + "pivots.json")
	var overrides: Dictionary = _json(dir + "rig_overrides.json") if FileAccess.file_exists(dir + "rig_overrides.json") else {}
	var lengths: Dictionary = skeleton.lengths.duplicate()
	lengths.merge(overrides.get("lengths", {}), true)
	var sprite_scales: Dictionary = overrides.get("sprite_scale", {})
	var widths: Dictionary = overrides.get("width", {})
	var tex: Texture2D = load(dir + "parts.png")
	var rig := Node2D.new()
	rig.name = dir.trim_suffix("/").get_file().capitalize().replace(" ", "") + "Rig"
	root.add_child(rig) # in the tree so global transforms are available for the ground lift
	var info := {} # bone name -> {pivot, distal, scale}
	for spec: Dictionary in skeleton.nodes:
		var has_art := rects.has(spec.part)
		if not has_art and not spec.get("optional", false):
			push_error("part %s missing from %sparts.json" % [spec.part, dir])
			continue
		var bone := Node2D.new()
		bone.name = spec.name
		var parent: Node2D = rig if spec.parent == "" else rig.find_child(spec.parent, true, false)
		parent.add_child(bone)
		bone.visible = not spec.get("hidden", false) # e.g. the glint, shown by animations
		if not has_art: # optional part this character lacks: keep the bone so animation tracks resolve
			var p0: Dictionary = info[spec.parent]
			bone.position = (_vec(spec.attach) - p0.pivot) * p0.scale
			info[spec.name] = {"pivot": Vector2.ZERO, "distal": Vector2.ZERO, "scale": Vector2.ONE}
			continue
		var pivot := _vec(pivots[spec.part].pivot)
		var distal: Variant = pivots[spec.part].distal
		var scale := Vector2.ONE
		var family: String = spec.part.trim_suffix("_near").trim_suffix("_far")
		if lengths.has(family) and distal != null:
			scale.y = lengths[family] / (_vec(distal).y - pivot.y)
		scale.x *= widths.get(family, 1.0)
		if sprite_scales.has(spec.part): # multiplies: never discards the limb stretch or width
			scale *= _vec(sprite_scales[spec.part])
		if spec.parent != "":
			var p: Dictionary = info[spec.parent]
			var at: Vector2 = p.distal if str(spec.get("attach")) == "distal" else _vec(spec.attach)
			bone.position = (at - p.pivot) * p.scale
		bone.rotation = deg_to_rad(spec.get("rotation", 0.0))
		bone.add_child(_sprite(spec, rects, pivots, tex, scale))
		for marker: String in spec.get("markers", {}):
			var m := Marker2D.new()
			m.name = marker
			m.position = _vec(spec.markers[marker])
			bone.add_child(m)
		info[spec.name] = {"pivot": pivot, "distal": _vec(distal) if distal != null else Vector2.ZERO, "scale": scale}
	_lift_to_ground(rig, rects, pivots, info)
	var ik := CutoutIK.new()
	ik.name = "CutoutIK"
	for key: String in IK_PATHS:
		ik.set(key, NodePath(IK_PATHS[key]))
	rig.add_child(ik)
	var player := AnimationPlayer.new()
	player.name = "AnimationPlayer"
	rig.add_child(player)
	if ResourceLoader.exists(LIBRARY):
		player.add_animation_library(&"", load(LIBRARY))
	rig.get_parent().remove_child(rig)
	_own(rig, rig)
	return rig


func _sprite(spec: Dictionary, rects: Dictionary, pivots: Dictionary, tex: Texture2D, scale: Vector2) -> PartSwap:
	var sprite := PartSwap.new()
	sprite.name = "Sprite"
	sprite.texture = tex
	sprite.region_enabled = true
	sprite.centered = true
	sprite.z_index = spec.z
	sprite.scale = scale
	var variants := {}
	var offsets := {}
	for part: String in spec.get("variants", [spec.part]):
		if not rects.has(part):
			continue
		var r: Array = rects[part]
		variants[StringName(part)] = Rect2(r[0], r[1], r[2], r[3])
		offsets[StringName(part)] = Vector2(r[2], r[3]) * 0.5 - _vec(pivots[part].pivot)
	sprite.variants = variants
	sprite.offsets = offsets
	sprite.variant = StringName(spec.part)
	return sprite


# Moves the pelvis so the lowest foot pixel sits on y = 0 (the character's feet).
func _lift_to_ground(rig: Node2D, rects: Dictionary, pivots: Dictionary, info: Dictionary) -> void:
	var lowest := -INF
	for foot in ["FootNear", "FootFar"]:
		var bone := rig.find_child(foot, true, false) as Node2D
		if bone:
			var part: String = "foot_near" if foot == "FootNear" else "foot_far"
			var below: float = (rects[part][3] - pivots[part].pivot[1]) * info[foot].scale.y
			lowest = maxf(lowest, (rig.get_global_transform().affine_inverse() * bone.get_global_transform()).origin.y + below)
	(rig.get_node("Pelvis") as Node2D).position.y -= lowest


func _own(node: Node, owner_node: Node) -> void:
	for child in node.get_children():
		child.owner = owner_node
		_own(child, owner_node)


func _json(path: String) -> Variant:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


static func _vec(a: Variant) -> Vector2:
	return Vector2(a[0], a[1])
