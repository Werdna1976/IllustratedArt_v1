extends TestCase
## Officer brain flow, dummy feedback, finisher on a staggered enemy.


func _tick(b: OfficerBrain, seconds: float, dx: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in int(round(seconds * 120.0)):
		out.append(b.tick(1.0 / 120.0, dx, false))
	return out


func test_officer_ignores_far_player() -> void:
	var b := OfficerBrain.new()
	var outs := _tick(b, 0.5, 20.0)
	assert_eq(b.state, OfficerBrain.State.IDLE, "idle")
	assert_near(outs[-1].x, 0.0, 1e-6, "no movement")


func test_officer_approaches_then_telegraphs_then_attacks() -> void:
	var b := OfficerBrain.new()
	var outs := _tick(b, 0.1, 5.0)
	assert_eq(b.state, OfficerBrain.State.APPROACH, "approaching")
	assert_near(outs[-1].x, 1.0, 1e-6, "walks toward the player")
	outs = _tick(b, 0.05, 1.0)
	assert_eq(b.state, OfficerBrain.State.WINDUP, "winds up in range")
	assert_true(outs.any(func(o: Dictionary) -> bool: return o.windup), "telegraph emitted")
	outs = _tick(b, OfficerBrain.WINDUP, 1.0)
	assert_true(outs.any(func(o: Dictionary) -> bool: return o.attack), "attack after the wind-up")


func test_stunned_officer_does_nothing() -> void:
	var b := OfficerBrain.new()
	_tick(b, 0.1, 1.0)
	var out := b.tick(1.0 / 120.0, 1.0, true)
	assert_true(not out.attack and out.x == 0.0, "stunned: no action")


func test_dummy_shows_damage_numbers() -> void:
	var p := Player.create()
	var d := TrainingDummy.create_dummy()
	p.position = Vector3(0, 1.0, 0)
	d.position = Vector3(1.0, 1.0, 0)
	add_node(p)
	add_node(d)
	for i in 2:
		await tree.physics_frame
	p.combat.request(&"light")
	for i in 60:
		await tree.physics_frame
	assert_eq(d.last_numbers, [10.0] as Array[float], "one number for one hit")


func test_finisher_only_on_staggered_enemy() -> void:
	var p := Player.create()
	var e := Enemy.create_officer()
	p.position = Vector3(0, 1.0, 0)
	e.position = Vector3(1.2, 1.0, 0)
	add_node(p)
	add_node(e)
	e.brain = null # hold still
	await tree.physics_frame
	assert_eq(p.resolve_heavy_action(), &"heavy", "heavy when the enemy is not staggered")
	e.vitals.take(0.0, 1000.0)
	assert_eq(p.resolve_heavy_action(), &"finisher", "finisher on a staggered enemy in range")


func test_dead_enemy_is_untargetable() -> void:
	var p := Player.create()
	var e := Enemy.create_officer()
	add_node(p)
	add_node(e)
	await tree.physics_frame
	var died := [false]
	e.died.connect(func() -> void: died[0] = true)
	e.receive_hit({"outcome": HitResolver.Outcome.HIT, "damage": 1000.0, "stagger": 0.0, "knockback": Vector2.ZERO}, p)
	await tree.physics_frame
	assert_true(died[0], "died signal")
	assert_true(not e.is_in_group(&"enemies"), "left the enemies group")
	assert_true(not e.hurtbox.monitorable, "no longer hittable")
