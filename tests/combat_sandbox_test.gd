extends TestCase
## Sandbox builds with a player, a dummy and an officer inside the arena.


func test_sandbox_contents() -> void:
	var s = add_node(load("res://scenes/level/combat_sandbox.tscn").instantiate()) # untyped: script vars
	await tree.process_frame
	assert_true(s.player is Player, "player")
	assert_true(s.dummy is TrainingDummy, "dummy")
	assert_true(s.officer is Enemy, "officer")
	assert_true(s.officer.is_network, "officer is network-controlled (blade light)")
	assert_true(s.rig.camera.current, "camera")
