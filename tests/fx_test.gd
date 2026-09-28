extends TestCase
## Rain appears only when asked for; lightning flashes and restores; flicker stays in range.


func test_rain_only_when_enabled() -> void:
	var sun := DirectionalLight3D.new()
	add_node(sun)
	var dry := Weather.new()
	dry.setup(false, false, sun)
	add_node(dry)
	assert_true(dry.rain_near == null and dry.rain_far == null, "no rain")
	var wet := Weather.new()
	wet.setup(true, false, sun)
	add_node(wet)
	assert_true(wet.rain_near != null and wet.rain_far != null, "two rain layers")
	assert_true(wet.rain_near.position.z > 0.0 and wet.rain_far.position.z < 0.0, "in front of and behind the gameplay plane")


func test_lightning_flash_restores_sun() -> void:
	var sun := DirectionalLight3D.new()
	sun.light_energy = 0.4
	add_node(sun)
	var w := Weather.new()
	w.setup(false, true, sun)
	add_node(w)
	w.flash()
	assert_near(sun.light_energy, Weather.FLASH_ENERGY, 1e-6, "flash")
	await tree.create_timer(Weather.FLASH_TIME + 0.1, true, false, true).timeout
	assert_near(sun.light_energy, 0.4, 1e-3, "restored")


func test_flicker_level_bounded_and_varies() -> void:
	var lo := 1.0
	var hi := 0.0
	for i in 600:
		var v := Flicker.level(i * 0.01, 0.4)
		lo = minf(lo, v)
		hi = maxf(hi, v)
		assert_true(v >= 0.6 - 1e-6 and v <= 1.0 + 1e-6, "in range at %d" % i)
	assert_true(hi - lo > 0.1, "actually flickers (range %.2f)" % (hi - lo))
