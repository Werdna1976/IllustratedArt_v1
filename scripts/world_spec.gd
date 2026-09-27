class_name WorldSpec
extends RefCounted
## Single source of truth for world scale, camera and plate-size math (spec §2–§4).
## Coordinates: metres, X right, Y up, level origin at (0, 0). "Depth" is distance behind
## the gameplay plane; a layer at depth z sits at world Z = -z.

const PX_PER_M := 100.0 ## Texels per metre at the gameplay plane (1080p).
const CAMERA_DISTANCE := 20.0 ## Camera to gameplay plane, metres.
const SCREEN_H := 10.8 ## Metres visible vertically at the gameplay plane.
const LEVEL_SIZE := Vector2(134.4, 16.2)
const MAX_ASPECT := 21.0 / 9.0 ## Widest aspect that shows extra width; wider crops height.
const PLATE_MARGIN := 1.10 ## Slack for shake, dolly and look-ahead.
const PLATE_ROUND := 64
const STRIP_MAX_PX := 2048
const ACTOR_Z := 0.5 ## Actor/platform visuals sit this far in front of the gameplay plate.


static func camera_distance(depth: float) -> float:
	return CAMERA_DISTANCE + depth


## How fast a layer scrolls relative to the gameplay plane.
static func scroll_factor(depth: float) -> float:
	return CAMERA_DISTANCE / camera_distance(depth)


## Texels per metre needed at this depth for 1 texel per screen pixel at 1080p.
static func density(depth: float) -> float:
	return PX_PER_M * scroll_factor(depth)


static func vfov_deg() -> float:
	return rad_to_deg(2.0 * atan(SCREEN_H * 0.5 / CAMERA_DISTANCE))


## Metres visible at the gameplay plane for a viewport aspect.
static func screen_size(aspect: float) -> Vector2:
	if aspect > MAX_ASPECT:
		var w := SCREEN_H * MAX_ASPECT
		return Vector2(w, w / aspect)
	return Vector2(SCREEN_H * aspect, SCREEN_H)


static func visible_size(depth: float, aspect: float) -> Vector2:
	return screen_size(aspect) * camera_distance(depth) / CAMERA_DISTANCE


static func visible_rect(depth: float, camera_center: Vector2, aspect: float) -> Rect2:
	var size := visible_size(depth, aspect)
	return Rect2(camera_center - size * 0.5, size)


## World area (metres) a layer at this depth must cover while the camera roams the level.
static func plate_span(depth: float, level_size: Vector2 = LEVEL_SIZE) -> Vector2:
	var k := camera_distance(depth) / CAMERA_DISTANCE - 1.0
	return level_size + screen_size(MAX_ASPECT) * k


static func plate_size_px(depth: float, level_size: Vector2 = LEVEL_SIZE) -> Vector2i:
	var px := plate_span(depth, level_size) * density(depth) * PLATE_MARGIN
	return Vector2i(_round_up(px.x), _round_up(px.y))


## The plate's world rect: plate_size_px at this depth's density, centred on the level.
static func plate_rect(depth: float, level_size: Vector2 = LEVEL_SIZE) -> Rect2:
	var size := Vector2(plate_size_px(depth, level_size)) / density(depth)
	return Rect2(level_size * 0.5 - size * 0.5, size)


static func clamp_camera_center(center: Vector2, aspect: float, level_size: Vector2 = LEVEL_SIZE) -> Vector2:
	var half := screen_size(aspect) * 0.5
	return Vector2(clampf(center.x, half.x, level_size.x - half.x),
			clampf(center.y, half.y, level_size.y - half.y))


## Camera3D keep_aspect + fov (degrees) for a viewport aspect.
static func projection_for_aspect(aspect: float) -> Dictionary:
	if aspect > MAX_ASPECT:
		var half_w := SCREEN_H * MAX_ASPECT * 0.5
		return {"keep_aspect": Camera3D.KEEP_WIDTH, "fov": rad_to_deg(2.0 * atan(half_w / CAMERA_DISTANCE))}
	return {"keep_aspect": Camera3D.KEEP_HEIGHT, "fov": vfov_deg()}


# Round up to PLATE_ROUND; the tolerance stops float noise (14784.000000002) adding a step.
static func _round_up(v: float) -> int:
	return int(ceil(v / PLATE_ROUND - 1e-6)) * PLATE_ROUND
