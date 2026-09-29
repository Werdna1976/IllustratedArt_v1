class_name Enemy
extends Fighter
## Network-controlled enemy driven by an OfficerBrain; uses the placeholder cutout, tinted.

const OFFICER_MOVES := preload("res://data/moves/officer.tres")
const OFFICER_RIG := preload("res://scenes/characters/officer_rig.tscn")
const OFFICER_ALBEDO := preload("res://art/characters/officer/parts.png")
const OFFICER_NORMAL := preload("res://art/characters/officer/parts_n.png")
const OFFICER_EMISSIVE := preload("res://art/characters/officer/parts_emit.png")
const OFFICER_TINT := Color.WHITE ## The officer art carries its own uniform colours.
const DEATH_DELAY := 0.6

var brain: OfficerBrain


static func create_officer() -> Enemy:
	var enemy := Enemy.new()
	enemy.setup(OFFICER_TINT, 60.0, 40.0)
	enemy.brain = OfficerBrain.new()
	return enemy


func setup(tint: Color, hp: float, stagger: float) -> void:
	build(OFFICER_RIG, OFFICER_ALBEDO, OFFICER_NORMAL, OFFICER_EMISSIVE, OFFICER_MOVES, hp, stagger)
	is_network = true
	facing = -1.0
	for quad: MeshInstance3D in mirror.quads.values():
		(quad.material_override as StandardMaterial3D).albedo_color = tint


func _ready() -> void:
	add_to_group(&"enemies")


func intent() -> Dictionary:
	if brain == null:
		return super()
	var target := get_tree().get_first_node_in_group(&"player") as Node3D
	var dx := target.global_position.x - global_position.x if target else 1e6
	var out := brain.tick(get_physics_process_delta_time(), dx, combat.is_stunned())
	if combat.current == null and not combat.is_stunned():
		facing = out.face
	if out.windup:
		_play(&"windup")
	var speed_scale := OfficerBrain.SPEED / PlayerMotor.RUN_SPEED
	return {"x": out.x * speed_scale, "jump": false, "action": &"officer_attack" if out.attack else &""}


func receive_hit(result: Dictionary, attacker: Fighter) -> void:
	super(result, attacker)
	if vitals.is_dead() and is_in_group(&"enemies"):
		# Out of play immediately (arenas count it as cleared); the body lingers briefly for feedback.
		remove_from_group(&"enemies")
		hurtbox.set_deferred("monitorable", false)
		brain = null
		get_tree().create_timer(DEATH_DELAY).timeout.connect(queue_free)


func _on_event(event: StringName) -> void:
	super(event)
	if event == &"done" and brain and brain.state == OfficerBrain.State.ATTACK:
		brain.attack_finished()


func _update_base_anim() -> void:
	if brain and brain.state == OfficerBrain.State.WINDUP:
		return # hold the telegraph pose (and its red glint)
	super()
