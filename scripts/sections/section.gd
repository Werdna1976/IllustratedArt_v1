class_name Section
extends Node3D
## Builds one section at runtime from its SectionDef (spec §3.1): environment and lights, plate
## layers from imported strips (placeholders where art is missing), looping layers for vehicle
## runs, foreground props, collision, exit, free enemies and arenas.

signal exited

const STATIC_LAYERS := {"sky": 400.0, "far": 100.0, "mid": 40.0, "near": 10.0, "gameplay": 0.0}
const LOOP_LAYERS := {"mid_loop": 40.0, "near_loop": 10.0, "fg_loop": -8.0}
const LIT := ["near", "gameplay", "near_loop"]
const LOOP_PX := 4096
const FG_DEPTH := -8.0
const MIN_LOOP_SPEED := 0.3 ## Fraction of loop_speed at the start of the ramp.

var def: SectionDef
var layers: Array[PlateLayer] = []
var loops: Array[LoopingLayer] = []
var blocks: Array[StaticBody3D] = []
var props: Array[MeshInstance3D] = []
var arenas: Array = [] ## Array[ArenaZone]
var exit_zone: Area3D
var enemies: Array[Enemy] = []
var sun: DirectionalLight3D
var environment: Environment
var weather: Node3D ## Weather, when the section has rain or lightning.
var lamps: Array[OmniLight3D] = []
var flicker: Flicker
var _layer_by_name := {}

var _t := 0.0
var _exited := false


func setup(p_def: SectionDef) -> void:
	def = p_def
	environment = LevelBuilder.environment(self, def.env)
	sun = LevelBuilder.sun(self, Color(def.env.get("sun", "#ffe2c0")), def.env.get("sun_energy", 1.0))
	for spec in def.lights:
		var lamp := OmniLight3D.new()
		lamp.position = spec.pos
		lamp.light_color = spec.color
		lamp.omni_range = spec.range
		lamp.light_energy = spec.energy
		add_child(lamp)
		lamps.append(lamp)
	if def.is_vehicle():
		_add_static("gameplay")
		for layer: String in LOOP_LAYERS:
			_add_loop(layer)
	else:
		for layer: String in STATIC_LAYERS:
			_add_static(layer)
	_add_props()
	var greybox := StandardMaterial3D.new()
	greybox.albedo_color = Color(def.env.get("greybox", "#2e2a33"))
	var visual: Material = null if def.manifest.has("gameplay") else greybox
	for rect in def.collision:
		blocks.append(LevelBuilder.block(self, rect, visual))
	for rect in LevelBuilder.walls(def.size):
		blocks.append(LevelBuilder.block(self, rect, null))
	if def.has_exit:
		_add_exit()
	for arena_spec: Dictionary in def.arenas:
		var arena := ArenaZone.new()
		arena.setup(arena_spec.rect, arena_spec.enemies)
		arena.cleared.connect(_check_exit)
		add_child(arena)
		arenas.append(arena)
	_add_fx()
	for spec: Dictionary in def.enemies:
		var enemy := spawn_enemy(spec)
		add_child(enemy)
		enemies.append(enemy)


func _process(delta: float) -> void:
	if loops.is_empty():
		return
	_t += delta
	var ramp := 1.0 if def.loop_ramp_s <= 0.0 else clampf(_t / def.loop_ramp_s, 0.0, 1.0)
	for loop in loops:
		loop.speed = def.loop_speed * lerpf(MIN_LOOP_SPEED, 1.0, ramp)


static func spawn_enemy(spec: Dictionary) -> Enemy:
	var enemy: Enemy = TrainingDummy.create_dummy() if spec.get("type", "officer") == "dummy" else Enemy.create_officer()
	enemy.position = Vector3(spec.get("x", 0.0), spec.get("y", 2.5), 0.0)
	return enemy


func _add_static(layer: String) -> void:
	var depth: float = STATIC_LAYERS[layer]
	var maps := _strips(layer)
	var plate: PlateLayer
	if maps.is_empty():
		plate = LevelBuilder.plate_layer(self, _style(layer, depth), def.size)
	else:
		plate = PlateLayer.new()
		plate.name = "Plate_%s" % layer
		plate.build(depth, maps.albedo, layer in LIT, def.size, layer != "sky", maps.normal, maps.emit)
		add_child(plate)
	layers.append(plate)
	_layer_by_name[layer] = plate


