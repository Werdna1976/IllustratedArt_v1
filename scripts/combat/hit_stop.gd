class_name HitStop
extends RefCounted
## Brief whole-game freeze on impact. Overlapping stops extend the freeze; time scale always
## returns to 1.0 when the latest one ends (timers run in real time, ignoring the time scale).

const SLOW := 0.05

static var _end_ms := 0 ## Real-time end of the latest-ending hit-stop.
static var _generation := 0 ## Only the timer of the latest-ending hit-stop restores time.


static func trigger(tree: SceneTree, duration: float) -> void:
	if duration <= 0.0:
		return
	var end := Time.get_ticks_msec() + int(duration * 1000.0)
	if end <= _end_ms:
		return
	_end_ms = end
	_generation += 1
	var gen := _generation
	Engine.time_scale = SLOW
	tree.create_timer(duration, true, false, true).timeout.connect(func() -> void: _restore(gen))


static func active() -> bool:
	return Engine.time_scale < 1.0


static func _restore(gen: int) -> void:
	if gen == _generation:
		Engine.time_scale = 1.0
