class_name Vitals
extends RefCounted
## HP and stagger meter (spec §5.7). A full stagger meter staggers for STAGGERED_TIME (opening
## a finisher), then resets. Stagger drains after STAGGER_DECAY_DELAY without being hit.

const STAGGER_DECAY_DELAY := 1.5
const STAGGER_DECAY := 20.0 ## Per second.
const STAGGERED_TIME := 2.5

var max_hp := 100.0
var hp := 100.0
var max_stagger := 100.0
var stagger := 0.0

var _since_hit := 0.0
var _staggered_left := 0.0


static func make(p_hp: float, p_stagger: float) -> Vitals:
	var v := Vitals.new()
	v.max_hp = p_hp
	v.hp = p_hp
	v.max_stagger = p_stagger
	return v


func take(damage: float, stagger_dmg: float) -> void:
	hp = maxf(hp - damage, 0.0)
	_since_hit = 0.0
	if is_staggered():
		return
	stagger = minf(stagger + stagger_dmg, max_stagger)
	if stagger >= max_stagger:
		_staggered_left = STAGGERED_TIME


func advance(dt: float) -> void:
	if is_staggered():
		_staggered_left -= dt
		if not is_staggered():
			stagger = 0.0
		return
	var before := _since_hit
	_since_hit += dt
	var decay_time := _since_hit - maxf(before, STAGGER_DECAY_DELAY)
	if decay_time > 0.0:
		stagger = maxf(stagger - STAGGER_DECAY * decay_time, 0.0)


func is_dead() -> bool:
	return hp <= 0.0


func is_staggered() -> bool:
	return _staggered_left > 0.0
