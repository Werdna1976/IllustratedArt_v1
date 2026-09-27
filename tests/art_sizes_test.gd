extends TestCase
## ArtSizes reports WorldSpec plate sizes per layer for any section.


func test_default_section_matches_spec_table() -> void:
	var sizes := ArtSizes.for_section(WorldSpec.LEVEL_SIZE)
	assert_eq(sizes.gameplay, Vector2i(14784, 1792), "gameplay")
	assert_eq(sizes.near, Vector2i(10816, 1600), "near")
	assert_eq(sizes.mid, Vector2i(6784, 1408), "mid")
	assert_eq(sizes.far, Vector2i(4800, 1344), "far")
	assert_eq(sizes.sky, Vector2i(3392, 1280), "sky")


func test_vertical_section_gets_tall_plates() -> void:
	var sizes := ArtSizes.for_section(Vector2(28.8, 64.8))
	assert_true(sizes.gameplay.y > sizes.gameplay.x, "a climb section is taller than wide")
