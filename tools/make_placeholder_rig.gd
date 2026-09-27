extends SceneTree
## Builds the placeholder fighter cutout rig + animations (M2 plan, Task 3) from
## art/characters/placeholder_fighter/parts.json and saves it as a scene.
## usage: godot --headless --path . --script res://tools/make_placeholder_rig.gd

const ART := "res://art/characters/placeholder_fighter/"
const OUT := "res://scenes/characters/placeholder_fighter_rig.tscn"

const ARM_UPPER_NEAR := "Pelvis/Torso/ArmUpperNear"
const ARM_LOWER_NEAR := "Pelvis/Torso/ArmUpperNear/ArmLowerNear"
const ARM_UPPER_FAR := "Pelvis/Torso/ArmUpperFar"
const TORSO := "Pelvis/Torso"
const HEAD := "Pelvis/Torso/Head"
const GLINT := "Pelvis/Torso/Head/Glint"
const THIGH_NEAR := "Pelvis/ThighNear"
const THIGH_FAR := "Pelvis/ThighFar"
const SHIN_NEAR := "Pelvis/ThighNear/ShinNear"
const SHIN_FAR := "Pelvis/ThighFar/ShinFar"

# [path, region, position, offset, z_index]
const PARTS := [
	["Pelvis", "pelvis", Vector2(0, -350), Vector2(0, -20), 0],
	["Pelvis/Torso", "torso", Vector2(0, -40), Vector2(0, -115), 1],
	["Pelvis/Torso/Head", "head", Vector2(5, -235), Vector2(0, -50), 2],
	["Pelvis/Torso/Head/Glint", "glint", Vector2(25, -60), Vector2.ZERO, 6],
	["Pelvis/Torso/ArmUpperFar", "arm_upper_far", Vector2(-5, -210), Vector2(0, 55), -2],
	["Pelvis/Torso/ArmUpperFar/ArmLowerFar", "arm_lower_far", Vector2(0, 110), Vector2(0, 55), -2],
	["Pelvis/Torso/ArmUpperFar/ArmLowerFar/HandFar", "hand_far", Vector2(0, 110), Vector2(0, 15), -2],
	["Pelvis/ThighFar", "thigh_far", Vector2(0, 10), Vector2(0, 80), -1],
	["Pelvis/ThighFar/ShinFar", "shin_far", Vector2(0, 160), Vector2(0, 80), -1],
	["Pelvis/ThighFar/ShinFar/FootFar", "foot_far", Vector2(0, 165), Vector2(20, 0), -1],
	["Pelvis/ThighNear", "thigh_near", Vector2(0, 10), Vector2(0, 80), 2],
	["Pelvis/ThighNear/ShinNear", "shin_near", Vector2(0, 160), Vector2(0, 80), 2],
	["Pelvis/ThighNear/ShinNear/FootNear", "foot_near", Vector2(0, 165), Vector2(20, 0), 2],
	["Pelvis/Torso/ArmUpperNear", "arm_upper_near", Vector2(5, -210), Vector2(0, 55), 3],
	["Pelvis/Torso/ArmUpperNear/ArmLowerNear", "arm_lower_near", Vector2(0, 110), Vector2(0, 55), 3],
	["Pelvis/Torso/ArmUpperNear/ArmLowerNear/HandNear", "hand_near", Vector2(0, 110), Vector2(0, 15), 3],
	["Pelvis/Torso/ArmUpperNear/ArmLowerNear/HandNear/Blade", "blade", Vector2(0, 10), Vector2(190, 0), 4],
]

