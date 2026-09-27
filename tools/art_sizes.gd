extends SceneTree
## Prints plate sizes for a section; optionally writes them as JSON for check_art.py.
## usage: godot --headless --path . --script res://tools/art_sizes.gd -- <width_m> <height_m> [out.json]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		printerr("usage: -- <width_m> <height_m> [out.json]")
		quit(1)
		return
	var sizes := ArtSizes.for_section(Vector2(args[0].to_float(), args[1].to_float()))
	var out := {}
	for layer: String in sizes:
		var s: Vector2i = sizes[layer]
		print("%s %dx%d" % [layer, s.x, s.y])
		out[layer] = [s.x, s.y]
	if args.size() > 2:
		var f := FileAccess.open(args[2], FileAccess.WRITE)
		f.store_string(JSON.stringify(out, "  "))
	quit(0)
