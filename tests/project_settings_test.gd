extends TestCase
## Project settings must match spec §6.


func test_display_and_rendering_settings_match_spec() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_width"), 1920, "viewport width")
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_height"), 1080, "viewport height")
	assert_eq(ProjectSettings.get_setting("display/window/stretch/mode"), "canvas_items", "stretch mode")
	assert_eq(ProjectSettings.get_setting("display/window/stretch/aspect"), "expand", "stretch aspect")
	assert_eq(ProjectSettings.get_setting("rendering/anti_aliasing/quality/msaa_3d"), Viewport.MSAA_4X, "msaa 4x")
	assert_eq(ProjectSettings.get_setting("rendering/anti_aliasing/quality/use_taa"), false, "taa off")
	assert_eq(ProjectSettings.get_setting("display/window/vsync/vsync_mode"), DisplayServer.VSYNC_ENABLED, "vsync on")


func test_physics_settings_match_spec() -> void:
	assert_eq(ProjectSettings.get_setting("physics/common/physics_ticks_per_second"), 120, "120 Hz tick")
	assert_eq(ProjectSettings.get_setting("physics/common/physics_interpolation"), true, "interpolation on")
	assert_eq(ProjectSettings.get_setting("physics/3d/physics_engine"), "Jolt Physics", "Jolt")
