class_name OfficerBrain
extends RefCounted
## Security officer decisions (pure): notice the player, walk into range, telegraph with a
## wind-up, attack, recover, repeat after a cooldown. The caller reports attack_finished().

enum State { IDLE, APPROACH, WINDUP, ATTACK, RECOVER }

const SIGHT := 12.0
const ATTACK_RANGE := 1.6
const SPEED := 3.5 ## Walk speed, m/s (Enemy scales its input by SPEED / RUN_SPEED).
const WINDUP := 0.45
const RECOVER := 0.6
const COOLDOWN := 1.2
const EPS := 1e-6

var state := State.IDLE
var _timer := 0.0
var _cooldown := 0.0


## dx = player x - officer x. Returns {x, face, windup, attack}.
func tick(dt: float, dx: float, stunned: bool) -> Dictionary:
	var out := {"x": 0.0, "face": signf(dx) if dx != 0.0 else 1.0, "windup": false, "attack": false}
	_cooldown = maxf(_cooldown - dt, 0.0)
	if stunned:
		state = State.IDLE
		_timer = 0.0
		return out
	match state:
		State.IDLE:
			if absf(dx) < SIGHT:
				state = State.APPROACH
				out.x = signf(dx)
		State.APPROACH:
			if absf(dx) >= SIGHT:
				state = State.IDLE
			elif absf(dx) <= ATTACK_RANGE and _cooldown <= 0.0:
				state = State.WINDUP
				_timer = 0.0
				out.windup = true
			else:
				out.x = signf(dx)
		State.WINDUP:
			_timer += dt
			if _timer >= WINDUP - EPS:
				state = State.ATTACK
				out.attack = true
		State.RECOVER:
			_timer += dt
			if _timer >= RECOVER - EPS:
				state = State.APPROACH
	return out


func attack_finished() -> void:
	state = State.RECOVER
	_timer = 0.0
	_cooldown = COOLDOWN
