extends Node3D
## M2 combat sandbox: a two-screen arena section with the player, a training dummy and a
## security officer. User arg `--demo` walks the player to the dummy and attacks every 0.6 s.

const SECTION := Vector2(38.4, 12.0)
const PLAYER_X := 6.0
const DUMMY_X := 14.0
const OFFICER_X := 26.0
const SPAWN_Y := 2.5
const DEMO_INTERVAL := 0.6

var player: Player
var dummy: TrainingDummy
var officer: Enemy
var rig: CameraRig

var _demo := false
var _demo_timer := 0.0
var _floor_material := StandardMaterial3D.new()


func _ready() -> void:
	_demo = OS.get_cmdline_user_args().has("--demo")
	_floor_material.albedo_color = Color("#2e2a33")
	LevelBuilder.environment(self)
	LevelBuilder.lights(self, Vector2(SECTION.x * 0.5, 6.0))
	if OS.get_cmdline_user_args().has("--rain"):
		var weather := Weather.new()
		weather.setup(true, true, find_children("*", "DirectionalLight3D", false, false)[0])
		add_child(weather)
	for style in LevelBuilder.default_styles():
		LevelBuilder.plate_layer(self, style, SECTION)
	LevelBuilder.block(self, Rect2(0.0, 0.0, SECTION.x, 1.0), _floor_material)
	for rect in LevelBuilder.walls(SECTION):
		LevelBuilder.block(self, rect, null)
	player = _spawn(Player.create(), PLAYER_X)
	dummy = _spawn(TrainingDummy.create_dummy(), DUMMY_X)
	officer = _spawn(Enemy.create_officer(), OFFICER_X)
	rig = CameraRig.new()
	rig.target = player
	rig.level_size = SECTION
	add_child(rig)
	rig.snap_to_target()


func _physics_process(delta: float) -> void:
	if not _demo:
		return
	player.autorun = player.global_position.x < DUMMY_X - 1.4
	_demo_timer += delta
	if not player.autorun and _demo_timer >= DEMO_INTERVAL:
		_demo_timer = 0.0
		player.combat.request(&"light")


func _spawn(fighter: Fighter, x: float) -> Fighter:
	fighter.position = Vector3(x, SPAWN_Y, 0.0)
	add_child(fighter)
	return fighter