func _add_loop(layer: String) -> void:
	var depth: float = LOOP_LAYERS[layer]
	var maps := _strips(layer)
	if maps.is_empty():
		var style := _style(layer, depth)
		var h := WorldSpec.plate_size_px(depth, def.size).y
		var img := PlaceholderPlate.generate_strip(Vector2i(LOOP_PX, h), 0, LOOP_PX, WorldSpec.density(depth),
				style.top, style.bottom, style.fill_from, LOOP_PX)
		img.generate_mipmaps()
		maps = {"albedo": [ImageTexture.create_from_image(img)] as Array[Texture2D], "normal": [] as Array[Texture2D], "emit": [] as Array[Texture2D]}
	var loop := LoopingLayer.new()
	loop.name = "Loop_%s" % layer
	loop.setup(depth, maps.albedo, layer in LIT, true, def.size, maps.normal, maps.emit)
	add_child(loop)
	loops.append(loop)
	_layer_by_name[layer] = loop


# Imported strips for a layer: {albedo, normal, emit} texture arrays, or {} when not imported.
func _strips(layer: String) -> Dictionary:
	if not def.manifest.has(layer):
		return {}
	var entry: Dictionary = def.manifest[layer]
	var out := {"albedo": [] as Array[Texture2D], "normal": [] as Array[Texture2D], "emit": [] as Array[Texture2D]}
	for i in entry.widths.size():
		for kind: String in ["albedo", "normal", "emit"]:
			if (kind == "normal" and not entry.has_n) or (kind == "emit" and not entry.has_emit):
				continue
			var suffix: String = {"albedo": "", "normal": "_n", "emit": "_emit"}[kind]
			var path := "%s_strips/%s%s_%02d.png" % [def.dir, layer, suffix, i]
			if not ResourceLoader.exists(path):
				push_warning("%s missing (run tools/import_art.sh); using a placeholder for %s" % [path, layer])
				return {}
			out[kind].append(load(path))
	return out


func _style(layer: String, depth: float) -> Dictionary:
	var style: Dictionary = {}
	for s: Dictionary in LevelBuilder.default_styles():
		if is_equal_approx(s.depth, clampf(depth, 0.0, 400.0)):
			style = s.duplicate()
	if layer == "fg_loop":
		style = {"top": Color("#0c0b10"), "bottom": Color("#050408"), "fill_from": 0.9, "lit": false, "fog": true}
	style.depth = depth
	var custom: Array = def.placeholder.get(layer, [])
	if custom.size() == 3:
		style.top = Color(custom[0])
		style.bottom = Color(custom[1])
		style.fill_from = float(custom[2])
	return style


func _add_fx() -> void:
	if def.rain or def.lightning:
		weather = Weather.new()
		weather.setup(def.rain, def.lightning, sun)
		add_child(weather)
	flicker = Flicker.new()
	for layer_name in def.flicker_layers:
		if _layer_by_name.has(layer_name):
			flicker.add_layer(_layer_by_name[layer_name], 0.5)
	for i in lamps.size():
		if def.lights[i].flicker > 0.0:
			flicker.add_light(lamps[i], def.lights[i].flicker)
	add_child(flicker)


func _add_props() -> void:
	var px_per_m := WorldSpec.density(FG_DEPTH)
	var available: Array = def.manifest.get("props", [])
	for spec: Dictionary in def.props:
		var path := "%s_strips/%s" % [def.dir, spec.image]
		if not spec.image in available or not ResourceLoader.exists(path):
			continue
		var tex: Texture2D = load(path)
		var size_m := Vector2(tex.get_size()) / px_per_m
		var quad := QuadMesh.new()
		quad.size = size_m
		var mi := MeshInstance3D.new()
		mi.mesh = quad
		mi.material_override = PlateLayer.make_material(tex, false, true)
		mi.position = Vector3(spec.x, spec.get("y", 0.0) + size_m.y * 0.5, -FG_DEPTH)
		add_child(mi)
		props.append(mi)


func _add_exit() -> void:
	exit_zone = Area3D.new()
	exit_zone.collision_layer = 0
	exit_zone.collision_mask = Fighter.LAYER_ACTORS
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(def.exit.size.x, def.exit.size.y, 2.0)
	shape.shape = box
	exit_zone.add_child(shape)
	exit_zone.position = Vector3(def.exit.get_center().x, def.exit.get_center().y, 0.0)
	exit_zone.body_entered.connect(_on_exit_body)
	add_child(exit_zone)


func _on_exit_body(body: Node3D) -> void:
	if body is Player and not _exited and not _arena_in_progress():
		_exited = true
		exited.emit()


# An arena that has started but not been cleared keeps the exit shut.
func _arena_in_progress() -> bool:
	for arena in arenas:
		if arena.active and not arena.is_cleared:
			return true
	return false


# The player may already be standing in the exit when the arena clears.
func _check_exit() -> void:
	if exit_zone:
		for body in exit_zone.get_overlapping_bodies():
			_on_exit_body(body)
