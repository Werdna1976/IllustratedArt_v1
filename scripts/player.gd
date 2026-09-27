class_name Player
extends Fighter
## Input-driven fighter using the placeholder cutout (spec §5.6–5.7). Heavy becomes the finisher
## when a staggered enemy stands within FINISHER_RANGE in front.

const FINISHER_RANGE := 2.0
const RIG := preload("res://scenes/characters/placeholder_fighter_rig.tscn")
const ALBEDO := preload("res://art/characters/placeholder_fighter/parts.png")
const NORMAL := preload("res://art/characters/placeholder_fighter/parts_n.png")
const EMISSIVE := preload("res://art/characters/placeholder_fighter/parts_emit.png")
const MOVES := preload("res://data/moves/player.tres")

var autorun := false ## Forces running right (demo / capture runs).


static func create() -> Player:
	var player := Player.new()
	player.build(RIG, ALBEDO, NORMAL, EMISSIVE, MOVES, 100.0, 100.0)
	return player


func _ready() -> void:
	GameInput.ensure_actions()


func intent() -> Dictionary:
	var action := &""
	if Input.is_action_just_pressed(&"light_attack"):
		action = &"light"
	elif Input.is_action_just_pressed(&"heavy_attack"):
		action = resolve_heavy_action()
	elif Input.is_action_just_pressed(&"launcher"):
		action = &"launcher"
	elif Input.is_action_just_pressed(&"parry"):
		action = &"parry"
	elif Input.is_action_just_pressed(&"dodge"):
		action = &"dodge"
	var x := 1.0 if autorun else Input.get_axis(&"move_left", &"move_right")
	return {"x": x, "jump": Input.is_action_just_pressed(&"jump"), "action": action}


func resolve_heavy_action() -> StringName:
	for node in get_tree().get_nodes_in_group(&"enemies"):
		var enemy := node as Fighter
		if enemy and enemy.vitals.is_staggered():
			var ahead := (enemy.global_position.x - global_position.x) * facing
			if ahead >= 0.0 and ahead <= FINISHER_RANGE:
				return &"finisher"
	return &"heavy"
