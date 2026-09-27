class_name PlaceholderPlate
extends RefCounted
## Script-generated stand-in plates (spec §9, M1): a gradient silhouette with a 1 m grid,
## so scroll speed and texel density are visible before real art exists.

const COLUMN_PX := 16 ## Silhouette height is constant across each column of this width.
const LINE_PX := 2
const MAJOR_EVERY_M := 5 ## Every 5th vertical line is drawn twice as thick.


## Columns [x0, x0 + width) of a plate plate_size px big. fill_from: fraction of the plate
## height (from the top) where the opaque silhouette begins; 0 = fully opaque.
static func generate_strip(plate_size: Vector2i, x0: int, width: int, px_per_m: float,
		top: Color, bottom: Color, fill_from: float) -> Image:
	var h := plate_size.y
	var img := Image.create_empty(width, h, false, Image.FORMAT_RGBA8)
	var column := _column(h, px_per_m, top, bottom)
	var x := 0
	while x < width:
		var w := mini(COLUMN_PX - (x0 + x) % COLUMN_PX, width - x)
		var y_top := silhouette_top(x0 + x, h, px_per_m, fill_from)
		img.blit_rect(column, Rect2i(0, y_top, w, h - y_top), Vector2i(x, y_top))
		x += w
	var grid := grid_color(top, bottom)
	var m := int(ceil(x0 / px_per_m))
	while true:
		var gx := int(round(m * px_per_m)) - x0
		if gx >= width:
			break
		var line_w := LINE_PX * (2 if m % MAJOR_EVERY_M == 0 else 1)
		var y_top := silhouette_top(x0 + gx, h, px_per_m, fill_from)
		img.fill_rect(Rect2i(gx, y_top, mini(line_w, width - gx), h - y_top), grid)
		m += 1
	return img


## Top row of the opaque silhouette at an absolute plate column.
static func silhouette_top(abs_x: int, h: int, px_per_m: float, fill_from: float) -> int:
	if fill_from <= 0.0:
		return 0
	var x := float(abs_x - abs_x % COLUMN_PX)
	var phase := x / (12.0 * px_per_m) * TAU # 12 m wavelength in world space
	var wave := sin(phase) * 0.06 + sin(phase * 2.7) * 0.03
	return clampi(int((fill_from + wave) * h), 0, h - 1)


static func grid_color(top: Color, bottom: Color) -> Color:
	return top.lerp(bottom, 0.5).darkened(0.45)


# One COLUMN_PX-wide gradient column with horizontal grid lines every metre from the bottom.
static func _column(h: int, px_per_m: float, top: Color, bottom: Color) -> Image:
	var col := Image.create_empty(COLUMN_PX, h, false, Image.FORMAT_RGBA8)
	for y in h:
		col.fill_rect(Rect2i(0, y, COLUMN_PX, 1), top.lerp(bottom, float(y) / maxf(h - 1, 1)))
	var grid := grid_color(top, bottom)
	var m := 1
	while true:
		var gy := h - int(round(m * px_per_m))
		if gy < 0:
			break
		col.fill_rect(Rect2i(0, gy, COLUMN_PX, LINE_PX), grid)
		m += 1
	return col
