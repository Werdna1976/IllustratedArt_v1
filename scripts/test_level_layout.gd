class_name TestLevelLayout
extends RefCounted
## Data for the M1 test level (metres, Y up, rect position = bottom-left). Platform tops step
## up at most 2.5 m, inside the ~3 m jump apex.

const SPAWN := Vector2(4.0, 2.5)
const LANTERN := Vector2(30.0, 5.5)
const FOREGROUND_DEPTH := -8.0
const FOREGROUND_PROP_SIZE := Vector2(1.2, 9.0)
const FOREGROUND_PROPS_X := [15.0, 37.0, 59.0, 81.0, 103.0, 125.0]


static func platforms() -> Array[Rect2]:
	return [
		Rect2(0.0, 0.0, WorldSpec.LEVEL_SIZE.x, 1.0), # floor
		Rect2(12.0, 3.0, 6.0, 0.5),
		Rect2(22.0, 5.5, 5.0, 0.5),
		Rect2(30.0, 3.5, 8.0, 0.5),
		Rect2(42.0, 6.0, 4.0, 0.5),
		Rect2(48.0, 8.5, 6.0, 0.5),
		Rect2(58.0, 4.0, 10.0, 0.5),
		Rect2(72.0, 3.0, 4.0, 0.5),
		Rect2(78.0, 5.5, 4.0, 0.5),
		Rect2(84.0, 8.0, 4.0, 0.5),
		Rect2(90.0, 10.5, 8.0, 0.5),
		Rect2(104.0, 6.0, 6.0, 0.5),
		Rect2(115.0, 3.5, 8.0, 0.5),
	]


static func walls() -> Array[Rect2]:
	return LevelBuilder.walls(WorldSpec.LEVEL_SIZE)
