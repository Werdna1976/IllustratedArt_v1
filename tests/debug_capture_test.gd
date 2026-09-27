extends TestCase
## DebugCapture autoload argument parsing (the capture itself needs a window; see tools/capture.sh).

const DebugCaptureScript := preload("res://scripts/debug_capture.gd")


func test_no_capture_args_disables_capture() -> void:
	var opts := DebugCaptureScript.parse_args(PackedStringArray(["--autorun"]))
	assert_eq(opts.path, "", "no path")
	assert_eq(opts.frames, 90, "default frames")


func test_capture_args_parsed() -> void:
	var opts := DebugCaptureScript.parse_args(PackedStringArray(["--capture=res://.godot/captures/a.png", "--capture-frames=30"]))
	assert_eq(opts.path, "res://.godot/captures/a.png", "path")
	assert_eq(opts.frames, 30, "frames")
