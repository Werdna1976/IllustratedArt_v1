extends TestCase
## Fighters hitting each other through Area3D hit/hurtboxes; hit-stop safety.


func _pair() -> Array:
	var a := Player.create()
	var b := Player.create()
	a.position = Vector3(0, 1.0, 0)
	b.position = Vector3(1.0, 1.0, 0)
	b.facing = -1.0
	add_node(a)
	add_node(b)
	return [a, b]


func _frames(n: int) -> void:
	for i in n:
		await tree.physics_frame


func test_light_attack_damages_target_once() -> void:
	var p := _pair()
	var a: Fighter = p[0]
	var b: Fighter = p[1]
	await _frames(2)
	a.combat.request(&"light")
	await _frames(60)
	assert_near(b.vitals.hp, 90.0, 1e-4, "exactly one light hit")


func test_one_hit_per_target_per_swing() -> void:
	var p := _pair()
	var a: Fighter = p[0]
	var b: Fighter = p[1]
	await _frames(2)
	a.combat.request(&"heavy") # 0.12 s active = ~14 physics frames overlapping
	await _frames(120)
	assert_near(b.vitals.hp, 75.0, 1e-4, "heavy lands once despite a long active window")


func test_parry_stuns_attacker_and_prevents_damage() -> void:
	var p := _pair()
	var a: Fighter = p[0]
	var b: Fighter = p[1]
	await _frames(2)
	b.combat.request(&"parry")
	a.combat.request(&"light")
	await _frames(30)
	assert_near(b.vitals.hp, 100.0, 1e-4, "no damage through a facing parry")
	assert_true(a.combat.is_stunned(), "attacker stunned")


func test_overlapping_hit_stops_restore_time_scale() -> void:
	HitStop.trigger(tree, 0.05)
	HitStop.trigger(tree, 0.10)
	await tree.create_timer(0.07, true, false, true).timeout
	assert_true(Engine.time_scale < 1.0, "still frozen by the longer stop")
	await tree.create_timer(0.08, true, false, true).timeout
	assert_near(Engine.time_scale, 1.0, 1e-6, "restored")
