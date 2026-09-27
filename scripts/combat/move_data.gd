class_name MoveData
extends Resource
## One attack/defence move (spec §5.7). Times in seconds; distances in metres; the hitbox is
## given for a fighter facing right, relative to the body centre.

enum Phase { STARTUP, ACTIVE, RECOVERY, DONE }

const EPS := 1e-6 ## Boundary tolerance so summed float times (0.1 + 0.2 + 0.3) land on the right phase.

@export var id: StringName
@export var anim: StringName
@export var startup := 0.0
@export var active := 0.0
@export var recovery := 0.0
@export var damage := 0.0
@export var stagger := 0.0
@export var knockback := Vector2.ZERO ## x forward, y up (m/s).
@export var hit_stop := 0.0
@export var cancel_from := -1.0 ## -1 = end of the active window.
@export var next_combo: StringName
@export var hitbox_offset := Vector2.ZERO
@export var hitbox_size := Vector2.ZERO
@export var dash_speed := 0.0
@export var is_parry := false
@export var is_dodge := false
@export var airborne_only := false
@export var requires_staggered_target := false


func total() -> float:
	return startup + active + recovery


func phase_at(t: float) -> Phase:
	if t < startup - EPS:
		return Phase.STARTUP
	if t < startup + active - EPS:
		return Phase.ACTIVE
	if t < total() - EPS:
		return Phase.RECOVERY
	return Phase.DONE


func cancel_time() -> float:
	return startup + active if cancel_from < 0.0 else cancel_from
