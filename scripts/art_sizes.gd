class_name ArtSizes
extends RefCounted
## Plate sizes (px) per layer for a section, from WorldSpec — the numbers artists deliver.

const LAYER_DEPTHS := {"sky": 400.0, "far": 100.0, "mid": 40.0, "near": 10.0, "gameplay": 0.0}


static func for_section(level_size: Vector2) -> Dictionary:
	var sizes := {}
	for layer: String in LAYER_DEPTHS:
		sizes[layer] = WorldSpec.plate_size_px(LAYER_DEPTHS[layer], level_size)
	return sizes
