extends TestCase
## Hit outcomes and HP/stagger bookkeeping.


func _move() -> MoveData:
	var m := MoveData.new()
	m.damage = 10.0
	m.stagger = 20.0
	m.knockback = Vector2(3, 1)
	return m


func test_plain_hit_signs_knockback_by_facing() -> void:
	var r := HitResolver.resolve(_move(), 0.0, -1.0, -1.0, 1.0, false, false)
	assert_eq(r.outcome, HitResolver.Outcome.HIT, "hit")
	assert_near(r.damage, 10.0, 1e-6, "damage")
	assert_near(r.knockback.x, -3.0, 1e-6, "pushed the way the attacker faces")


func test_parry_only_when_facing_attacker() -> void:
	# attacker at x=2 facing left; defender at x=0
	var facing := HitResolver.resolve(_move(), 2.0, -1.0, 0.0, 1.0, true, false)
	assert_eq(facing.outcome, HitResolver.Outcome.PARRIED, "parried when facing the attacker")
	var back := HitResolver.resolve(_move(), 2.0, -1.0, 0.0, -1.0, true, false)
	assert_eq(back.outcome, HitResolver.Outcome.HIT, "hit from behind lands through a parry")


func test_invulnerable_evades() -> void:
	var r := HitResolver.resolve(_move(), 0.0, 1.0, 1.0, -1.0, false, true)
	assert_eq(r.outcome, HitResolver.Outcome.EVADED, "dodged")


func test_stagger_fills_then_recovers() -> void:
	var v := Vitals.make(100.0, 30.0)
	v.take(5.0, 20.0)
	assert_true(not v.is_staggered(), "not yet")
	v.take(5.0, 20.0)
	assert_true(v.is_staggered(), "full meter staggers")
	assert_near(v.hp, 90.0, 1e-6, "hp")
	v.advance(Vitals.STAGGERED_TIME + 0.01)
	assert_true(not v.is_staggered(), "stagger ends")
	assert_near(v.stagger, 0.0, 1e-6, "meter reset")


func test_stagger_decays_after_delay() -> void:
	var v := Vitals.make(100.0, 50.0)
	v.take(0.0, 20.0)
	v.advance(1.0)
	assert_near(v.stagger, 20.0, 1e-6, "no decay inside the delay")
	v.advance(1.0) # 0.5 s past the delay
	assert_near(v.stagger, 10.0, 1e-6, "decays at 20/s")


func test_death() -> void:
	var v := Vitals.make(10.0, 10.0)
	v.take(15.0, 0.0)
	assert_true(v.is_dead(), "dead")
	assert_near(v.hp, 0.0, 1e-6, "hp clamps at 0")
