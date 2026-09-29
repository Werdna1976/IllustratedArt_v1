extends TestCase
## Rigs built from part data: structure, proportions, attachments.

const PLAYER := "res://scenes/characters/player_rig.tscn"


func _rel(rig: Node2D, node: Node2D) -> Vector2:
	return (rig.get_global_transform().affine_inverse() * node.get_global_transform()).origin


func test_player_rig_structure() -> void:
	var rig: Node2D = add_node(load(PLAYER).instantiate())
	for path in ["Pelvis/Torso/Head", "Pelvis/Torso/ArmUpperNear/ArmLowerNear/HandNear/Katana/Tip",
			"Pelvis/Torso/ArmUpperFar/ArmLowerFar/HandFar", "Pelvis/Torso/Saya", "Pelvis/ThighNear/ShinNear/FootNear",
			"CutoutIK", "AnimationPlayer"]:
		assert_true(rig.has_node(path), "has %s" % path)
	assert_true(rig.get_node("Pelvis/Torso/Head/Sprite") is PartSwap, "head swaps")
	assert_eq((rig.get_node("Pelvis/Torso/Head/Sprite") as PartSwap).variants.size(), 3, "three heads")


func test_proportions_match_the_approved_assembly() -> void:
	var rig: Node2D = add_node(load(PLAYER).instantiate())
	var head_top := _rel(rig, rig.get_node("Pelvis/Torso/Head")).y - 106.0
	assert_near(head_top, -720.0, 40.0, "about 720 px tall")
	var foot := _rel(rig, rig.get_node("Pelvis/ThighNear/ShinNear/FootNear"))
	assert_near(foot.y, -20.0, 12.0, "ankle just above the ground line")


func test_stretch_applies_to_sprite_not_children() -> void:
	var rig: Node2D = add_node(load(PLAYER).instantiate())
	var thigh: Node2D = rig.get_node("Pelvis/ThighNear")
	assert_near(thigh.scale.y, 1.0, 1e-6, "bone itself unscaled")
	assert_true((thigh.get_node("Sprite") as Node2D).scale.y > 1.2, "thigh sprite stretched to the approved length")
	assert_near((thigh.get_node("ShinNear/Sprite") as Node2D).global_scale.y / (thigh.get_node("ShinNear/Sprite") as Node2D).scale.y, 1.0, 1e-4, "shin inherits no stretch")


func test_missing_required_parts_are_listed_before_building() -> void:
	var skeleton: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/rigs/humanoid.json"))
	var rects := {"pelvis": [0, 0, 1, 1], "torso": [0, 0, 1, 1]}
	var missing := RigSpec.missing_parts(skeleton, rects)
	assert_true("arm_lower_far" in missing and "katana" in missing, "required parts reported")
	assert_true(not ("glint" in missing), "optional parts are not required")
	assert_true(not ("pelvis" in missing), "present parts are fine")


func test_head_draws_behind_the_collar() -> void:
	var rig: Node2D = add_node(load(PLAYER).instantiate())
	var head: Sprite2D = rig.get_node("Pelvis/Torso/Head/Sprite")
	var torso: Sprite2D = rig.get_node("Pelvis/Torso/Sprite")
	assert_true(head.z_index < torso.z_index, "the jacket collar overlaps the neck")


func test_width_override_combines_with_limb_stretch() -> void:
	var rig: Node2D = add_node(load(PLAYER).instantiate())
	var thigh: Node2D = rig.get_node("Pelvis/ThighNear/Sprite")
	var torso: Node2D = rig.get_node("Pelvis/Torso/Sprite")
	assert_true(torso.scale.x > 1.1, "torso widened (%.2f)" % torso.scale.x)
	assert_true(thigh.scale.x > 1.1 and thigh.scale.y > 1.2, "thigh widened and still stretched (%s)" % thigh.scale)
