class_name SectionDef
extends RefCounted
## A section folder parsed into metres (spec §3.1): section.json gameplay data, pixel collision
## from gameplay_collision.json (compose_plate) and _strips/collision_traced.json (import_art),
## and the strip manifest written by tools/import_art.sh.

const TYPES := ["horizontal", "vertical", "arena", "vehicle"]

var dir := ""
var id := ""
var size := WorldSpec.LEVEL_SIZE
var type := "horizontal"
var env := {}
var placeholder := {}
var spawn := Vector2(4.0, 2.5)
var has_exit := false
var exit := Rect2()
var collision: Array[Rect2] = []
var lights: Array[Dictionary] = []
var props: Array = []
var enemies: Array = []
var arenas: Array[Dictionary] = []
var rain := false
var lightning := false
var flicker_layers := PackedStringArray()
var loop_speed := 0.0
var loop_ramp_s := 0.0
var manifest := {}


static func load_dir(p_dir: String) -> SectionDef:
	var def := SectionDef.new()
	def.dir = p_dir if p_dir.ends_with("/") else p_dir + "/"
	def.id = def.dir.trim_suffix("/").get_file()
	var data: Dictionary = _read_json(def.dir + "section.json", {})
	if data.has("size_m"):
		def.size = _vec2(data.size_m)
	def.type = data.get("type", "horizontal")
	def.env = data.get("env", {})
	def.placeholder = data.get("placeholder", {})
	if data.has("spawn"):
		def.spawn = _vec2(data.spawn)
	if data.has("exit"):
		def.has_exit = true
		def.exit = _rect(data.exit)
	# Collision from the art (compose_plate / traced mask) replaces the greybox boxes in section.json,
	# unless "keep_greybox_collision" asks to keep both.
	var plate := WorldSpec.plate_rect(0.0, def.size)
	var ppm := WorldSpec.density(0.0)
	for path in [def.dir + "gameplay_collision.json", def.dir + "_strips/collision_traced.json"]:
		for px: Array in _read_json(path, []):
			def.collision.append(px_to_world(px, plate, ppm))
	if def.collision.is_empty() or data.get("keep_greybox_collision", false):
		for r: Array in data.get("collision", []):
			def.collision.append(_rect(r))
	for light: Dictionary in data.get("lights", []):
		def.lights.append(_light(light, _vec3(light.pos)))
	for row: Dictionary in data.get("light_rows", []):
		var x: float = row.from
		while x <= row.to + 1e-6:
			def.lights.append(_light(row, Vector3(x, row.y, row.get("z", 1.5))))
			x += row.step
	def.props = data.get("props", [])
	def.enemies = data.get("enemies", [])
	for arena: Dictionary in data.get("arenas", []):
		def.arenas.append({"rect": _rect(arena.rect), "enemies": arena.get("enemies", [])})
	var weather: Dictionary = data.get("weather", {})
	def.rain = weather.get("rain", false)
	def.lightning = weather.get("lightning", false)
	def.flicker_layers = PackedStringArray(data.get("flicker_layers", []))
	def.loop_speed = data.get("loop_speed", 0.0)
	def.loop_ramp_s = data.get("loop_ramp_s", 0.0)
	def.manifest = _read_json(def.dir + "_strips/manifest.json", {})
	return def


func is_vehicle() -> bool:
	return type == "vehicle"


## [x, y, w, h] in plate px (y down from the image top) -> world rect in metres (y up).
static func px_to_world(px: Array, plate: Rect2, px_per_m: float) -> Rect2:
	var w: float = px[2] / px_per_m
	var h: float = px[3] / px_per_m
	return Rect2(plate.position.x + px[0] / px_per_m, plate.end.y - px[1] / px_per_m - h, w, h)


static func _light(spec: Dictionary, pos: Vector3) -> Dictionary:
	return {"pos": pos, "color": Color(spec.get("color", "#ffffff")), "range": float(spec.get("range", 6.0)),
			"energy": float(spec.get("energy", 2.0)), "flicker": float(spec.get("flicker", 0.0))}


static func _read_json(path: String, fallback: Variant) -> Variant:
	if not FileAccess.file_exists(path):
		return fallback
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return fallback if parsed == null else parsed


static func _vec2(a: Array) -> Vector2:
	return Vector2(a[0], a[1])


static func _vec3(a: Array) -> Vector3:
	return Vector3(a[0], a[1], a[2] if a.size() > 2 else 1.5)


static func _rect(a: Array) -> Rect2:
	return Rect2(a[0], a[1], a[2], a[3])
