extends TestCase
## The shared library: lengths match moves, and every slash is a diagonal front cut.

const PLAYER := "res://scenes/characters/player_rig.tscn"
const ATTACKS := [&"light1", &"light2", &"light3", &"heavy", &"launcher", &"air_light", &"finisher"]


func _tip(rig: Node2D) -> Vector2:
	return (rig.get_global_transform().affine_inverse() * rig.get_node("Pelvis/Torso/ArmUpperNear/ArmLowerNear/HandNear/Katana/Tip").get_global_transform()).origin


func test_lengths_match_move_data() -> void:
	var rig: Node2D = add_node(load(PLAYER).instantiate())
	var ap: AnimationPlayer = rig.get_node("AnimationPlayer")
	var moves: MoveSet = load("res://data/moves/player.tres")
	for m: MoveData in moves.moves:
		assert_near(ap.get_animation(m.anim).length, m.total(), 1e-3, "%s length" % m.id)


func test_slashes_are_diagonal_and_never_overhead() -> void:
	var rig: Node2D = add_node(load(PLAYER).instantiate())
	var ap: AnimationPlayer = rig.get_node("AnimationPlayer")
	var moves: MoveSet = load("res://data/moves/player.tres")
	for id in ATTACKS:
		var m := moves.get_move(id)
		ap.play(m.anim)
		ap.seek(m.startup, true)
		var a := _tip(rig)
		ap.seek(m.startup + m.active, true)
		var b := _tip(rig)
		var d := b - a
		assert_true(absf(d.y) > 150.0, "%s: tip travels vertically (%.0f px)" % [id, d.y])
		assert_true(absf(d.y) > 0.4 * absf(d.x), "%s: diagonal, not a flat sweep" % id)
		for i in 21:
			ap.seek(m.total() * i / 20.0, true)
			var tip := _tip(rig)
			assert_true(not (tip.x < -60.0 and tip.y < -620.0), "%s @%.2f: blade behind the head (overhead)" % [id, m.total() * i / 20.0])


func test_tracks_resolve_on_both_rigs() -> void:
	for path in [PLAYER, "res://scenes/characters/officer_rig.tscn"]:
		var rig: Node2D = add_node(load(path).instantiate())
		var ap: AnimationPlayer = rig.get_node("AnimationPlayer")
		for anim_name in ap.get_animation_list():
			var anim := ap.get_animation(anim_name)
			for t in anim.get_track_count():
				var np := anim.track_get_path(t)
				assert_true(rig.has_node(NodePath(np.get_concatenated_names())), "%s: %s resolves on %s" % [anim_name, np, path])


func test_hitboxes_do_not_reach_past_the_blade() -> void:
	var rig: Node2D = add_node(load(PLAYER).instantiate())
	var ap: AnimationPlayer = rig.get_node("AnimationPlayer")
	var moves: MoveSet = load("res://data/moves/player.tres")
	for id in ATTACKS:
		var m := moves.get_move(id)
		var reach := -INF
		ap.play(m.anim)
		for i in 11:
			ap.seek(m.startup + m.active * i / 10.0, true)
			reach = maxf(reach, _tip(rig).x / WorldSpec.CHAR_PX_PER_M)
		var far_edge := m.hitbox_offset.x + m.hitbox_size.x * 0.5
		assert_true(far_edge <= reach + 0.25, "%s: hitbox reaches %.2f m, blade only %.2f m" % [id, far_edge, reach])
