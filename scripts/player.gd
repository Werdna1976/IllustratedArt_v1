class_name Player
extends CharacterBody3D
## Capsule player on the gameplay plane. Collision at z = 0; the visual is offset to
## WorldSpec.ACTOR_Z so it always draws in front of the gameplay plate.

const RADIUS := 0.4
const HEIGHT := 1.8

var facing := 1.0 ## +1 right, -1 left; read by CameraRig for look-ahead.
var autorun := false ## Forces running right (demo / capture runs).


static func create() -> Player:
	var player := Player.new()
	player.axis_lock_linear_z = true
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = RADIUS
	capsule.height = HEIGHT
	shape.shape = capsule
	player.add_child(shape)
	var visual := MeshInstance3D.new()
	visual.name = "Visual"
	var mesh := CapsuleMesh.new()
	mesh.radius = RADIUS
	mesh.height = HEIGHT
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.55, 0.2)
	mesh.material = mat
	visual.mesh = mesh
	visual.position.z = WorldSpec.ACTOR_Z
	player.add_child(visual)
	return player


func _ready() -> void:
	GameInput.ensure_actions()


func _physics_process(delta: float) -> void:
	var input_x := 1.0 if autorun else Input.get_axis(&"move_left", &"move_right")
	if input_x != 0.0:
		facing = signf(input_x)
	velocity = PlayerMotor.step(velocity, input_x, Input.is_action_just_pressed(&"jump"), is_on_floor(), delta)
	move_and_slide()
