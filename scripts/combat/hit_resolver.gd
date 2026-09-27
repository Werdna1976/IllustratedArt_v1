class_name HitResolver
extends RefCounted
## Decides what a landed hitbox does (spec §5.7): evaded by an invulnerable dodge, parried only
## when the defender faces the attacker, otherwise a hit with knockback along the attacker's facing.

enum Outcome { HIT, PARRIED, EVADED }

const PARRY_STUN := 0.8 ## Seconds the attacker is stunned after being parried (applied by the caller).


static func resolve(move: MoveData, attacker_x: float, attacker_facing: float, defender_x: float,
		defender_facing: float, defender_parrying: bool, defender_invulnerable: bool) -> Dictionary:
	var result := {"outcome": Outcome.HIT, "damage": 0.0, "stagger": 0.0, "knockback": Vector2.ZERO}
	if defender_invulnerable:
		result.outcome = Outcome.EVADED
	elif defender_parrying and signf(attacker_x - defender_x) == defender_facing:
		result.outcome = Outcome.PARRIED
	else:
		result.damage = move.damage
		result.stagger = move.stagger
		result.knockback = Vector2(move.knockback.x * attacker_facing, move.knockback.y)
	return result