# name: [length, loop, {part_path: [[t, angle], ...]}]; windup also shows the glint.
const ANIMS := {
	"idle": [1.2, true, {TORSO: [[0, 0], [0.6, 0.04], [1.2, 0]], ARM_UPPER_NEAR: [[0, 0.3], [0.6, 0.35], [1.2, 0.3]]}],
	"run": [0.5, true, {THIGH_NEAR: [[0, -0.6], [0.25, 0.6], [0.5, -0.6]], THIGH_FAR: [[0, 0.6], [0.25, -0.6], [0.5, 0.6]],
		SHIN_NEAR: [[0, 0.5], [0.25, 0], [0.5, 0.5]], SHIN_FAR: [[0, 0], [0.25, 0.5], [0.5, 0]],
		ARM_UPPER_NEAR: [[0, 0.6], [0.25, -0.6], [0.5, 0.6]], ARM_UPPER_FAR: [[0, -0.6], [0.25, 0.6], [0.5, -0.6]]}],
	"jump": [0.2, false, {THIGH_NEAR: [[0, -0.5], [0.2, -0.5]], THIGH_FAR: [[0, -0.5], [0.2, -0.5]],
		SHIN_NEAR: [[0, 0.8], [0.2, 0.8]], SHIN_FAR: [[0, 0.8], [0.2, 0.8]]}],
	"fall": [0.2, false, {ARM_UPPER_NEAR: [[0, -0.8], [0.2, -0.8]], ARM_UPPER_FAR: [[0, -0.8], [0.2, -0.8]]}],
	"light1": [0.34, false, {ARM_UPPER_NEAR: [[0, -2.2], [0.08, -2.0], [0.16, 0.6], [0.34, 0.3]]}],
	"light2": [0.36, false, {ARM_UPPER_NEAR: [[0, 0.6], [0.08, 0.7], [0.16, -1.5], [0.36, -0.2]]}],
	"light3": [0.52, false, {ARM_UPPER_NEAR: [[0, -2.8], [0.12, -2.9], [0.22, 0.9], [0.52, 0.3]], TORSO: [[0.12, -0.1], [0.22, 0.15]]}],
	"heavy": [0.82, false, {ARM_UPPER_NEAR: [[0, -2.6], [0.30, -2.7], [0.42, 1.0], [0.82, 0.3]], TORSO: [[0.30, -0.2], [0.42, 0.25]]}],
	"launcher": [0.63, false, {ARM_UPPER_NEAR: [[0, 1.0], [0.18, 1.1], [0.28, -2.6], [0.63, -0.5]]}],
	"air_light": [0.31, false, {ARM_UPPER_NEAR: [[0, -1.8], [0.06, -1.8], [0.16, 0.8], [0.31, 0.3]]}],
	"finisher": [0.80, false, {ARM_UPPER_NEAR: [[0, -3.0], [0.10, -3.1], [0.30, 1.2], [0.80, 0.3]], TORSO: [[0.10, -0.3], [0.30, 0.35]]}],
	"parry": [0.42, false, {ARM_UPPER_NEAR: [[0, -1.2], [0.42, -1.2]], ARM_LOWER_NEAR: [[0, -0.6], [0.42, -0.6]]}],
	"dodge": [0.37, false, {TORSO: [[0, 0], [0.1, -0.45], [0.37, 0]], THIGH_NEAR: [[0.1, -0.7]]}],
	"hurt": [0.30, false, {TORSO: [[0, 0], [0.08, 0.3], [0.30, 0]], HEAD: [[0.08, 0.25]]}],
	"staggered": [1.0, true, {TORSO: [[0, 0.5], [1.0, 0.5]], HEAD: [[0, 0.4], [1.0, 0.4]],
		ARM_UPPER_NEAR: [[0, 0.5], [1.0, 0.5]], ARM_UPPER_FAR: [[0, 0.5], [1.0, 0.5]]}],
	"windup": [0.45, false, {ARM_UPPER_NEAR: [[0, 0.3], [0.45, -2.4]]}],
	"officer_attack": [0.75, false, {ARM_UPPER_NEAR: [[0, -2.4], [0.15, 0.8], [0.75, 0.3]]}],
}


func _initialize() -> void:
	var regions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ART + "parts.json"))
	var tex: Texture2D = load(ART + "parts.png")
	var rig := Node2D.new()
	rig.name = "PlaceholderFighterRig"
	for p: Array in PARTS:
		var sprite := Sprite2D.new()
		var path: String = p[0]
		sprite.name = path.get_file()
		var r: Array = regions[p[1]]
		sprite.texture = tex
		sprite.region_enabled = true
		sprite.region_rect = Rect2(r[0], r[1], r[2], r[3])
		sprite.position = p[2]
		sprite.offset = p[3]
		sprite.z_index = p[4]
		sprite.visible = p[1] != "glint"
		var parent: Node = rig if path.get_base_dir() == "" else rig.get_node(path.get_base_dir())
		parent.add_child(sprite)
		sprite.owner = rig
	var player := AnimationPlayer.new()
	player.name = "AnimationPlayer"
	rig.add_child(player)
	player.owner = rig
	player.add_animation_library(&"", _library())
	var packed := PackedScene.new()
	packed.pack(rig)
	DirAccess.make_dir_recursive_absolute(OUT.get_base_dir())
	var err := ResourceSaver.save(packed, OUT)
	print("saved %s (%s)" % [OUT, error_string(err)])
	rig.free()
	quit(0 if err == OK else 1)


func _library() -> AnimationLibrary:
	var animated := {} # every part any animation touches gets a track in every animation (no pose leaks)
	for anim_name: String in ANIMS:
		for path: String in ANIMS[anim_name][2]:
			animated[path] = true
	var lib := AnimationLibrary.new()
	for anim_name: String in ANIMS:
		var spec: Array = ANIMS[anim_name]
		var length: float = spec[0]
		var anim := Animation.new()
		anim.length = length
		anim.loop_mode = Animation.LOOP_LINEAR if spec[1] else Animation.LOOP_NONE
		for path: String in animated:
			var keys: Array = spec[2].get(path, [[0, 0]])
			var t := anim.add_track(Animation.TYPE_VALUE)
			anim.track_set_path(t, NodePath(path + ":rotation"))
			if keys[0][0] > 0:
				anim.track_insert_key(t, 0.0, 0.0)
			for k: Array in keys:
				anim.track_insert_key(t, k[0], k[1])
			if keys[-1][0] < length and keys.size() > 1 or keys[0][0] > 0:
				anim.track_insert_key(t, length, 0.0)
		var g := anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(g, NodePath(GLINT + ":visible"))
		anim.value_track_set_update_mode(g, Animation.UPDATE_DISCRETE)
		anim.track_insert_key(g, 0.0, anim_name == "windup")
		if anim_name == "windup":
			anim.track_insert_key(g, length, false)
		lib.add_animation(anim_name, anim)
	return lib
