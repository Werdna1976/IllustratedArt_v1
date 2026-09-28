class_name ArenaZone
extends Area3D
## An arena fight (spec §5.4): when the player enters, the camera locks to the arena, barrier
## walls close both sides and the enemies spawn; when every enemy has died the walls open and the
## camera unlocks. reset() returns an unfinished arena to its untriggered state (player death).

signal started
signal cleared

const BLEND := 0.5
const WALL_THICKNESS := 1.0
const GATE_COLOR := Color(1.0, 0.18, 0.25) ## Red holographic security gate.
const GATE_ALPHA := 0.35
const GATE_WIDTH := 0.8 ## Metres, drawn inside the arena so it shows at the screen edge.
const GATE_INSET := 0.15 ## Extra inset: the gate sits nearer the camera than the wall, so perspective pushes it outward.

var rect := Rect2()
var specs: Array = []
var active := false
var is_cleared := false
var enemies: Array[Enemy] = []
var barriers: Array[StaticBody3D] = []

var _alive := 0


func setup(p_rect: Rect2, enemy_specs: Array) -> void:
	rect = p_rect
	specs = enemy_specs
	collision_layer = 0
	collision_mask = Fighter.LAYER_ACTORS
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(rect.size.x, rect.size.y, 2.0)
	shape.shape = box
	add_child(shape)
	position = Vector3(rect.get_center().x, rect.get_center().y, 0.0)
	body_entered.connect(_on_body_entered)


func reset() -> void:
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemies.clear()
	_drop_barriers()
	if active and not is_cleared:
		get_tree().call_group(&"camera_rig", &"unlock", 0.0)
	active = false


func _on_body_entered(body: Node3D) -> void:
	if body is Player and not active and not is_cleared:
		active = true
		_start.call_deferred() # spawning bodies inside a physics callback is not allowed


func _start() -> void:
	get_tree().call_group(&"camera_rig", &"lock_to", rect, BLEND)
	# [wall left x, which side of the wall faces the arena (+1 right, -1 left)]
	for side: Array in [[rect.position.x - WALL_THICKNESS, 1.0], [rect.end.x, -1.0]]:
		var wall := LevelBuilder.block(get_parent(), Rect2(side[0], rect.position.y, WALL_THICKNESS, rect.size.y + 10.0), null)
		wall.add_child(_gate(side[1]))
		barriers.append(wall)
	_alive = specs.size()
	for spec: Dictionary in specs:
		var enemy := Section.spawn_enemy(spec)
		get_parent().add_child(enemy)
		enemy.died.connect(_on_enemy_died)
		enemies.append(enemy)
	started.emit()
	if _alive == 0:
		_clear()


# Visible, glowing gate so the lock reads as "security sealed the area", not an invisible wall.
func _gate(facing: float) -> MeshInstance3D:
	var quad := QuadMesh.new()
	quad.size = Vector2(GATE_WIDTH, rect.size.y)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(GATE_COLOR, GATE_ALPHA)
	mat.emission_enabled = true
	mat.emission = GATE_COLOR
	mat.emission_energy_multiplier = 2.0
	var gate := MeshInstance3D.new()
	gate.mesh = quad
	gate.material_override = mat
	# Block origin is its centre; place the gate on the arena-facing edge, bottom at the arena floor.
	# Camera locks keep the view inside the arena, so the gate sits wholly inside it (at the screen edge).
	gate.position = Vector3(facing * ((WALL_THICKNESS + GATE_WIDTH) * 0.5 + GATE_INSET), rect.size.y * 0.5 - (rect.size.y + 10.0) * 0.5, WorldSpec.ACTOR_Z)
	var glow := OmniLight3D.new()
	glow.light_color = GATE_COLOR
	glow.omni_range = 4.0
	glow.light_energy = 2.0
	glow.position = Vector3(0.0, -rect.size.y * 0.25, 0.8)
	gate.add_child(glow)
	return gate


func _on_enemy_died() -> void:
	_alive -= 1
	if _alive <= 0 and active:
		_clear()


func _clear() -> void:
	is_cleared = true
	_drop_barriers()
	get_tree().call_group(&"camera_rig", &"unlock", BLEND)
	cleared.emit()


func _drop_barriers() -> void:
	for wall in barriers:
		if is_instance_valid(wall):
			wall.queue_free()
	barriers.clear()
