extends Node3D
## M1 test level (spec §9): placeholder plates at the exact spec sizes, depth fog, DoF,
## one directional + one omni light, collision layout, player and camera rig — built in code.
## User args (after `--`): --autorun makes the player run right; --spawn-x=<metres> moves the spawn.

var layers: Array[PlateLayer] = []
var player: Player
var rig: CameraRig
var blocks: Array[StaticBody3D] = []

var _block_material := StandardMaterial3D.new()


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_block_material.albedo_color = Color("#3b2a20")
	LevelBuilder.environment(self)
	LevelBuilder.lights(self, TestLevelLayout.LANTERN)
	for style in LevelBuilder.default_styles():
		layers.append(LevelBuilder.plate_layer(self, style, WorldSpec.LEVEL_SIZE))
	_build_foreground()
	for rect in TestLevelLayout.platforms():
		blocks.append(LevelBuilder.block(self, rect, _block_material))
	for rect in TestLevelLayout.walls():
		blocks.append(LevelBuilder.block(self, rect, null))
	player = Player.create()
	player.autorun = args.has("--autorun")
	player.position = Vector3(_spawn_x(args), TestLevelLayout.SPAWN.y, 0.0)
	add_child(player)
	rig = CameraRig.new()
	rig.target = player
	rig.level_size = WorldSpec.LEVEL_SIZE
	add_child(rig)
	rig.snap_to_target()


func _spawn_x(args: PackedStringArray) -> float:
	for arg in args:
		if arg.begins_with("--spawn-x="):
			return clampf(arg.get_slice("=", 1).to_float(), 2.0, WorldSpec.LEVEL_SIZE.x - 2.0)
	return TestLevelLayout.SPAWN.x


func _build_foreground() -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.08, 0.07, 0.09)
	var quad := QuadMesh.new()
	quad.size = TestLevelLayout.FOREGROUND_PROP_SIZE
	for x: float in TestLevelLayout.FOREGROUND_PROPS_X:
		var prop := MeshInstance3D.new()
		prop.mesh = quad
		prop.material_override = mat
		prop.position = Vector3(x, TestLevelLayout.FOREGROUND_PROP_SIZE.y * 0.5 - 3.0, -TestLevelLayout.FOREGROUND_DEPTH)
		add_child(prop)
