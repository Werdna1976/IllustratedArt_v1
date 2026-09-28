class_name Flicker
extends Node
## Flickers glow on plate layers (anything with set_glow) and light energies: mostly steady with
## brief dips, like failing fluorescents. level() is deterministic so it is testable.

const RATE := 12.0 ## Noise steps per second.

var _targets: Array[Dictionary] = []
var _time := 0.0


func add_layer(layer: Object, amount: float) -> void:
	_targets.append({"obj": layer, "base": 1.0, "amount": amount, "phase": randf() * 100.0, "light": false})


func add_light(light: Light3D, amount: float) -> void:
	_targets.append({"obj": light, "base": light.light_energy, "amount": amount, "phase": randf() * 100.0, "light": true})


func _process(delta: float) -> void:
	_time += delta
	for t in _targets:
		var v: float = t.base * level(_time + t.phase, t.amount)
		if t.light:
			(t.obj as Light3D).light_energy = v
		else:
			t.obj.set_glow(v)


## Brightness factor in [1 - amount, 1].
static func level(t: float, amount: float) -> float:
	var step := floorf(t * RATE)
	var f := t * RATE - step
	var dip := lerpf(_dip(step), _dip(step + 1.0), f)
	return 1.0 - amount * dip


static func _dip(step: float) -> float:
	var n := fposmod(sin(step * 12.9898) * 43758.5453, 1.0)
	return smoothstep(0.7, 1.0, n)
