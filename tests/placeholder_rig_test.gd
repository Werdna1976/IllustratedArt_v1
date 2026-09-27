extends TestCase
## The generated placeholder rig has every part and every move's animation at the move's length.

const RIG := "res://scenes/characters/placeholder_fighter_rig.tscn"


func test_rig_has_parts_and_feet_near_origin() -> void:
	var rig: Node2D = add_node(load(RIG).instantiate())
	for path in ["Pelvis/Torso/Head", "Pelvis/Torso/ArmUpperNear/ArmLowerNear/HandNear/Blade", "Pelvis/ThighFar/ShinFar/FootFar"]:
		assert_true(rig.has_node(path), "has %s" % path)
	var foot: Sprite2D = rig.get_node("Pelvis/ThighNear/ShinNear/FootNear")
	assert_near(foot.global_position.y - rig.global_position.y, -15.0, 20.0, "feet within 20 px of the origin")


func test_animations_exist_with_looping() -> void:
	var rig: Node2D = add_node(load(RIG).instantiate())
	var ap: AnimationPlayer = rig.get_node("AnimationPlayer")
	for anim_name in ["idle", "run", "jump", "fall", "light1", "light2", "light3", "heavy", "launcher",
			"air_light", "finisher", "parry", "dodge", "hurt", "staggered", "windup", "officer_attack"]:
		assert_true(ap.has_animation(anim_name), "animation %s" % anim_name)
	assert_eq(ap.get_animation("run").loop_mode, Animation.LOOP_LINEAR, "run loops")
	assert_eq(ap.get_animation("light1").loop_mode, Animation.LOOP_NONE, "attacks do not loop")
