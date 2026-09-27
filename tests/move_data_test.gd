extends TestCase
## Move timing phases and the generated move sets.


func _move() -> MoveData:
	var m := MoveData.new()
	m.startup = 0.1
	m.active = 0.2
	m.recovery = 0.3
	m.cancel_from = -1.0
	return m


func test_phases() -> void:
	var m := _move()
	assert_near(m.total(), 0.6, 1e-6, "total")
	assert_eq(m.phase_at(0.05), MoveData.Phase.STARTUP, "startup")
	assert_eq(m.phase_at(0.1), MoveData.Phase.ACTIVE, "active starts exactly at startup end")
	assert_eq(m.phase_at(0.35), MoveData.Phase.RECOVERY, "recovery")
	assert_eq(m.phase_at(0.6), MoveData.Phase.DONE, "done at total")


func test_cancel_time_defaults_to_end_of_active() -> void:
	var m := _move()
	assert_near(m.cancel_time(), 0.3, 1e-6, "default cancel")
	m.cancel_from = 0.15
	assert_near(m.cancel_time(), 0.15, 1e-6, "explicit cancel")


func test_player_move_set_matches_rig_animations() -> void:
	var set: MoveSet = load("res://data/moves/player.tres")
	var rig: Node2D = add_node(load("res://scenes/characters/placeholder_fighter_rig.tscn").instantiate())
	var ap: AnimationPlayer = rig.get_node("AnimationPlayer")
	for id in [&"light1", &"light2", &"light3", &"heavy", &"launcher", &"air_light", &"finisher", &"parry", &"dodge"]:
		var m := set.get_move(id)
		assert_true(m != null, "move %s" % id)
		assert_near(ap.get_animation(m.anim).length, m.total(), 1e-3, "%s animation length = move total" % id)
	assert_eq(set.get_move(&"light1").next_combo, &"light2", "combo chain")
	assert_true(set.get_move(&"nope") == null, "missing move is null")
