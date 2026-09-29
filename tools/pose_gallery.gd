extends SceneTree
## Dev tool: renders the player frozen in several animation poses side by side and saves one PNG.
## usage (windowed): godot --path . --resolution 1920x1080 --script res://tools/pose_gallery.gd -- \
##        <out.png> anim@time [anim@time ...]      e.g. idle@0 light1@0.08 light1@0.16 parry@0.2
## Poses are spaced 2.6 m apart in front of a plain backdrop, lit like Level 1.


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0]
	var poses := args.slice(1)
	var world := Node3D.new()
	root.add_child(world)
	LevelBuilder.environment(world, {"background": "#3a4150", "ambient": "#c2c4cf", "ambient_energy": 1.0})
	LevelBuilder.sun(world, Color("#d4d6e6"), 0.5)
	var spacing := 2.6
	var fighters: Array[Player] = []
	for i in poses.size():
		var p := Player.create()
		p.position = Vector3(i * spacing, 0.9, 0)
		world.add_child(p)
		p.set_physics_process(false) # after entering the tree (ready re-enables it); keeps the pose frozen
		fighters.append(p)
	var cam := Camera3D.new()
	var width := maxf(poses.size() * spacing, 6.0)
	cam.keep_aspect = Camera3D.KEEP_WIDTH
	cam.fov = rad_to_deg(2.0 * atan(width * 0.5 / WorldSpec.CAMERA_DISTANCE)) * 1.15
	cam.position = Vector3((poses.size() - 1) * spacing * 0.5, 1.2, WorldSpec.CAMERA_DISTANCE)
	world.add_child(cam)
	cam.make_current()
	await process_frame
	for i in poses.size():
		var parts: PackedStringArray = poses[i].split("@")
		var f := fighters[i]
		f.anim.play(parts[0])
		f.anim.seek(parts[1].to_float() if parts.size() > 1 else 0.0, true)
		f.anim.pause()
		(f.rig.get_node("CutoutIK") as CutoutIK).apply()
		f.mirror.sync()
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out)
	print("saved ", out)
	quit(0)
