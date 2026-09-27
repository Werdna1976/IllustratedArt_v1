class_name CameraRig
extends Node3D
## Follows a target on the gameplay plane (spec §5.4). The rig moves in X/Y at z = 0 and its
## Camera3D child sits WorldSpec.CAMERA_DISTANCE in front, so parallax comes from perspective.
## Distance and FOV are never animated here (spec §2 invariant); only X/Y follow.

const LOOK_AHEAD := 2.5 ## Metres shown ahead of the facing direction.
const LOOK_AHEAD_RATE := 2.0 ## 1/s; how fast look-ahead swings on a turn.
const FOLLOW_RATE := 6.0 ## 1/s; exponential follow smoothing.
const DEAD_ZONE_HALF := 1.5 ## Metres of vertical free play before the camera follows.
const FOCUS_OFFSET_Y := 1.5 ## Camera centre sits this far above the target.

var target: Node3D
var level_size := WorldSpec.LEVEL_SIZE
var aspect_override := 0.0 ## > 0 forces an aspect (tests); 0 reads the viewport.
var camera: Camera3D

var _look := 0.0
var _focus_y := 0.0


func _ready() -> void:
	camera = Camera3D.new()
	camera.position = Vector3(0.0, 0.0, WorldSpec.CAMERA_DISTANCE)
	camera.far = 1000.0
	add_child(camera)
	camera.make_current()
	get_viewport().size_changed.connect(apply_projection)
	apply_projection()


func aspect() -> float:
	if aspect_override > 0.0:
		return aspect_override
	var size := get_viewport().get_visible_rect().size
	return size.x / maxf(size.y, 1.0)


func apply_projection() -> void:
	var proj := WorldSpec.projection_for_aspect(aspect())
	camera.keep_aspect = proj.keep_aspect
	camera.fov = proj.fov


## Jump straight to the target (level start / respawn) with no smoothing.
func snap_to_target() -> void:
	_look = 0.0
	_focus_y = target.global_position.y
	var c := WorldSpec.clamp_camera_center(_goal(), aspect(), level_size)
	position = Vector3(c.x, c.y, 0.0)
	reset_physics_interpolation()


func _physics_process(delta: float) -> void:
	if target == null:
		return
	var facing: float = (target as Player).facing if target is Player else 1.0
	_look = smooth(_look, facing * LOOK_AHEAD, LOOK_AHEAD_RATE, delta)
	_focus_y = dead_zone(_focus_y, target.global_position.y, DEAD_ZONE_HALF)
	var goal := WorldSpec.clamp_camera_center(_goal(), aspect(), level_size)
	position.x = smooth(position.x, goal.x, FOLLOW_RATE, delta)
	position.y = smooth(position.y, goal.y, FOLLOW_RATE, delta)


func _goal() -> Vector2:
	return Vector2(target.global_position.x + _look, _focus_y + FOCUS_OFFSET_Y)


## Frame-rate independent exponential approach; never overshoots, even for huge delta.
static func smooth(current: float, goal: float, rate: float, delta: float) -> float:
	return lerpf(current, goal, 1.0 - exp(-rate * delta))


static func dead_zone(focus: float, target_y: float, half: float) -> float:
	return clampf(focus, target_y - half, target_y + half)
