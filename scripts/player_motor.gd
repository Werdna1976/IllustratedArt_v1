class_name PlayerMotor
extends RefCounted
## Pure platformer movement maths (metres, seconds), unit-testable without physics.

const RUN_SPEED := 8.0
const ACCEL := 60.0
const AIR_ACCEL := 35.0
const GRAVITY := 30.0
const JUMP_VELOCITY := 13.5 ## Apex ≈ 3 m.
const MAX_FALL_SPEED := 25.0


static func step(v: Vector3, input_x: float, jump: bool, on_floor: bool, delta: float) -> Vector3:
	var accel := ACCEL if on_floor else AIR_ACCEL
	v.x = move_toward(v.x, clampf(input_x, -1.0, 1.0) * RUN_SPEED, accel * delta)
	if on_floor and jump:
		v.y = JUMP_VELOCITY
	elif not on_floor:
		v.y = maxf(v.y - GRAVITY * delta, -MAX_FALL_SPEED)
	v.z = 0.0
	return v
