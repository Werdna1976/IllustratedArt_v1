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
