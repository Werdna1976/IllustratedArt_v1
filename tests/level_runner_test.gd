extends TestCase
## Level runner chains sections, respawns the player, and completes the level.

const ROOT := "user://test_levels/"


func _section(name: String, data: Dictionary) -> String:
	var dir := ROOT + name + "/"
	DirAccess.make_dir_recursive_absolute(dir)
	FileAccess.open(dir + "section.json", FileAccess.WRITE).store_string(JSON.stringify(data))
	return dir


func _runner() -> LevelRunner:
	var a := _section("a", {"size_m": [40.0, 12.0], "collision": [[0, 0, 40, 1]], "spawn": [4.0, 2.5], "exit": [36, 1, 3, 6],
		"arenas": [{"rect": [15, 0, 20, 12], "enemies": [{"type": "officer", "x": 30.0}]}]})
	var b := _section("b", {"size_m": [40.0, 12.0], "collision": [[0, 0, 40, 1]], "spawn": [3.0, 2.5], "exit": [36, 1, 3, 6]})
	var runner := LevelRunner.new()
	runner.autostart = false
	runner.fade_time = 0.0
	runner.return_to_title = false
	add_node(runner)
	runner.start([a, b])
	return runner


func _frames(n: int) -> void:
	for i in n:
		await tree.physics_frame


func test_starts_first_section_at_spawn() -> void:
	var r := _runner()
	await _frames(3)
	assert_eq(r.index, 0, "first section")
	assert_near(r.player.global_position.x, 4.0, 0.1, "at spawn")


func test_exit_moves_to_next_section_and_last_exit_completes() -> void:
	var r := _runner()
	var done := [false]
	r.level_completed.connect(func() -> void: done[0] = true)
	await _frames(3)
	r.player.global_position = Vector3(37, 1.9, 0)
	await _frames(10)
	assert_eq(r.index, 1, "second section")
	assert_near(r.player.global_position.x, 3.0, 0.1, "at the second spawn")
	r.player.global_position = Vector3(37, 1.9, 0)
	await _frames(10)
	assert_true(done[0], "level completed")


func test_death_in_arena_resets_it() -> void:
	var r := _runner()
	await _frames(3)
	r.player.global_position = Vector3(20, 1.9, 0)
	await _frames(10)
	var arena: ArenaZone = r.section.arenas[0]
	assert_true(arena.active, "arena started")
	r.player.receive_hit({"outcome": HitResolver.Outcome.HIT, "damage": 1000.0, "stagger": 0.0, "knockback": Vector2.ZERO}, null)
	await tree.create_timer(1.2).timeout
	assert_true(not arena.active, "arena reset")
	assert_true(not r.rig.is_locked(), "camera unlocked")
	assert_near(r.player.vitals.hp, r.player.vitals.max_hp, 1e-6, "full health")
	assert_near(r.player.global_position.x, 4.0, 0.2, "back at spawn")
