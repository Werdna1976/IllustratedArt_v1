class_name TrainingDummy
extends Enemy
## Stands still, never dies, and shows a floating damage number for every hit (tuning aid).

const DUMMY_TINT := Color(0.7, 0.7, 0.75)
const NUMBER_RISE := 0.6
const NUMBER_TIME := 0.8

var last_numbers: Array[float] = []


static func create_dummy() -> TrainingDummy:
	var dummy := TrainingDummy.new()
	dummy.setup(DUMMY_TINT, 1e9, 60.0)
	return dummy


func _ready() -> void:
	super()
	got_hit.connect(_show_number)


func _show_number(result: Dictionary) -> void:
	last_numbers.append(result.damage)
	var label := Label3D.new()
	label.text = "%d" % int(result.damage)
	label.modulate = Color.WHITE
	label.outline_size = 8
	label.pixel_size = 0.01
	label.position = Vector3(0.0, 1.2, WorldSpec.ACTOR_Z + 0.2)
	add_child(label)
	var tween := label.create_tween()
	tween.tween_property(label, "position:y", label.position.y + NUMBER_RISE, NUMBER_TIME)
	tween.tween_callback(label.queue_free)
