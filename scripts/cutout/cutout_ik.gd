class_name CutoutIK
extends Node2D
## Pins the far hand to the katana's rear grip for two-handed poses: after the animation each
## frame, the far arm's bones are rotated (blended by `weight`, animatable) so the far fist lands
## on the FarGrip marker, and the far hand copies the near hand's angle on the grip.

@export var upper_path: NodePath
@export var lower_path: NodePath
@export var hand_path: NodePath
@export var near_hand_path: NodePath
@export var katana_path: NodePath
@export var target_path: NodePath ## FarGrip marker on the katana
@export var weight := 1.0 ## 0 = pure animation, 1 = hand on the grip
@export var bend := 1.0 ## Elbow side

var upper: Node2D
var lower: Node2D
var hand: Node2D
var near_hand: Node2D
var katana: Node2D
var target: Node2D


func _ready() -> void:
	process_priority = 100 # after the AnimationPlayer has posed the rig
	_resolve()


func _process(_delta: float) -> void:
	apply()


func apply() -> void:
	if upper == null:
		_resolve()
	if weight <= 0.0 or upper == null:
		return
	var parent_rot := _rel(upper.get_parent()).get_rotation()
	var shoulder := _rel(upper).origin
	# The far fist should sit on the grip the way the near fist sits on the katana pivot.
	var fist_offset := _rel(katana).origin - _rel(near_hand).origin
	var wrist_target := _rel(target).origin - fist_offset
	var angles := TwoBoneIK.solve(shoulder, wrist_target, lower.position.length(), hand.position.length(), bend)
	upper.rotation = lerp_angle(upper.rotation, angles[0] - lower.position.angle() - parent_rot, weight)
	var lower_parent_rot := parent_rot + upper.rotation
	lower.rotation = lerp_angle(lower.rotation, angles[1] - hand.position.angle() - lower_parent_rot, weight)
	var near_rot := _rel(near_hand).get_rotation()
	hand.rotation = lerp_angle(hand.rotation, near_rot - lower_parent_rot - lower.rotation, weight)


func _resolve() -> void:
	upper = get_node_or_null(upper_path)
	lower = get_node_or_null(lower_path)
	hand = get_node_or_null(hand_path)
	near_hand = get_node_or_null(near_hand_path)
	katana = get_node_or_null(katana_path)
	target = get_node_or_null(target_path)


# Transform relative to the rig root (this node's parent).
func _rel(node: Node) -> Transform2D:
	return get_parent().get_global_transform().affine_inverse() * (node as Node2D).get_global_transform()
