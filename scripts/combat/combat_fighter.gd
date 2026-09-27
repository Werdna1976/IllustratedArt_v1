class_name CombatFighter
extends RefCounted
## Pure move state machine (spec §5.7): starts moves from logical requests, chains and buffers
## combos, allows dodge-cancels from recovery, tracks invulnerability, parry window and stun.
## advance() reports events: "started:<id>", "active_start", "active_end", "done".

const LOGICAL := {&"heavy": &"heavy", &"launcher": &"launcher", &"parry": &"parry", &"dodge": &"dodge", &"finisher": &"finisher"}

var moves: MoveSet
var current: MoveData ## null = free to act.
var t := 0.0
var hit_this_move := {} ## target -> true; cleared per move so each swing hits a target once.
var buffered: StringName

var _stun_left := 0.0
var _events: Array[StringName] = []


func request(id: StringName, airborne: bool = false) -> bool:
	if is_stunned():
		return false
	var move := moves.get_move(_resolve(id, airborne))
	if move == null or (move.airborne_only and not airborne):
		return false
	if current == null:
		_start(move)
		return true
	if id == &"light" and current.next_combo != &"" and move.id == current.next_combo:
		if t >= current.cancel_time() - MoveData.EPS:
			_start(move)
		elif buffered == &"":
			buffered = move.id
		return true
	if move.is_dodge and phase() == MoveData.Phase.RECOVERY:
		_start(move)
		return true
	return false


func advance(dt: float) -> Array[StringName]:
	if _stun_left > 0.0:
		_stun_left -= dt
	if current and buffered != &"" and t + dt >= current.cancel_time() - MoveData.EPS:
		_start(moves.get_move(buffered))
	elif current:
		var before := current.phase_at(t)
		t += dt
		var after := current.phase_at(t)
		if before == MoveData.Phase.STARTUP and after != MoveData.Phase.STARTUP:
			_events.append(&"active_start")
		if before <= MoveData.Phase.ACTIVE and after >= MoveData.Phase.RECOVERY:
			_events.append(&"active_end")
		if after == MoveData.Phase.DONE:
			_events.append(&"done")
			current = null
	var out := _events
	_events = []
	return out


func phase() -> MoveData.Phase:
	return current.phase_at(t) if current else MoveData.Phase.DONE


func is_invulnerable() -> bool:
	return current != null and current.is_dodge and phase() == MoveData.Phase.ACTIVE


func is_parrying() -> bool:
	return current != null and current.is_parry and phase() == MoveData.Phase.ACTIVE


func stun(duration: float) -> void:
	current = null
	buffered = &""
	hit_this_move = {}
	_stun_left = duration


func is_stunned() -> bool:
	return _stun_left > MoveData.EPS


func _resolve(id: StringName, airborne: bool) -> StringName:
	if id != &"light":
		return LOGICAL.get(id, id)
	if airborne:
		return &"air_light"
	if current and current.next_combo != &"":
		return current.next_combo
	return &"light1"


func _start(move: MoveData) -> void:
	current = move
	t = 0.0
	buffered = &""
	hit_this_move = {}
	_events.append(StringName("started:%s" % move.id))
	if move.phase_at(0.0) == MoveData.Phase.ACTIVE:
		_events.append(&"active_start")
