extends TestCase
## Title screen: stretched background, looping theme music, keyboard/gamepad-ready menu.

const SCENE := "res://scenes/ui/title_screen.tscn"


func test_is_the_main_scene() -> void:
	assert_eq(ProjectSettings.get_setting("application/run/main_scene"), SCENE, "game starts on the title screen")


func test_background_fills_the_screen_without_bars() -> void:
	var title = add_node(load(SCENE).instantiate()) # untyped: reads title_screen.gd vars
	await tree.process_frame
	var bg: TextureRect = title.background
	assert_true(bg.texture != null, "background image loaded")
	assert_eq(bg.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_COVERED, "stretched to cover, cropping edges")
	assert_eq(bg.expand_mode, TextureRect.EXPAND_IGNORE_SIZE, "may grow beyond the image's own size")
	assert_eq(bg.anchor_right, 1.0, "anchored full width")
	assert_eq(bg.anchor_bottom, 1.0, "anchored full height")


func test_theme_music_plays_and_loops() -> void:
	var title = add_node(load(SCENE).instantiate()) # untyped: reads title_screen.gd vars
	await tree.process_frame
	var music: AudioStreamPlayer = title.music
	assert_true(music.stream is AudioStreamOggVorbis, "theme loaded")
	assert_true((music.stream as AudioStreamOggVorbis).loop, "theme loops")
	assert_true(music.playing, "theme starts at startup")


func test_start_button_has_focus_for_keyboard_and_gamepad() -> void:
	var title = add_node(load(SCENE).instantiate()) # untyped: reads title_screen.gd vars
	await tree.process_frame
	assert_true(title.start_button.has_focus(), "Start is focused so Enter / A works immediately")
	assert_eq(title.start_scene, "res://scenes/level/combat_sandbox.tscn", "Start opens the combat sandbox")
