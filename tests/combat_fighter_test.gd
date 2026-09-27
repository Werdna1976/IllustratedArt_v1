extends TestCase
## Pure combat state machine: combos, buffering, cancels, invulnerability, parry window, stun.


func _fighter() -> CombatFighter:
	var f := CombatFighter.new()
	f.moves = load("res://data/moves/player.tres")
	return f


func _run(f: CombatFighter, seconds: float) -> Array[StringName]:
	var events: Array[StringName] = []
	var steps := int(round(seconds * 120.0))
	for i in steps:
		events.append_array(f.advance(1.0 / 120.0))
	return events


func test_light_starts_combo_and_emits_phase_events() -> void:
	var f := _fighter()
	assert_true(f.request(&"light"), "starts")
	assert_eq(f.current.id, &"light1", "light resolves to light1")
	var events := _run(f, 0.34)
	assert_true(events.has(&"active_start") and events.has(&"active_end") and events.has(&"done"), "phase events: %s" % [events])
	assert_true(f.current == null, "free after the move")


func test_combo_chains_through_three_hits() -> void:
	var f := _fighter()
	f.request(&"light")
	_run(f, 0.15)
	assert_true(f.request(&"light"), "chain into light2 after cancel time")
	assert_eq(f.current.id, &"light2", "light2")
	_run(f, 0.15)
	f.request(&"light")
	assert_eq(f.current.id, &"light3", "light3")


func test_mashing_buffers_one_follow_up_only() -> void:
	var f := _fighter()
	f.request(&"light")
	for i in 5:
		f.request(&"light") # mashed during startup
	assert_eq(f.current.id, &"light1", "no restart mid-swing")
	_run(f, 0.15) # passes light1's cancel time (0.14)
	assert_eq(f.current.id, &"light2", "buffered follow-up fired once")
	_run(f, 0.12) # before light2's cancel time: nothing else was buffered
	assert_eq(f.current.id, &"light2", "mash did not queue light3")


func test_dodge_cancels_recovery_and_is_invulnerable() -> void:
	var f := _fighter()
	f.request(&"heavy")
	assert_true(not f.request(&"dodge"), "cannot dodge out of startup")
	_run(f, 0.45) # into heavy recovery
	assert_true(f.request(&"dodge"), "dodge cancels recovery")
	_run(f, 0.05)
	assert_true(f.is_invulnerable(), "invulnerable during dodge active")
	_run(f, 0.25)
	assert_true(not f.is_invulnerable(), "vulnerable after")


func test_parry_window() -> void:
	var f := _fighter()
	f.request(&"parry")
	assert_true(not f.is_parrying(), "not before startup ends")
	_run(f, 0.05)
	assert_true(f.is_parrying(), "parry window open")
	_run(f, 0.15)
	assert_true(not f.is_parrying(), "window closed")


func test_air_light_only_in_air() -> void:
	var f := _fighter()
	f.request(&"light", true)
	assert_eq(f.current.id, &"air_light", "light in the air becomes air_light")


func test_stun_cancels_and_blocks_input() -> void:
	var f := _fighter()
	f.request(&"heavy")
	f.stun(0.3)
	assert_true(f.current == null, "move cancelled")
	assert_true(not f.request(&"light"), "stunned")
	_run(f, 0.31)
	assert_true(f.request(&"light"), "free after stun")


func test_cancel_ends_previous_active_window_first() -> void:
	var f := _fighter()
	f.request(&"light")
	f.request(&"light") # buffered; fires at light1's cancel time (0.14), inside its active window (0.08-0.16)
	var events := _run(f, 0.15)
	var end_i := events.rfind(&"active_end")
	var start_i := events.find(&"started:light2")
	assert_true(start_i > 0 and end_i >= 0 and end_i < start_i, "light1's window closes before light2 starts: %s" % [events])


func test_dodge_cannot_cancel_its_own_recovery() -> void:
	var f := _fighter()
	f.request(&"dodge")
	_run(f, 0.3) # dodge recovery (0.25-0.37)
	assert_true(not f.request(&"dodge"), "no dodge chaining for permanent invulnerability")
