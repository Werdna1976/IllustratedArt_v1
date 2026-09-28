class_name ArenaZone
extends Area3D
## An arena fight (spec §5.4): when the player enters, the camera locks to the arena, barrier
## walls close both sides and the enemies spawn; when every enemy has died the walls open and the
## camera unlocks. reset() returns an unfinished arena to its untriggered state (player death).

signal started
signal cleared

const BLEND := 0.5
const WALL_THICKNESS := 1.0

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
	for x in [rect.position.x - WALL_THICKNESS, rect.end.x]:
		barriers.append(LevelBuilder.block(get_parent(), Rect2(x, rect.position.y, WALL_THICKNESS, rect.size.y + 10.0), null))
	_alive = specs.size()
	for spec: Dictionary in specs:
		var enemy := Section.spawn_enemy(spec)
		get_parent().add_child(enemy)
		enemy.died.connect(_on_enemy_died)
		enemies.append(enemy)
	started.emit()
	if _alive == 0:
		_clear()


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
