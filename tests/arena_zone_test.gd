extends TestCase
## Arenas lock the camera, spawn enemies behind barriers, and clear when the enemies die.


func _world() -> Array:
	var world := Node3D.new()
	add_node(world)
	LevelBuilder.block(world, Rect2(0, 0, 80, 1), null)
	var player := Player.create()
	player.position = Vector3(10, 1.9, 0)
	world.add_child(player)
	var rig := CameraRig.new()
	rig.target = player
	rig.level_size = Vector2(80, 16.2)
	world.add_child(rig)
	var arena := ArenaZone.new()
	arena.setup(Rect2(40, 0, 28.8, 16.2), [{"type": "officer", "x": 60.0}])
	world.add_child(arena)
	return [world, player, rig, arena]


func _kill(e: Enemy, by: Fighter) -> void:
	e.receive_hit({"outcome": HitResolver.Outcome.HIT, "damage": 1000.0, "stagger": 0.0, "knockback": Vector2.ZERO}, by)


func test_arena_locks_spawns_and_clears() -> void:
	var w := _world()
	var player: Player = w[1]
	var rig: CameraRig = w[2]
	var arena: ArenaZone = w[3]
	player.position.x = 45.0
	for i in 10:
		await tree.physics_frame
	assert_true(arena.active, "entered")
	assert_eq(rig.locked_rect(), Rect2(40, 0, 28.8, 16.2), "camera locked to the arena")
	assert_eq(arena.barriers.size(), 2, "walls up")
	assert_eq(arena.enemies.size(), 1, "officer spawned")
	_kill(arena.enemies[0], player)
	for i in 5:
		await tree.physics_frame
	assert_true(arena.is_cleared, "cleared as soon as the last enemy dies")
	assert_eq(arena.barriers.size(), 0, "walls down")
	assert_true(not rig.is_locked(), "camera unlocked")


func test_reset_after_player_death() -> void:
	var w := _world()
	var player: Player = w[1]
	var rig: CameraRig = w[2]
	var arena: ArenaZone = w[3]
	player.position.x = 45.0
	for i in 10:
		await tree.physics_frame
	arena.reset()
	await tree.process_frame
	assert_true(not arena.active and not arena.is_cleared, "ready to trigger again")
	assert_eq(arena.barriers.size(), 0, "walls removed")
	assert_true(not rig.is_locked(), "camera unlocked")


func test_barriers_are_visible_security_gates() -> void:
	var w := _world()
	var player: Player = w[1]
	var arena: ArenaZone = w[3]
	player.position.x = 45.0
	for i in 10:
		await tree.physics_frame
	for wall in arena.barriers:
		var gates := wall.find_children("*", "MeshInstance3D", false, false)
		assert_eq(gates.size(), 1, "each barrier shows a gate")
		var gate: MeshInstance3D = gates[0]
		assert_true(gate.visible and gate.position.z > 0.0, "gate drawn in front of the gameplay plate")
		assert_true((gate.material_override as StandardMaterial3D).emission_enabled, "gate glows")
