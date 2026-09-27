extends Node
## Dev tool autoload: run with `-- --capture=<res:// png path> [--capture-frames=N]` to save the
## rendered frame at the real window size after N frames (default 90), then quit. Unlike Movie
## Maker, this keeps non-16:9 window sizes intact. Driven by tools/capture.sh.

var _path := ""
var _frames := 90


func _ready() -> void:
	var opts := parse_args(OS.get_cmdline_user_args())
	_path = opts.path
	_frames = opts.frames
	set_process(_path != "")


func _process(_delta: float) -> void:
	if Engine.get_process_frames() < _frames:
		return
	set_process(false)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_path)
	get_tree().quit()


static func parse_args(args: PackedStringArray) -> Dictionary:
	var opts := {"path": "", "frames": 90}
	for arg in args:
		if arg.begins_with("--capture="):
			opts.path = arg.get_slice("=", 1)
		elif arg.begins_with("--capture-frames="):
			opts.frames = arg.get_slice("=", 1).to_int()
	return opts
