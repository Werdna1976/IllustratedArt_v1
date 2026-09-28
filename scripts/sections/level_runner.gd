class_name LevelRunner
extends Node3D
## Plays a level as a chain of sections (spec §3.1): fades between sections, spawns the player and
## camera at each section's spawn, respawns the player after death (resetting unfinished arenas),
## and returns to the title when the last section's exit is reached.
## User args: `--section=N` starts at section N; `--spawn-x=M` spawns the player at x = M metres
## in the first section loaded (captures, testing).

signal level_completed

const LEVELS := {"l1": ["res://art/levels/l1_station", "res://art/levels/l1_train"]}
const TITLE := "res://scenes/ui/title_screen.tscn"
const RESPAWN_DELAY := 1.0

@export var level_id := "l1"

var fade_time := 0.4
var return_to_title := true
var autostart := true
var section_dirs: Array = []
var index := -1
var section: Section
var player: Player
var rig: CameraRig

var _fade: ColorRect
var _busy := false
var _first_load := true


func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade)
	add_child(layer)
	if autostart:
		var first := 0
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--section="):
				first = arg.get_slice("=", 1).to_int()
		start([], first)


func start(dirs: Array = [], first: int = 0) -> void:
	section_dirs = dirs if not dirs.is_empty() else LEVELS[level_id]
	go_to(first)


func go_to(i: int) -> void:
	_busy = true
	if section:
		await _fade_to(1.0)
		section.queue_free()
	else:
		_fade.color.a = 1.0 # first section: start from black, nothing to fade out
	index = i
	var def := SectionDef.load_dir(section_dirs[i])
	section = Section.new()
	section.setup(def)
	add_child(section)
	section.exited.connect(_on_exited, CONNECT_DEFERRED) # exits fire inside physics callbacks
	player = Player.create()
	var spawn_x := def.spawn.x
	var override := spawn_x_override(OS.get_cmdline_user_args())
	if _first_load and not is_nan(override):
		spawn_x = clampf(override, 2.0, def.size.x - 2.0)
	_first_load = false
	player.position = Vector3(spawn_x, def.spawn.y + 3.0 if spawn_x != def.spawn.x else def.spawn.y, 0.0)
	section.add_child(player)
	player.died.connect(_on_player_died)
	rig = CameraRig.new()
	rig.target = player
	rig.level_size = def.size
	section.add_child(rig)
	rig.snap_to_target()
	await _fade_to(0.0)
	_busy = false


static func spawn_x_override(args: PackedStringArray) -> float:
	for arg in args:
		if arg.begins_with("--spawn-x="):
			return arg.get_slice("=", 1).to_float()
	return NAN


func _on_exited() -> void:
	if _busy:
		return
	if index + 1 < section_dirs.size():
		go_to(index + 1)
		return
	level_completed.emit()
	if return_to_title:
		get_tree().change_scene_to_file(TITLE)


func _on_player_died() -> void:
	await get_tree().create_timer(RESPAWN_DELAY).timeout
	if not is_instance_valid(player):
		return
	for arena in section.arenas:
		if not arena.is_cleared:
			arena.reset()
	player.global_position = Vector3(section.def.spawn.x, section.def.spawn.y, 0.0)
	player.revive()
	player.reset_physics_interpolation()
	rig.unlock(0.0)
	rig.snap_to_target()


func _fade_to(alpha: float) -> void:
	if fade_time <= 0.0:
		_fade.color.a = alpha
		return
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", alpha, fade_time)
	await tween.finished
