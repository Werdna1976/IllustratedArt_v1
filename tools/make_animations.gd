extends SceneTree
## Writes the shared katana animation library (M4a plan Task 6) to data/animations/humanoid.tres.
## usage: godot --headless --path . --script res://tools/make_animations.gd
## Poses are authored as a two-handed guard plus per-key overrides. `blade` is the katana's GLOBAL
## direction (0 = pointing right, -90 = up); the katana's local rotation is derived from it.
## Every attack is a diagonal front cut (high→low or low→high); nothing swings overhead.

const OUT := "res://data/animations/humanoid.tres"
const TORSO := "Pelvis/Torso"
const ARM := "Pelvis/Torso/ArmUpperNear"
const ELBOW := "Pelvis/Torso/ArmUpperNear/ArmLowerNear"
const KATANA := "Pelvis/Torso/ArmUpperNear/ArmLowerNear/HandNear/Katana"
const FAR_ARM := "Pelvis/Torso/ArmUpperFar"
const FAR_ELBOW := "Pelvis/Torso/ArmUpperFar/ArmLowerFar"
const THIGH_N := "Pelvis/ThighNear"
const SHIN_N := "Pelvis/ThighNear/ShinNear"
const THIGH_F := "Pelvis/ThighFar"
const SHIN_F := "Pelvis/ThighFar/ShinFar"
const HEAD_SPRITE := "Pelvis/Torso/Head/Sprite"
const FAR_HAND_SPRITE := "Pelvis/Torso/ArmUpperFar/ArmLowerFar/HandFar/Sprite"
const GLINT := "Pelvis/Torso/Head/Glint"
const IK := "CutoutIK"

const GUARD := {"torso": 6.0, "arm": -35.0, "elbow": -45.0, "blade": -40.0, "far_arm": 20.0, "far_elbow": -20.0,
	"thigh_n": -20.0, "shin_n": 15.0, "thigh_f": 18.0, "shin_f": 8.0,
	"head": "head", "far_hand": "hand_grip_far", "ik": 1.0, "glint": false}
const ATTACK := {"head": "head_attack"}
const RUN_BASE := {"torso": 10.0, "arm": -20.0, "elbow": -20.0, "blade": 150.0, "ik": 0.0, "far_hand": "hand_open_far"}
const SLUMP := {"torso": 25.0, "arm": 10.0, "elbow": -10.0, "blade": 80.0, "ik": 0.0, "far_hand": "hand_open_far",
	"far_arm": 15.0, "head": "head_hurt"}

# name: [length, loop, [[t, {overrides}], ...]] — each key is GUARD merged with its overrides.
var ANIMS := {
	"RESET": [0.001, false, [[0.0, {}]]],
	"idle": [1.2, true, [[0.0, {}], [0.6, {"torso": 8.0}], [1.2, {}]]],
	"run": [0.5, true, [
		[0.0, _m(RUN_BASE, {"thigh_n": -34.0, "shin_n": 29.0, "thigh_f": 34.0, "shin_f": 0.0, "far_arm": 30.0})],
		[0.25, _m(RUN_BASE, {"thigh_n": 34.0, "shin_n": 0.0, "thigh_f": -34.0, "shin_f": 29.0, "far_arm": -30.0})],
		[0.5, _m(RUN_BASE, {"thigh_n": -34.0, "shin_n": 29.0, "thigh_f": 34.0, "shin_f": 0.0, "far_arm": 30.0})]]],
	"jump": [0.2, false, [[0.0, {"thigh_n": -40.0, "shin_n": 60.0, "thigh_f": -20.0, "shin_f": 50.0}],
		[0.2, {"thigh_n": -40.0, "shin_n": 60.0, "thigh_f": -20.0, "shin_f": 50.0}]]],
	"fall": [0.2, false, [[0.0, {"arm": -60.0, "thigh_n": -15.0, "shin_n": 20.0, "thigh_f": 10.0, "shin_f": 20.0}],
		[0.2, {"arm": -60.0, "thigh_n": -15.0, "shin_n": 20.0, "thigh_f": 10.0, "shin_f": 20.0}]]],
	# high -> low
	"light1": [0.34, false, [[0.0, _a(-4, -95, -60, -50)], [0.08, _a(-2, -92, -60, -45)],
		[0.16, _a(10, -15, -30, 35)], [0.34, {}]]],
	# low -> high
	"light2": [0.36, false, [[0.0, _a(10, -15, -30, 35)], [0.08, _a(10, -18, -30, 40)],
		[0.16, _a(0, -100, -50, -45)], [0.36, {}]]],
	# wide low -> high finish with a step
	"light3": [0.52, false, [[0.0, _a(-6, 5, -40, 70)], [0.12, _a(-6, 0, -40, 65)],
		[0.22, _m(_a(12, -110, -40, -55), {"thigh_n": -35.0})], [0.52, {}]]],
	# power high -> low: wind up at the shoulder with a torso twist (no overhead)
	"heavy": [0.82, false, [[0.0, _a(-12, -80, -80, -40)], [0.30, _a(-14, -78, -85, -45)],
		[0.42, _m(_a(16, 0, -20, 50), {"thigh_n": -35.0, "shin_n": 20.0})], [0.82, {}]]],
	# rising low -> high
	"launcher": [0.63, false, [[0.0, _a(-8, 15, -50, 80)], [0.18, _a(-8, 20, -50, 88)],
		[0.28, _a(10, -110, -40, -55)], [0.63, {}]]],
	"air_light": [0.31, false, [[0.0, _a(0, -95, -55, -45)], [0.06, _a(0, -95, -55, -45)],
		[0.16, _a(8, -20, -30, 40)], [0.31, {}]]],
	# rising cut, then a descending return cut
	"finisher": [0.80, false, [[0.0, _a(-10, 10, -40, 75)], [0.10, _a(-10, 12, -40, 80)],
		[0.30, _a(14, -110, -40, -55)], [0.55, _a(18, -10, -30, 40)], [0.80, {}]]],
	"parry": [0.42, false, [[0.0, {"torso": 0.0, "arm": -70.0, "elbow": -40.0, "blade": -80.0}],
		[0.42, {"torso": 0.0, "arm": -70.0, "elbow": -40.0, "blade": -80.0}]]],
	"dodge": [0.37, false, [[0.0, {}], [0.1, {"torso": -25.0, "thigh_n": -45.0}], [0.37, {}]]],
	"hurt": [0.30, false, [[0.0, {"head": "head_hurt"}], [0.08, {"torso": -15.0, "head": "head_hurt"}], [0.30, {}]]],
	"staggered": [1.0, true, [[0.0, SLUMP], [1.0, SLUMP]]],
	"windup": [0.45, false, [[0.0, {"glint": true}], [0.45, _m(_a(-4, -95, -60, -50), {"glint": false})]]],
	"officer_attack": [0.75, false, [[0.0, _a(-4, -95, -60, -50)], [0.15, _a(10, -15, -30, 35)], [0.75, {}]]],
}


