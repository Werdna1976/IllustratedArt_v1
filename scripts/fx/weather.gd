class_name Weather
extends Node3D
## Rain and lightning (spec §5.2). Rain is two particle sheets, one in front of the gameplay plane
## and one behind it, following the camera; lightning briefly flashes the key light.

const FLASH_ENERGY := 6.0
const FLASH_TIME := 0.15
const RAIN_SPEED := 18.0 ## m/s
const FLASH_MIN := 6.0
const FLASH_MAX := 14.0

var rain_near: GPUParticles3D
var rain_far: GPUParticles3D
var lightning := false
var next_flash_in := 0.0

var _sun: DirectionalLight3D
var _sun_base := 1.0


func setup(rain: bool, p_lightning: bool, sun: DirectionalLight3D) -> void:
	_sun = sun
	_sun_base = sun.light_energy
	lightning = p_lightning
	next_flash_in = randf_range(FLASH_MIN, FLASH_MAX)
	if rain:
		rain_near = _rain_sheet(3.0, 1200)
		rain_far = _rain_sheet(-15.0, 2400)


func _process(delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam:
		position.x = cam.global_position.x
		position.y = cam.global_position.y
	if lightning:
		next_flash_in -= delta
		if next_flash_in <= 0.0:
			flash()
			next_flash_in = randf_range(FLASH_MIN, FLASH_MAX)


func flash() -> void:
	_sun.light_energy = FLASH_ENERGY
	var tween := create_tween()
	tween.set_ignore_time_scale(true)
	tween.tween_property(_sun, "light_energy", _sun_base, FLASH_TIME)


# A sheet of falling streaks at world offset z (positive = toward the camera), sized to cover the
# widest supported view at that distance.
func _rain_sheet(z: float, amount: int) -> GPUParticles3D:
	var view := WorldSpec.visible_size(-z, WorldSpec.MAX_ASPECT)
	var p := GPUParticles3D.new()
	p.position = Vector3(0.0, view.y * 0.6, z)
	p.amount = amount
	p.lifetime = view.y * 1.2 / RAIN_SPEED
	p.preprocess = p.lifetime
	p.visibility_aabb = AABB(Vector3(-view.x, -view.y * 1.5, -1.0), Vector3(view.x * 2.0, view.y * 2.0, 2.0))
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(view.x * 0.6, 0.1, 0.5)
	mat.direction = Vector3(0.12, -1.0, 0.0)
	mat.spread = 2.0
	mat.initial_velocity_min = RAIN_SPEED
	mat.initial_velocity_max = RAIN_SPEED * 1.15
	mat.gravity = Vector3.ZERO
	p.process_material = mat
	var streak := QuadMesh.new()
	streak.size = Vector2(0.015, 0.5) * (1.0 + maxf(-z, 0.0) / 20.0)
	var look := StandardMaterial3D.new()
	look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	look.albedo_color = Color(0.75, 0.85, 1.0, 0.35)
	streak.material = look
	p.draw_pass_1 = streak
	add_child(p)
	return p