func _initialize() -> void:
	var lib := AnimationLibrary.new()
	for anim_name: String in ANIMS:
		lib.add_animation(anim_name, _build(ANIMS[anim_name]))
	DirAccess.make_dir_recursive_absolute(OUT.get_base_dir())
	var err := ResourceSaver.save(lib, OUT)
	print("saved %s (%s), %d animations" % [OUT, error_string(err), ANIMS.size()])
	quit(0 if err == OK else 1)


func _build(spec: Array) -> Animation:
	var anim := Animation.new()
	anim.length = spec[0]
	anim.loop_mode = Animation.LOOP_LINEAR if spec[1] else Animation.LOOP_NONE
	var keys: Array = []
	for k: Array in spec[2]:
		keys.append([k[0], _m(GUARD, k[1])])
	var rot_tracks := {TORSO: "torso", ARM: "arm", ELBOW: "elbow", FAR_ARM: "far_arm", FAR_ELBOW: "far_elbow",
		THIGH_N: "thigh_n", SHIN_N: "shin_n", THIGH_F: "thigh_f", SHIN_F: "shin_f"}
	for path: String in rot_tracks:
		var t := _track(anim, path + ":rotation", Animation.UPDATE_CONTINUOUS)
		for k in keys:
			anim.track_insert_key(t, k[0], deg_to_rad(k[1][rot_tracks[path]]))
	# Katana local rotation from the global blade direction, unwrapped so keys never spin the long way.
	var kt := _track(anim, KATANA + ":rotation", Animation.UPDATE_CONTINUOUS)
	var prev := NAN
	for k in keys:
		var p: Dictionary = k[1]
		var local: float = p.blade - p.torso - p.arm - p.elbow
		if not is_nan(prev):
			local = prev + wrapf(local - prev, -180.0, 180.0)
		prev = local
		anim.track_insert_key(kt, k[0], deg_to_rad(local))
	var discrete := {HEAD_SPRITE + ":variant": "head", FAR_HAND_SPRITE + ":variant": "far_hand", GLINT + ":visible": "glint"}
	for path: String in discrete:
		var t := _track(anim, path, Animation.UPDATE_DISCRETE)
		for k in keys:
			var v: Variant = k[1][discrete[path]]
			anim.track_insert_key(t, k[0], StringName(v) if v is String else v)
	var ik := _track(anim, IK + ":weight", Animation.UPDATE_CONTINUOUS)
	for k in keys:
		anim.track_insert_key(ik, k[0], float(k[1].ik))
	return anim


func _track(anim: Animation, path: String, mode: int) -> int:
	var t := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t, NodePath(path))
	anim.value_track_set_update_mode(t, mode)
	return t


# Attack pose: torso, near arm, elbow, global blade direction (degrees) + the attack face.
static func _a(torso: float, arm: float, elbow: float, blade: float) -> Dictionary:
	return _m(ATTACK, {"torso": torso, "arm": arm, "elbow": elbow, "blade": blade})


static func _m(base: Dictionary, over: Dictionary) -> Dictionary:
	var d := base.duplicate()
	d.merge(over, true)
	return d
